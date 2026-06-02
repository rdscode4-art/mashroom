const mongoose = require("mongoose");

const supportTicketSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    subject: String,

    message: String,

    status: {
      type: String,
      enum: ["open", "closed", "pending"],
      default: "open",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "SupportTicket",
  supportTicketSchema
);