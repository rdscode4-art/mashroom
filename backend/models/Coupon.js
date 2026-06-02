const mongoose = require("mongoose");

const couponSchema = new mongoose.Schema(
  {
    code: String,

    discountType: {
      type: String,
      enum: ["percentage", "fixed"],
    },

    discountValue: Number,

    minimumOrder: Number,

    expiryDate: Date,

    usageLimit: Number,
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Coupon", couponSchema);