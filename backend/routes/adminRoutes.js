const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");

const {
  adminLogin,
  getStats,
  getVendors,
  approveVendor,
  getOrders,
  updateOrderStatus,
  getProducts,
  deleteProduct,
  addCategory,
  deleteCategory,
  toggleProductFeatured,
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
} = require("../controllers/adminController");

// Admin role authorization middleware
const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === "admin") {
    next();
  } else {
    res.status(403).json({
      success: false,
      message: "Access denied. Admin authorization required."
    });
  }
};

// PUBLIC: Secure admin login with phone + password (no OTP, no make-admin exploit)
router.post("/login", adminLogin);

// PROTECTED: All admin operations require valid JWT + admin role
router.get("/stats", protect, isAdmin, getStats);
router.get("/vendors", protect, isAdmin, getVendors);
router.put("/vendors/:id/approve", protect, isAdmin, approveVendor);
router.get("/orders", protect, isAdmin, getOrders);
router.put("/orders/:id/status", protect, isAdmin, updateOrderStatus);
router.get("/products", protect, isAdmin, getProducts);
router.delete("/products/:id", protect, isAdmin, deleteProduct);
router.put("/products/:id/feature", protect, isAdmin, toggleProductFeatured);
router.post("/categories", protect, isAdmin, addCategory);
router.delete("/categories/:id", protect, isAdmin, deleteCategory);

router.get("/customers", protect, isAdmin, getCustomers);
router.get("/delivery-partners", protect, isAdmin, getDeliveryPartners);
router.put("/delivery-partners/:id/kyc", protect, isAdmin, updateDriverKyc);
router.post("/send-notification", protect, isAdmin, sendManualNotification);

// NEW DASHBOARD ROUTES
router.get("/withdrawals", protect, isAdmin, getWithdrawals);
router.get("/reviews", protect, isAdmin, getReviews);
router.get("/coupons", protect, isAdmin, getCoupons);
router.get("/banners", protect, isAdmin, getBanners);
router.get("/tickets", protect, isAdmin, getTickets);
router.get("/settings", protect, isAdmin, getSettings);
router.put("/settings", protect, isAdmin, updateSettings);

module.exports = router;
