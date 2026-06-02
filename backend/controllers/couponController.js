const Coupon = require("../models/Coupon");

// VALIDATE A COUPON CODE against cart subtotal
const validateCoupon = async (req, res) => {
  try {
    const { code, subtotal } = req.body;
    if (!code) return res.status(400).json({ success: false, message: "Coupon code is required" });

    const coupon = await Coupon.findOne({ code: code.toUpperCase().trim() });
    if (!coupon) return res.status(404).json({ success: false, message: "Invalid coupon code" });

    // Check expiry
    if (coupon.expiryDate && new Date(coupon.expiryDate) < new Date()) {
      return res.status(400).json({ success: false, message: "This coupon has expired" });
    }

    // Check minimum order
    const orderAmount = parseFloat(subtotal) || 0;
    if (coupon.minimumOrder && orderAmount < coupon.minimumOrder) {
      return res.status(400).json({
        success: false,
        message: `Minimum order of ₹${coupon.minimumOrder} required for this coupon`,
      });
    }

    // Calculate discount
    let discountAmount = 0;
    if (coupon.discountType === "percentage") {
      discountAmount = parseFloat(((orderAmount * coupon.discountValue) / 100).toFixed(2));
    } else {
      discountAmount = Math.min(coupon.discountValue, orderAmount);
    }

    res.json({
      success: true,
      message: "Coupon applied successfully!",
      coupon: {
        code: coupon.code,
        discountType: coupon.discountType,
        discountValue: coupon.discountValue,
        discountAmount,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET ALL ACTIVE COUPONS (public — for showing available coupons in app)
const getActiveCoupons = async (req, res) => {
  try {
    const now = new Date();
    const coupons = await Coupon.find({
      $or: [{ expiryDate: null }, { expiryDate: { $gt: now } }],
    }).sort({ createdAt: -1 });
    res.json({ success: true, coupons });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { validateCoupon, getActiveCoupons };
