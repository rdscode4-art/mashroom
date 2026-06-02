const Review = require("../models/Review");
const Order = require("../models/Order");
const Product = require("../models/Product");

// POST A REVIEW — only allowed if user has a delivered order containing this product
const postReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { productId, vendorId, rating, reviewText } = req.body;

    if (!productId || !rating) {
      return res.status(400).json({ success: false, message: "productId and rating are required" });
    }
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ success: false, message: "Rating must be between 1 and 5" });
    }

    // Check user has a delivered order containing this product
    const deliveredOrder = await Order.findOne({
      customerId: userId,
      orderStatus: "delivered",
      "products.productId": productId,
    });
    if (!deliveredOrder) {
      return res.status(403).json({
        success: false,
        message: "You can only review products from delivered orders.",
      });
    }

    // Prevent duplicate review
    const existing = await Review.findOne({ userId, productId });
    if (existing) {
      return res.status(400).json({ success: false, message: "You have already reviewed this product." });
    }

    const review = await Review.create({ userId, productId, vendorId, rating, reviewText });

    // Update product's average rating and reviewsCount
    const allReviews = await Review.find({ productId });
    const avgRating = allReviews.reduce((sum, r) => sum + (r.rating || 0), 0) / allReviews.length;
    await Product.findByIdAndUpdate(productId, {
      rating: parseFloat(avgRating.toFixed(1)),
      reviewsCount: allReviews.length,
    });

    const populated = await review.populate("userId", "name profileImage");
    res.status(201).json({ success: true, message: "Review posted", review: populated });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET REVIEWS FOR A PRODUCT
const getProductReviews = async (req, res) => {
  try {
    const { productId } = req.params;
    const reviews = await Review.find({ productId })
      .populate("userId", "name profileImage")
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// CHECK IF USER CAN REVIEW A PRODUCT (has delivered order with this product, hasn't reviewed yet)
const canReview = async (req, res) => {
  try {
    const userId = req.user.id;
    const { productId } = req.params;

    const deliveredOrder = await Order.findOne({
      customerId: userId,
      orderStatus: "delivered",
      "products.productId": productId,
    });
    if (!deliveredOrder) {
      return res.json({ success: true, canReview: false, reason: "no_delivered_order" });
    }

    const existing = await Review.findOne({ userId, productId });
    if (existing) {
      return res.json({ success: true, canReview: false, reason: "already_reviewed", review: existing });
    }

    res.json({ success: true, canReview: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { postReview, getProductReviews, canReview };
