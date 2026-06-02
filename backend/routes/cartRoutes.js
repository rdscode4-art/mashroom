const express = require("express");
const router = express.Router();

const {
  getCart,
  addToCart,
  replaceCart,
  updateCartItem,
  removeCartItem,
  clearCart,
} = require("../controllers/cartController");

const { protect } = require("../middleware/authMiddleware");

// All cart routes require authentication
router.use(protect);

// GET /api/cart — get user's current cart
router.get("/", getCart);

// POST /api/cart/add — add item to cart (with vendor conflict check)
router.post("/add", addToCart);

// POST /api/cart/replace — replace cart (user confirmed vendor switch)
router.post("/replace", replaceCart);

// PUT /api/cart/update — update item quantity
router.put("/update", updateCartItem);

// DELETE /api/cart/remove/:productId — remove single item
router.delete("/remove/:productId", removeCartItem);

// DELETE /api/cart/clear — clear entire cart
router.delete("/clear", clearCart);

module.exports = router;
