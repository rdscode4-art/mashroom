const express = require("express");
const router = express.Router();
const { upload } = require("../middleware/uploadMiddleware");

const {
  // Customer-facing (public)
  getVendors,
  getNearbyVendors,
  getVendorById,
  getVendorProducts,
  // Vendor panel (protected)
  getVendorDashboard,
  getVendorProfile,
  updateVendorProfile,
  toggleShopStatus,
  getMyProducts,
  toggleProductAvailability,
  getVendorOrders,
  updateOrderStatus,
  registerVendor,
} = require("../controllers/vendorController");

const { protect } = require("../middleware/authMiddleware");

// ==========================================
// PUBLIC ROUTES (Customer App)
// ==========================================

// GET /api/vendors — all approved vendors
router.get("/", getVendors);

// GET /api/vendors/nearby?lat=20.29&lng=85.82&radius=10
router.get("/nearby", getNearbyVendors);

// ==========================================
// VENDOR PANEL ROUTES (Protected)
// ==========================================

// GET /api/vendors/panel/dashboard — vendor dashboard stats
router.get("/panel/dashboard", protect, getVendorDashboard);

// GET /api/vendors/panel/profile — get own vendor profile
router.get("/panel/profile", protect, getVendorProfile);

// POST /api/vendors/onboard — onboard new vendor
router.post(
  "/onboard",
  protect,
  upload.array("shopImage", 1),
  registerVendor
);

// PUT /api/vendors/panel/profile — update vendor profile
router.put(
  "/panel/profile",
  protect,
  upload.array("shopImage", 1),
  updateVendorProfile
);

// PUT /api/vendors/panel/toggle-shop — toggle open/close
router.put("/panel/toggle-shop", protect, toggleShopStatus);

// GET /api/vendors/panel/products — get vendor's own products (all)
router.get("/panel/products", protect, getMyProducts);

// PUT /api/vendors/panel/products/:productId/toggle — toggle product availability
router.put(
  "/panel/products/:productId/toggle",
  protect,
  toggleProductAvailability
);

// GET /api/vendors/panel/orders?status=pending — get vendor's orders
router.get("/panel/orders", protect, getVendorOrders);

// PUT /api/vendors/panel/orders/:orderId/status — update order status
router.put("/panel/orders/:orderId/status", protect, updateOrderStatus);

// ==========================================
// PUBLIC ROUTES (with ID param — keep at bottom)
// ==========================================

// GET /api/vendors/:id — single vendor detail
router.get("/:id", getVendorById);

// GET /api/vendors/:id/products — all products of a vendor
router.get("/:id/products", getVendorProducts);

module.exports = router;
