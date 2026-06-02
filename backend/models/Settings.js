const mongoose = require("mongoose");

const settingsSchema = new mongoose.Schema(
  {
    deliveryCharge: { type: Number, default: 30 },
    taxPercent: { type: Number, default: 5 },
    minimumOrder: { type: Number, default: 0 },
    supportNumber: { type: String, default: "" },
    appVersion: { type: String, default: "1.0.0" },
    appName: { type: String, default: "RiFresh" },
    isMaintenanceMode: { type: Boolean, default: false },
    razorpayKeyId: { type: String, default: "" },
    deliveryPartnerRadius: { type: Number, default: 2 }, // km — broadcast radius for delivery partner assignment
    deliveryBaseFare: { type: Number, default: 25 },
    deliveryPerKmRate: { type: Number, default: 5 },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Settings", settingsSchema);