const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      default: "",
    },

    phone: {
      type: String,
      required: true,
      unique: true,
    },

   email: {
  type: String,
  sparse: true,
  default: null,
},

    profileImage: {
      type: String,
      default: "",
    },

    role: {
      type: String,
      enum: ["customer", "vendor", "delivery", "admin"],
      default: "customer",
    },

    otp: {
      type: String,
      default: null,
    },

    otpExpiry: {
      type: Date,
      default: null,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    fcmToken: {
      type: String,
      default: "",
    },

    walletBalance: {
      type: Number,
      default: 0,
    },

    address: {
      houseNo: { type: String, default: "" },
      floor: { type: String, default: "" },
      building: { type: String, default: "" },
      area: { type: String, default: "" },
      landmark: { type: String, default: "" },
      fullAddress: { type: String, default: "" },
      city: { type: String, default: "" },
      state: { type: String, default: "" },
      pincode: { type: String, default: "" },
      location: {
        latitude: { type: Number, default: 0.0 },
        longitude: { type: Number, default: 0.0 },
      },
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);