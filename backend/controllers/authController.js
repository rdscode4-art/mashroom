const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Order = require("../models/Order");
const Notification = require("../models/Notification");
const Address = require("../models/Address");

// UPLOAD PROFILE PHOTO
const uploadProfilePhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "No image file provided" });
    }
    const imagePath = req.file.path.replace(/\\/g, "/");
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { profileImage: imagePath },
      { new: true }
    );
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    res.status(200).json({ success: true, message: "Profile photo updated", profileImage: imagePath, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const generateOTP = () => "1234";

// SEND OTP
const sendOTP = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: "Phone number is required" });
    let user = await User.findOne({ phone });
    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 5 * 60 * 1000);
    if (!user) {
      user = await User.create({ phone, otp, otpExpiry });
    } else {
      user.otp = otp;
      user.otpExpiry = otpExpiry;
      await user.save();
    }
    console.log("OTP:", otp);
    res.status(200).json({ success: true, message: "OTP sent successfully", otp });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// VERIFY OTP
const verifyOTP = async (req, res) => {
  try {
    const { phone, otp } = req.body;
    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    if (user.otp !== otp) return res.status(400).json({ success: false, message: "Invalid OTP" });
    if (user.otpExpiry < new Date()) return res.status(400).json({ success: false, message: "OTP expired" });
    user.isVerified = true;
    user.otp = null;
    user.otpExpiry = null;
    await user.save();
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "30d" });
    res.status(200).json({ success: true, message: "Login successful", token, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// REGISTER / COMPLETE PROFILE
const registerUser = async (req, res) => {
  try {
    const { name, email, phone, role, fullAddress, city, state, pincode, latitude, longitude } = req.body;
    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    user.name = name || user.name;
    user.email = email || user.email;
    if (role) user.role = role;
    user.address = { fullAddress, city, state, pincode, location: { latitude, longitude } };
    await user.save();
    res.status(200).json({ success: true, message: "User registered successfully", user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET PROFILE
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    res.status(200).json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE PROFILE (name, email)
const updateProfile = async (req, res) => {
  try {
    const { name, email } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    if (name !== undefined && name.trim() !== "") user.name = name.trim();
    if (email !== undefined) user.email = email.trim() || null;
    await user.save();
    res.status(200).json({ success: true, message: "Profile updated successfully", user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE LOCATION (GPS-based, no structured fields)
const updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, fullAddress, city, state, pincode } = req.body;
    const updateFields = {};
    if (fullAddress !== undefined) updateFields["address.fullAddress"] = fullAddress;
    if (city !== undefined) updateFields["address.city"] = city;
    if (state !== undefined) updateFields["address.state"] = state;
    if (pincode !== undefined) updateFields["address.pincode"] = pincode;
    if (latitude !== undefined) updateFields["address.location.latitude"] = latitude;
    if (longitude !== undefined) updateFields["address.location.longitude"] = longitude;
    const user = await User.findByIdAndUpdate(req.user.id, { $set: updateFields }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    res.status(200).json({ success: true, message: "Location updated successfully", address: user.address });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// LEGACY: save address directly onto user profile (used by old flow)
const saveAddress = async (req, res) => {
  try {
    const { houseNo, floor, building, area, landmark, city, state, pincode, latitude, longitude } = req.body;
    if (!houseNo || houseNo.trim() === "") {
      return res.status(400).json({ success: false, message: "House / Flat number is required" });
    }
    if (!city || city.trim() === "") {
      return res.status(400).json({ success: false, message: "City is required" });
    }
    if (!pincode || pincode.trim() === "") {
      return res.status(400).json({ success: false, message: "Pincode is required" });
    }
    const parts = [houseNo.trim()];
    if (floor && floor.trim()) parts.push(`Floor ${floor.trim()}`);
    if (building && building.trim()) parts.push(building.trim());
    if (area && area.trim()) parts.push(area.trim());
    if (landmark && landmark.trim()) parts.push(`Near ${landmark.trim()}`);
    parts.push(city.trim());
    if (state && state.trim()) parts.push(state.trim());
    parts.push(pincode.trim());
    const fullAddress = parts.join(", ");
    const updateFields = {
      "address.houseNo": houseNo.trim(),
      "address.floor": floor || "",
      "address.building": building || "",
      "address.area": area || "",
      "address.landmark": landmark || "",
      "address.fullAddress": fullAddress,
      "address.city": city.trim(),
      "address.state": state || "",
      "address.pincode": pincode.trim(),
    };
    if (latitude !== undefined) updateFields["address.location.latitude"] = latitude;
    if (longitude !== undefined) updateFields["address.location.longitude"] = longitude;
    const user = await User.findByIdAndUpdate(req.user.id, { $set: updateFields }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });
    res.status(200).json({ success: true, message: "Address saved successfully", address: user.address });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET ALL SAVED ADDRESSES for the user (Address collection)
const getSavedAddresses = async (req, res) => {
  try {
    const addresses = await Address.find({ userId: req.user.id }).sort({ updatedAt: -1 });
    res.status(200).json({ success: true, addresses });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADD / UPDATE A SAVED ADDRESS in the Address collection
const addSavedAddress = async (req, res) => {
  try {
    const { houseNo, floor, building, area, landmark, city, state, pincode,
            addressType, latitude, longitude, addressId } = req.body;

    if (!houseNo || houseNo.trim() === "") {
      return res.status(400).json({ success: false, message: "House / Flat number is required" });
    }
    if (!city || city.trim() === "") {
      return res.status(400).json({ success: false, message: "City is required" });
    }
    if (!pincode || pincode.trim() === "") {
      return res.status(400).json({ success: false, message: "Pincode is required" });
    }

    const parts = [houseNo.trim()];
    if (floor && floor.trim()) parts.push(`Floor ${floor.trim()}`);
    if (building && building.trim()) parts.push(building.trim());
    if (area && area.trim()) parts.push(area.trim());
    if (landmark && landmark.trim()) parts.push(`Near ${landmark.trim()}`);
    parts.push(city.trim());
    if (state && state.trim()) parts.push(state.trim());
    parts.push(pincode.trim());
    const fullAddress = parts.join(", ");

    const addrData = {
      houseNo: houseNo.trim(), floor: floor || "", building: building || "",
      area: area || "", landmark: landmark || "", fullAddress,
      city: city.trim(), state: state || "", pincode: pincode.trim(),
      addressType: addressType || "home",
      latitude: latitude || 0, longitude: longitude || 0,
    };

    let address;
    if (addressId) {
      address = await Address.findOneAndUpdate(
        { _id: addressId, userId: req.user.id },
        addrData,
        { new: true }
      );
    } else {
      address = await Address.create({ userId: req.user.id, ...addrData });
    }

    // Mirror onto user profile so order fallback works
    await User.findByIdAndUpdate(req.user.id, {
      $set: {
        "address.houseNo": addrData.houseNo,
        "address.floor": addrData.floor,
        "address.building": addrData.building,
        "address.area": addrData.area,
        "address.landmark": addrData.landmark,
        "address.fullAddress": addrData.fullAddress,
        "address.city": addrData.city,
        "address.state": addrData.state,
        "address.pincode": addrData.pincode,
        ...(latitude !== undefined && { "address.location.latitude": latitude }),
        ...(longitude !== undefined && { "address.location.longitude": longitude }),
      },
    });

    res.status(200).json({ success: true, message: "Address saved", address });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET PAST DELIVERY ADDRESSES from order history (deduplicated, max 3)
const getPastAddresses = async (req, res) => {
  try {
    const orders = await Order.find({ customerId: req.user.id })
      .select("deliveryAddress createdAt")
      .sort({ createdAt: -1 })
      .limit(20);
    const seen = new Set();
    const unique = [];
    for (const order of orders) {
      const addr = order.deliveryAddress;
      if (!addr || !addr.fullAddress) continue;
      const key = addr.fullAddress.trim().toLowerCase();
      if (!seen.has(key)) {
        seen.add(key);
        unique.push(addr);
        if (unique.length >= 3) break;
      }
    }
    res.status(200).json({ success: true, addresses: unique });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET USER'S ORDER HISTORY
const getOrders = async (req, res) => {
  try {
    const orders = await Order.find({ customerId: req.user.id })
      .populate("vendorId", "shopName shopImage")
      .populate("deliveryPartnerId", "name phone vehicleType vehicleNumber profileImage currentLocation")
      .populate("products.productId", "productName images sellingPrice mrpPrice unit")
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET USER NOTIFICATIONS
const getNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);
    res.status(200).json({ success: true, notifications });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// MARK SINGLE NOTIFICATION AS READ
const markNotificationRead = async (req, res) => {
  try {
    const { id } = req.params;
    await Notification.findOneAndUpdate({ _id: id, userId: req.user.id }, { isRead: true });
    res.status(200).json({ success: true, message: "Notification marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// MARK ALL NOTIFICATIONS AS READ
const markAllNotificationsRead = async (req, res) => {
  try {
    await Notification.updateMany({ userId: req.user.id, isRead: false }, { isRead: true });
    res.status(200).json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// CREATE A SUPPORT TICKET
const createSupportTicket = async (req, res) => {
  try {
    const { subject, message } = req.body;
    if (!subject || !subject.trim() || !message || !message.trim()) {
      return res.status(400).json({ success: false, message: "Subject and message are required" });
    }
    const SupportTicket = require("../models/SupportTicket");
    const ticket = await SupportTicket.create({
      userId: req.user.id,
      subject: subject.trim(),
      message: message.trim(),
      status: "open",
    });
    res.status(201).json({ success: true, message: "Support ticket created successfully", ticket });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET USER'S SUPPORT TICKETS
const getSupportTickets = async (req, res) => {
  try {
    const SupportTicket = require("../models/SupportTicket");
    const tickets = await SupportTicket.find({ userId: req.user.id }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, tickets });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE FCM TOKEN
const updateFcmToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) return res.status(400).json({ success: false, message: "FCM token is required" });
    
    await User.findByIdAndUpdate(req.user.id, { fcmToken });
    res.status(200).json({ success: true, message: "FCM token updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  updateFcmToken,
  sendOTP,
  verifyOTP,
  getProfile,
  updateProfile,
  uploadProfilePhoto,
  registerUser,
  updateLocation,
  saveAddress,
  getSavedAddresses,
  addSavedAddress,
  getPastAddresses,
  getOrders,
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  createSupportTicket,
  getSupportTickets,
};
