const express = require("express");
const router = express.Router();

const {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
} = require("../controllers/wishlistController");

const { protect } = require("../middleware/authMiddleware");

// All wishlist routes require authentication
router.use(protect);

// GET /api/wishlist — get user's wishlist
router.get("/", getWishlist);

// POST /api/wishlist/add — add product to wishlist
router.post("/add", addToWishlist);

// DELETE /api/wishlist/remove/:productId — remove product from wishlist
router.delete("/remove/:productId", removeFromWishlist);

module.exports = router;
