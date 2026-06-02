const express = require("express");
const router = express.Router();
const { uploadProfile } = require("../middleware/uploadMiddleware");

const {
  sendOTP,
  verifyOTP,
  getProfile,
  updateProfile,
  uploadProfilePhoto,
  registerUser,
  updateLocation,
  getOrders,
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  saveAddress,
  getSavedAddresses,
  addSavedAddress,
  createSupportTicket,
  getSupportTickets,
  updateFcmToken,
} = require("../controllers/authController");

const { protect } = require("../middleware/authMiddleware");

router.post("/send-otp", sendOTP);
router.post("/verify-otp", verifyOTP);
router.get("/profile", protect, getProfile);
router.put("/profile", protect, updateProfile);
router.post("/profile/photo", protect, uploadProfile.single("profileImage"), uploadProfilePhoto);
router.post("/register", registerUser);
router.put("/location", protect, updateLocation);
router.put("/fcm-token", protect, updateFcmToken);
router.post("/address", protect, saveAddress);          // legacy profile address upsert
router.get("/addresses", protect, getSavedAddresses);   // list all saved addresses
router.post("/addresses", protect, addSavedAddress);    // add / update a saved address
router.get("/orders", protect, getOrders);
router.get("/notifications", protect, getNotifications);
router.put("/notifications/:id/read", protect, markNotificationRead);
router.put("/notifications/read-all", protect, markAllNotificationsRead);

// Support Tickets
router.post("/tickets", protect, createSupportTicket);
router.get("/tickets", protect, getSupportTickets);

module.exports = router;