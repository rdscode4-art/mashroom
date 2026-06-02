const mongoose = require("mongoose");

const vendorSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    shopName: String,

    ownerName: String,

    phone: String,

    shopImage: String,

    shopBanner: {
      type: String,
      default: "",
    },

    description: String,

    address: {
      fullAddress: String,
      city: String,
      state: String,
      pincode: String,

      location: {
        latitude: Number,
        longitude: Number,
      },
    },

    rating: {
      type: Number,
      default: 0,
    },

    totalReviews: {
      type: Number,
      default: 0,
    },

    totalOrders: {
      type: Number,
      default: 0,
    },

    totalEarnings: {
      type: Number,
      default: 0,
    },

    deliveryTime: {
      type: String,
      default: "30-45 mins",
    },

    minimumOrder: {
      type: Number,
      default: 100,
    },

    deliveryCharge: {
      type: Number,
      default: 30,
    },

    isOpen: {
      type: Boolean,
      default: true,
    },

    isApproved: {
      type: Boolean,
      default: false,
    },

    isOnline: {
      type: Boolean,
      default: false,
    },

    cuisineTags: {
      type: [String],
      default: [],
    },

    serviceRadius: {
      type: Number,
      default: 10,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Vendor", vendorSchema);