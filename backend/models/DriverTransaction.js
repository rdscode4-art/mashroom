const mongoose = require("mongoose");

const driverTransactionSchema = new mongoose.Schema(
  {
    deliveryPartnerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DeliveryPartner",
      required: true,
    },
    amount: {
      type: Number,
      required: true,
    }, // positive for earnings, negative for withdrawals
    type: {
      type: String,
      enum: ["earning", "withdrawal"],
      required: true,
    },
    description: {
      type: String,
      default: "",
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
      default: null,
    },
    withdrawalId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "WithdrawalRequest",
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("DriverTransaction", driverTransactionSchema);
