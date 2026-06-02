const mongoose = require("mongoose");

const bannerSchema = new mongoose.Schema(
  {
    title: String,

    image: String,

    redirectType: String,

    redirectId: String,

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Banner", bannerSchema);