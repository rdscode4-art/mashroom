const fs = require('fs');
const code = fs.readFileSync('controllers/adminController.js', 'utf8');

const idx = code.indexOf('const sendManualNotification = async (req, res) => {');

const goodPart = code.substring(0, idx);

const restOfFile = `const sendManualNotification = async (req, res) => {
  try {
    const { target, title, body } = req.body;
    
    if (!title || !body) {
      return res.status(400).json({ success: false, message: "Title and body are required" });
    }

    let filter = {};
    if (target === "customers") filter.role = "customer";
    else if (target === "drivers") filter.role = "delivery";
    
    const users = await User.find({ ...filter, fcmToken: { $ne: null, $ne: "" } });
    const tokens = users.map(u => u.fcmToken);

    if (tokens.length === 0) {
      return res.status(404).json({ success: false, message: "No users found with valid FCM tokens for this target" });
    }

    await sendPushNotification(tokens, title, body, { type: "admin_broadcast" });

    res.status(200).json({
      success: true,
      message: \`Notification sent to \${tokens.length} users\`
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// 13. MISSING ENDPOINTS FOR ADMIN PANEL DASHBOARD
const getWithdrawals = async (req, res) => {
  try {
    const withdrawals = await require("../models/WithdrawalRequest").find().populate("vendorId driverId").sort({ createdAt: -1 });
    res.status(200).json({ success: true, withdrawals });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getReviews = async (req, res) => {
  try {
    const reviews = await require("../models/Review").find().populate("customerId productId").sort({ createdAt: -1 });
    res.status(200).json({ success: true, reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getCoupons = async (req, res) => {
  try {
    const coupons = await require("../models/Coupon").find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, coupons });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getBanners = async (req, res) => {
  try {
    const banners = await require("../models/Banner").find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, banners });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getTickets = async (req, res) => {
  try {
    const tickets = await require("../models/SupportTicket").find().populate("userId").sort({ createdAt: -1 });
    res.status(200).json({ success: true, tickets });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getSettings = async (req, res) => {
  try {
    let settings = await require("../models/Settings").findOne();
    if (!settings) settings = await require("../models/Settings").create({});
    res.status(200).json({ success: true, settings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateSettings = async (req, res) => {
  try {
    const settingsData = req.body;
    let settings = await require("../models/Settings").findOne();
    if (!settings) {
      settings = await require("../models/Settings").create(settingsData);
    } else {
      settings = await require("../models/Settings").findOneAndUpdate({}, settingsData, { returnDocument: 'after', new: true });
    }
    res.status(200).json({ success: true, settings, message: "Settings updated successfully" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  adminLogin,
  getStats,
  getVendors,
  approveVendor,
  getOrders,
  updateOrderStatus,
  getProducts,
  deleteProduct,
  toggleProductFeatured,
  addCategory,
  deleteCategory,
  getCustomers,
  getDeliveryPartners,
  updateDriverKyc,
  sendManualNotification,
  getWithdrawals,
  getReviews,
  getCoupons,
  getBanners,
  getTickets,
  getSettings,
  updateSettings
};
`;

fs.writeFileSync('controllers/adminController.js', goodPart + restOfFile);
console.log('Fixed file.');
