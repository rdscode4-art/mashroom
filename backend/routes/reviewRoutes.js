const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const { postReview, getProductReviews, canReview } = require("../controllers/reviewController");

router.get("/product/:productId", getProductReviews);           // public
router.get("/can-review/:productId", protect, canReview);       // auth required
router.post("/", protect, postReview);                          // auth required

module.exports = router;
