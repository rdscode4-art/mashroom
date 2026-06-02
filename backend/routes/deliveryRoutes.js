const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const { uploadProfile, uploadKyc } = require("../middleware/uploadMiddleware");
const {
  registerPartner, submitKyc, getProfile, toggleOnline, updateLocation,
  getAssignedOrder, getOrderHistory,
  acceptPickup, confirmPickup, markDelivered, getDashboard,
  getWalletHistory, requestWithdrawal, updateProfile,
} = require("../controllers/deliveryController");

// All routes require auth
router.post("/register", protect, uploadProfile.single("profileImage"), registerPartner);
router.post("/kyc", protect, uploadKyc.fields([
  { name: "aadharFront", maxCount: 1 },
  { name: "aadharBack",  maxCount: 1 },
  { name: "dlImage",     maxCount: 1 },
]), submitKyc);
router.get("/profile", protect, getProfile);
router.put("/profile", protect, uploadProfile.single("profileImage"), updateProfile);
router.get("/dashboard", protect, getDashboard);
router.put("/toggle-online", protect, toggleOnline);
router.put("/location", protect, updateLocation);
router.get("/order/assigned", protect, getAssignedOrder);
router.get("/orders/history", protect, getOrderHistory);
router.put("/order/:orderId/accept", protect, acceptPickup);
router.put("/order/:orderId/pickup", protect, confirmPickup);
router.put("/order/:orderId/deliver", protect, markDelivered);

// Wallet routes
router.get("/wallet/history", protect, getWalletHistory);
router.post("/wallet/withdraw", protect, requestWithdrawal);

module.exports = router;
