const mongoose = require("mongoose");

const addressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    houseNo: { type: String, default: "" },
    floor: { type: String, default: "" },
    building: { type: String, default: "" },
    area: { type: String, default: "" },
    fullAddress: { type: String, default: "" },
    landmark: { type: String, default: "" },
    city: { type: String, default: "" },
    state: { type: String, default: "" },
    pincode: { type: String, default: "" },

    addressType: {
      type: String,
      enum: ["home", "work", "other"],
      default: "home",
    },

    latitude: { type: Number, default: 0 },
    longitude: { type: Number, default: 0 },

    isDefault: { type: Boolean, default: false },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Address", addressSchema);