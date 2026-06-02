const mongoose = require("mongoose");

const deliveryPartnerSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    name: String,
    phone: String,
    email: { type: String, default: "" },
    vehicleType: { type: String, enum: ["bike", "scooter", "cycle", "other"], default: "bike" },
    vehicleNumber: String,
    profileImage: String,
    isOnline: { type: Boolean, default: false },
    isAvailable: { type: Boolean, default: true },
    currentLocation: { latitude: Number, longitude: Number },
    activeOrderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order", default: null },
    totalDeliveries: { type: Number, default: 0 },
    earnings: { type: Number, default: 0 },

    // KYC fields
    kyc: {
      aadharNumber: { type: String, default: "" },
      aadharFront: { type: String, default: "" },   // file path
      aadharBack: { type: String, default: "" },    // file path
      dlNumber: { type: String, default: "" },
      dlImage: { type: String, default: "" },       // file path
    },
    kycStatus: {
      type: String,
      enum: ["pending", "submitted", "approved", "rejected"],
      default: "pending",
    },
    kycRejectionReason: { type: String, default: "" },
    isApproved: { type: Boolean, default: false },  // set true when admin approves KYC
  },
  { timestamps: true }
);

module.exports = mongoose.model("DeliveryPartner", deliveryPartnerSchema);