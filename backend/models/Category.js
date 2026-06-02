const mongoose = require("mongoose");

const categorySchema = new mongoose.Schema(
  {
    name: String,

    image: String,

    icon: String,

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Category", categorySchema);