const Wishlist = require("../models/Wishlist");
const Product = require("../models/Product");

// GET USER'S WISHLIST
const getWishlist = async (req, res) => {
  try {
    let wishlist = await Wishlist.findOne({ userId: req.user.id })
      .populate("productIds", "productName images sellingPrice mrpPrice unit weight stock isAvailable rating vendorId");

    if (!wishlist) {
      wishlist = await Wishlist.create({ userId: req.user.id, productIds: [] });
    }

    res.status(200).json({
      success: true,
      wishlist,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ADD PRODUCT TO WISHLIST
const addToWishlist = async (req, res) => {
  try {
    const { productId } = req.body;
    if (!productId) {
      return res.status(400).json({ success: false, message: "productId is required" });
    }

    let wishlist = await Wishlist.findOne({ userId: req.user.id });
    if (!wishlist) {
      wishlist = await Wishlist.create({ userId: req.user.id, productIds: [] });
    }

    if (!wishlist.productIds.includes(productId)) {
      wishlist.productIds.push(productId);
      await wishlist.save();
    }

    await wishlist.populate("productIds", "productName images sellingPrice mrpPrice unit weight stock isAvailable rating vendorId");

    res.status(200).json({
      success: true,
      message: "Product added to wishlist",
      wishlist,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// REMOVE PRODUCT FROM WISHLIST
const removeFromWishlist = async (req, res) => {
  try {
    const { productId } = req.params;
    if (!productId) {
      return res.status(400).json({ success: false, message: "productId is required" });
    }

    let wishlist = await Wishlist.findOne({ userId: req.user.id });
    if (wishlist) {
      wishlist.productIds = wishlist.productIds.filter(id => id.toString() !== productId);
      await wishlist.save();
    }

    await wishlist.populate("productIds", "productName images sellingPrice mrpPrice unit weight stock isAvailable rating vendorId");

    res.status(200).json({
      success: true,
      message: "Product removed from wishlist",
      wishlist,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  getWishlist,
  addToWishlist,
  removeFromWishlist,
};
