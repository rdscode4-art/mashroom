const Order = require("../models/Order");
const Cart = require("../models/Cart");
const User = require("../models/User");
const Address = require("../models/Address");
const Settings = require("../models/Settings");
const Coupon = require("../models/Coupon");
const { sendPushNotification } = require("../services/notificationService");

// PLACE NEW ORDER FROM CART
const placeOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const { paymentMethod, deliveryAddress: bodyAddress, couponCode, razorpayOrderId, razorpayPaymentId } = req.body;
    console.log("PLACE ORDER REQUEST BODY:", req.body);

    // 1. Cart
    const cart = await Cart.findOne({ userId }).populate("products.productId");
    if (!cart || cart.products.length === 0)
      return res.status(400).json({ success: false, message: "Your cart is empty" });

    // 2. Delivery address
    let deliveryAddress;
    if (bodyAddress?.fullAddress?.trim()) {
      deliveryAddress = {
        fullAddress: bodyAddress.fullAddress.trim(),
        city: bodyAddress.city || "", state: bodyAddress.state || "",
        pincode: bodyAddress.pincode || "", landmark: bodyAddress.landmark || "",
        latitude: bodyAddress.latitude || 0, longitude: bodyAddress.longitude || 0,
      };
    } else {
      const user = await User.findById(userId);
      if (!user?.address?.fullAddress)
        return res.status(400).json({ success: false, message: "Delivery address not found. Please add an address before placing an order." });
      deliveryAddress = {
        fullAddress: user.address.fullAddress, city: user.address.city || "",
        state: user.address.state || "", pincode: user.address.pincode || "",
        landmark: user.address.landmark || "",
        latitude: user.address.location?.latitude || 0,
        longitude: user.address.location?.longitude || 0,
      };
    }

    // 3. Persist address to Address collection
    await Address.findOneAndUpdate(
      { userId, fullAddress: deliveryAddress.fullAddress },
      {
        userId, ...deliveryAddress,
        ...(bodyAddress?.houseNo && { houseNo: bodyAddress.houseNo }),
        ...(bodyAddress?.floor && { floor: bodyAddress.floor }),
        ...(bodyAddress?.building && { building: bodyAddress.building }),
        ...(bodyAddress?.area && { area: bodyAddress.area }),
      },
      { upsert: true, returnDocument: 'after', setDefaultsOnInsert: true }
    );

    // 4. Read dynamic charges from Settings
    let settings = await Settings.findOne();
    if (!settings) settings = await Settings.create({});
    const deliveryCharge = settings.deliveryCharge ?? 30;
    const taxPercent = settings.taxPercent ?? 5;

    // 5. Products + totals
    const orderProducts = cart.products.map(item => ({
      productId: item.productId._id, quantity: item.quantity, price: item.price,
    }));
    const tax = parseFloat((cart.totalPrice * (taxPercent / 100)).toFixed(2));
    let totalAmount = parseFloat((cart.totalPrice + deliveryCharge + tax).toFixed(2));

    // 5.1 Validate and apply coupon
    let couponDiscount = 0;
    let validatedCouponCode = "";
    if (couponCode && couponCode.trim()) {
      const coupon = await Coupon.findOne({ code: couponCode.toUpperCase().trim() });
      if (!coupon) {
        return res.status(400).json({ success: false, message: "Invalid coupon code" });
      }
      if (coupon.expiryDate && new Date(coupon.expiryDate) < new Date()) {
        return res.status(400).json({ success: false, message: "This coupon has expired" });
      }
      if (coupon.minimumOrder && cart.totalPrice < coupon.minimumOrder) {
        return res.status(400).json({
          success: false,
          message: `Minimum order of ₹${coupon.minimumOrder} required for this coupon`,
        });
      }
      validatedCouponCode = coupon.code;
      if (coupon.discountType === "percentage") {
        couponDiscount = parseFloat(((cart.totalPrice * coupon.discountValue) / 100).toFixed(2));
      } else {
        couponDiscount = Math.min(coupon.discountValue, cart.totalPrice);
      }
      totalAmount = parseFloat(Math.max(0, totalAmount - couponDiscount).toFixed(2));
    }

    // 6. Create order — generate a 4-digit delivery OTP
    const pickupOTP = String(Math.floor(1000 + Math.random() * 9000));
    const orderOTP = String(Math.floor(1000 + Math.random() * 9000));
    const order = await Order.create({
      customerId: userId, vendorId: cart.vendorId,
      products: orderProducts, totalAmount, deliveryCharge, tax,
      paymentMethod: paymentMethod || "cod",
      paymentStatus: (paymentMethod === "online" && razorpayPaymentId) ? "paid" : "pending",
      orderStatus: "pending", deliveryAddress, pickupOTP, orderOTP,
      couponCode: validatedCouponCode, couponDiscount,
      razorpayOrderId: razorpayOrderId || "",
      razorpayPaymentId: razorpayPaymentId || "",
    });

    // 7. Clear cart
    await Cart.deleteOne({ _id: cart._id });

    // 8. Notify Vendor
    try {
      const vendorUser = await User.findById(cart.vendorId);
      if (vendorUser && vendorUser.fcmToken) {
        await sendPushNotification(
          vendorUser.fcmToken,
          "New Order Received! 🛍️",
          "You have received a new order. Please pack it soon.",
          { type: "new_order_vendor", orderId: order._id.toString() }
        );
      }
    } catch (pushErr) {
      console.log("Failed to send push notification to vendor:", pushErr.message);
    }

    res.status(201).json({ success: true, message: "Order placed successfully", order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { placeOrder };
