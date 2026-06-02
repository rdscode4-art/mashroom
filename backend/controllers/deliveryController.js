const DeliveryPartner = require("../models/DeliveryPartner");
const Order = require("../models/Order");
const Vendor = require("../models/Vendor");
const User = require("../models/User");
const Settings = require("../models/Settings");
const DriverTransaction = require("../models/DriverTransaction");
const WithdrawalRequest = require("../models/WithdrawalRequest");
const { sendPushNotification } = require("../services/notificationService");

// REGISTER / ONBOARD as delivery partner (basic info only — KYC submitted separately)
const registerPartner = async (req, res) => {
  try {
    const existing = await DeliveryPartner.findOne({ userId: req.user.id });
    if (existing) return res.status(400).json({ success: false, message: "You already have a delivery partner profile" });

    const { name, phone, email, vehicleType, vehicleNumber } = req.body;
    if (!name || !phone) return res.status(400).json({ success: false, message: "Name and phone are required" });

    const profileImage = req.file ? req.file.path.replace(/\\/g, "/") : "";
    const partner = await DeliveryPartner.create({
      userId: req.user.id, name, phone,
      email: email || "",
      vehicleType: vehicleType || "bike",
      vehicleNumber: vehicleNumber || "", profileImage,
      isOnline: false, isAvailable: true,
      kycStatus: "pending", isApproved: false,
    });

    await User.findByIdAndUpdate(req.user.id, { role: "delivery" });
    res.status(201).json({ success: true, message: "Profile created. Please complete KYC to start delivering.", partner });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// SUBMIT KYC DOCUMENTS
const submitKyc = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found. Please register first." });

    const { aadharNumber, dlNumber } = req.body;
    if (!aadharNumber || aadharNumber.replace(/\s/g, "").length !== 12) {
      return res.status(400).json({ success: false, message: "Valid 12-digit Aadhar number is required" });
    }
    if (!dlNumber) {
      return res.status(400).json({ success: false, message: "Driving licence number is required" });
    }

    const files = req.files || {};
    const aadharFront = files.aadharFront?.[0]?.path.replace(/\\/g, "/") || partner.kyc?.aadharFront || "";
    const aadharBack = files.aadharBack?.[0]?.path.replace(/\\/g, "/") || partner.kyc?.aadharBack || "";
    const dlImage = files.dlImage?.[0]?.path.replace(/\\/g, "/") || partner.kyc?.dlImage || "";

    if (!aadharFront || !aadharBack) {
      return res.status(400).json({ success: false, message: "Both Aadhar front and back images are required" });
    }
    if (!dlImage) {
      return res.status(400).json({ success: false, message: "Driving licence image is required" });
    }

    partner.kyc = { aadharNumber: aadharNumber.replace(/\s/g, ""), aadharFront, aadharBack, dlNumber, dlImage };
    partner.kycStatus = "submitted";
    partner.kycRejectionReason = "";
    await partner.save();

    res.json({ success: true, message: "KYC submitted successfully! Our team will verify within 24 hours.", partner });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET OWN PROFILE
const getProfile = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Delivery partner profile not found" });
    res.json({ success: true, partner });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// TOGGLE ONLINE / OFFLINE
const toggleOnline = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });
    if (!partner.isApproved) {
      return res.status(403).json({ success: false, message: "Your KYC is not approved yet. Please wait for admin verification." });
    }
    partner.isOnline = !partner.isOnline;
    if (!partner.isOnline) partner.isAvailable = true;
    await partner.save();
    res.json({ success: true, message: partner.isOnline ? "You are now Online 🟢" : "You are now Offline 🔴", isOnline: partner.isOnline });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE CURRENT LOCATION
const updateLocation = async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    const partner = await DeliveryPartner.findOneAndUpdate(
      { userId: req.user.id },
      { currentLocation: { latitude, longitude } },
      { new: true }
    );
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });
    res.json({ success: true, message: "Location updated" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const deg2rad = (d) => d * (Math.PI / 180);

const distanceKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const findAvailablePickupOrder = async (partner) => {
  if (!partner.isApproved || !partner.isOnline || !partner.isAvailable) return null;

  let settings = await Settings.findOne();
  if (!settings) settings = await Settings.create({});
  const radius = settings.deliveryPartnerRadius ?? 2;

  const orders = await Order.find({
    orderStatus: { $in: ["ready_for_pickup", "packed", "accepted"] },
    deliveryPartnerId: null,
  })
    .populate("customerId", "name phone")
    .populate("vendorId", "shopName phone address")
    .populate("products.productId", "productName images unit")
    .sort({ createdAt: 1 })
    .limit(20);

  const pLat = partner.currentLocation?.latitude;
  const pLng = partner.currentLocation?.longitude;

  for (const order of orders) {
    const vLat = order.vendorId?.address?.location?.latitude;
    const vLng = order.vendorId?.address?.location?.longitude;
    const hasLocations =
      typeof pLat === "number" && typeof pLng === "number" && pLat !== 0 && pLng !== 0 &&
      typeof vLat === "number" && typeof vLng === "number" && vLat !== 0 && vLng !== 0;

    // Use radius when locations are available. During local testing, do not hide
    // orders just because one side has not saved GPS coordinates yet.
    if (hasLocations && distanceKm(pLat, pLng, vLat, vLng) > radius) continue;

    if (["accepted", "packed"].includes(order.orderStatus)) {
      if (!order.pickupOTP) {
        order.pickupOTP = String(Math.floor(1000 + Math.random() * 9000));
        await order.save();
      }
    }
    return order;
  }

  return null;
};

// GET ASSIGNED ORDER (the one currently assigned to this partner)
const getAssignedOrder = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    if (!partner.activeOrderId) {
      const availableOrder = await findAvailablePickupOrder(partner);
      return res.json({ success: true, order: availableOrder });
    }

    let order = await Order.findById(partner.activeOrderId)
      .populate("customerId", "name phone")
      .populate("vendorId", "shopName phone address")
      .populate("products.productId", "productName images unit");

    if (!order || ["delivered", "cancelled"].includes(order.orderStatus)) {
      partner.activeOrderId = null;
      partner.isAvailable = true;
      await partner.save();
      order = await findAvailablePickupOrder(partner);
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET ORDER HISTORY for this partner
const getOrderHistory = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const orders = await Order.find({ deliveryPartnerId: partner._id })
      .populate("customerId", "name phone")
      .populate("vendorId", "shopName")
      .sort({ createdAt: -1 });

    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ACCEPT PICKUP — first delivery partner to tap "Accept" gets the order (atomic)
const acceptPickup = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });
    if (!partner.isApproved) return res.status(403).json({ success: false, message: "Your KYC is not approved yet" });
    if (!partner.isOnline) return res.status(400).json({ success: false, message: "You must be online to accept orders" });
    if (!partner.isAvailable) return res.status(400).json({ success: false, message: "You already have an active delivery" });

    // Atomic findOneAndUpdate — only succeeds if order is still unassigned and ready_for_pickup
    const order = await Order.findOneAndUpdate(
      {
        _id: req.params.orderId,
        orderStatus: { $in: ["ready_for_pickup", "packed", "accepted"] },
        deliveryPartnerId: null, // not yet claimed by anyone
      },
      {
        deliveryPartnerId: partner._id,
      },
      { new: true }
    ).populate("customerId", "name phone")
     .populate("vendorId", "shopName phone address")
     .populate("products.productId", "productName images unit");

    if (!order) {
      return res.status(409).json({
        success: false,
        message: "This order was already accepted by another rider. Check for new orders.",
      });
    }

    // Lock the partner
    partner.isAvailable = false;
    partner.activeOrderId = order._id;
    await partner.save();

    res.json({ success: true, message: "Order accepted! Head to the vendor for pickup. 🛵", order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// CONFIRM PICKED UP FROM VENDOR — partner has collected the order, now heading to customer
const confirmPickup = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const { otp } = req.body;
    const order = await Order.findOne({ _id: req.params.orderId, deliveryPartnerId: partner._id });
    if (!order) return res.status(404).json({ success: false, message: "Order not found or not assigned to you" });
    if (!["ready_for_pickup", "packed", "accepted"].includes(order.orderStatus)) {
      return res.status(400).json({ success: false, message: "Order is not in a valid state for pickup" });
    }

    if (!order.pickupOTP) {
      order.pickupOTP = String(Math.floor(1000 + Math.random() * 9000));
      await order.save();
    }

    if (order.pickupOTP !== String(otp)) {
      return res.status(400).json({ success: false, message: "Invalid pickup OTP. Please ask the vendor for the correct OTP." });
    }

    order.orderStatus = "out_for_delivery";
    await order.save();

    // Notify Customer
    const orderWithCustomer = await Order.findById(order._id).populate("customerId", "fcmToken");
    if (orderWithCustomer && orderWithCustomer.customerId?.fcmToken) {
      await sendPushNotification(
        orderWithCustomer.customerId.fcmToken,
        "Order Out for Delivery! 🚴",
        "Your order has been picked up and is on its way to you.",
        { type: "order_update", orderId: order._id.toString() }
      );
    }

    res.json({ success: true, message: "Picked up! Head to the customer. 🚴", order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const markDelivered = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const { otp } = req.body;
    const order = await Order.findOne({ _id: req.params.orderId, deliveryPartnerId: partner._id }).populate("vendorId");
    if (!order) return res.status(404).json({ success: false, message: "Order not found or not assigned to you" });

    if (order.orderStatus !== "out_for_delivery") {
      return res.status(400).json({ success: false, message: "Order is not out for delivery" });
    }

    // Verify OTP
    if (order.orderOTP !== String(otp)) {
      return res.status(400).json({ success: false, message: "Invalid delivery OTP. Please ask the customer for the correct OTP." });
    }

    // Calculate delivery distance and fare
    let distance = 0;
    const vLat = order.vendorId?.address?.location?.latitude;
    const vLng = order.vendorId?.address?.location?.longitude;
    const cLat = order.deliveryAddress?.latitude;
    const cLng = order.deliveryAddress?.longitude;
    if (
      typeof vLat === "number" && typeof vLng === "number" &&
      typeof cLat === "number" && typeof cLng === "number" &&
      vLat !== 0 && vLng !== 0 && cLat !== 0 && cLng !== 0
    ) {
      distance = distanceKm(vLat, vLng, cLat, cLng);
    }

    let settings = await Settings.findOne();
    const baseFare = settings?.deliveryBaseFare ?? 25;
    const perKmRate = settings?.deliveryPerKmRate ?? 5;
    const calculatedEarning = Number((baseFare + distance * perKmRate).toFixed(2));

    order.orderStatus = "delivered";
    if (order.paymentMethod === "cod") order.paymentStatus = "paid";
    order.driverEarning = calculatedEarning;
    order.deliveryDistance = Number(distance.toFixed(2));
    await order.save();

    // Update vendor earnings
    await Vendor.findByIdAndUpdate(order.vendorId._id || order.vendorId, {
      $inc: { totalEarnings: order.totalAmount, totalOrders: 1 }
    });

    // Update partner stats and free them up
    partner.totalDeliveries += 1;
    partner.earnings = Number((partner.earnings + calculatedEarning).toFixed(2));
    partner.isAvailable = true;
    partner.activeOrderId = null;
    await partner.save();

    // Log the transaction
    await DriverTransaction.create({
      deliveryPartnerId: partner._id,
      amount: calculatedEarning,
      type: "earning",
      description: `Earnings for Order #${order._id.toString().substring(18)}`,
      orderId: order._id
    });

    // Notify Customer
    const orderWithCustomer = await Order.findById(order._id).populate("customerId", "fcmToken");
    if (orderWithCustomer && orderWithCustomer.customerId?.fcmToken) {
      await sendPushNotification(
        orderWithCustomer.customerId.fcmToken,
        "Order Delivered! ✅",
        "Your order has been successfully delivered. Enjoy!",
        { type: "order_update", orderId: order._id.toString() }
      );
    }

    res.json({ success: true, message: "Order delivered successfully! ✅", order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DASHBOARD STATS for delivery partner
const getDashboard = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
    const todayDeliveries = await Order.countDocuments({
      deliveryPartnerId: partner._id,
      orderStatus: "delivered",
      updatedAt: { $gte: todayStart },
    });

    res.json({
      success: true,
      partner,
      stats: {
        totalDeliveries: partner.totalDeliveries,
        totalEarnings: partner.earnings,
        todayDeliveries,
        isOnline: partner.isOnline,
        isAvailable: partner.isAvailable,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET WALLET HISTORY
const getWalletHistory = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const transactions = await DriverTransaction.find({ deliveryPartnerId: partner._id })
      .populate("withdrawalId")
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      balance: partner.earnings,
      transactions,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// REQUEST WITHDRAWAL
const requestWithdrawal = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const { amount, method, upiId, bankDetails } = req.body;
    const numAmount = Number(amount);

    if (isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({ success: false, message: "Please enter a valid positive withdrawal amount" });
    }

    if (numAmount < 100) {
      return res.status(400).json({ success: false, message: "Minimum withdrawal amount is ₹100" });
    }

    if (partner.earnings < numAmount) {
      return res.status(400).json({ success: false, message: "Insufficient balance for withdrawal" });
    }

    if (!["upi", "bank"].includes(method)) {
      return res.status(400).json({ success: false, message: "Invalid payout method. Choose UPI or Bank Transfer" });
    }

    if (method === "upi" && !upiId) {
      return res.status(400).json({ success: false, message: "UPI ID is required for UPI payout" });
    }

    if (method === "bank") {
      if (!bankDetails || !bankDetails.holderName || !bankDetails.accountNumber || !bankDetails.bankName || !bankDetails.ifscCode) {
        return res.status(400).json({ success: false, message: "All bank account details are required for Bank Transfer payout" });
      }
    }

    // Deduct amount immediately
    partner.earnings = Number((partner.earnings - numAmount).toFixed(2));
    await partner.save();

    // Create withdrawal request
    const withdrawal = await WithdrawalRequest.create({
      deliveryPartnerId: partner._id,
      amount: numAmount,
      method,
      upiId: method === "upi" ? upiId : "",
      bankDetails: method === "bank" ? bankDetails : {},
      status: "pending",
    });

    // Create negative transaction entry
    await DriverTransaction.create({
      deliveryPartnerId: partner._id,
      amount: -numAmount,
      type: "withdrawal",
      description: `Withdrawal request submitted (${method.toUpperCase()})`,
      withdrawalId: withdrawal._id,
    });

    res.status(201).json({
      success: true,
      message: "Withdrawal request submitted successfully! It will be processed soon.",
      withdrawal,
      balance: partner.earnings,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE PROFILE
const updateProfile = async (req, res) => {
  try {
    const partner = await DeliveryPartner.findOne({ userId: req.user.id });
    if (!partner) return res.status(404).json({ success: false, message: "Profile not found" });

    const { name, email, vehicleType, vehicleNumber } = req.body;
    const User = require("../models/User");

    if (name !== undefined && name.trim() !== "") {
      partner.name = name.trim();
      await User.findByIdAndUpdate(req.user.id, { name: name.trim() });
    }

    if (email !== undefined) {
      partner.email = email.trim();
      await User.findByIdAndUpdate(req.user.id, { email: email.trim() || null });
    }

    if (vehicleType !== undefined && ["bike", "scooter", "cycle", "other"].includes(vehicleType)) {
      partner.vehicleType = vehicleType;
    }

    if (vehicleNumber !== undefined) {
      partner.vehicleNumber = vehicleNumber.trim();
    }

    if (req.file) {
      partner.profileImage = req.file.path.replace(/\\/g, "/");
    }

    await partner.save();

    res.status(200).json({ success: true, message: "Profile updated successfully", partner });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  registerPartner, submitKyc, getProfile, toggleOnline, updateLocation,
  getAssignedOrder, getOrderHistory, acceptPickup, confirmPickup, markDelivered, getDashboard,
  getWalletHistory, requestWithdrawal, updateProfile,
};
