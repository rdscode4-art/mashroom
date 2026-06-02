const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },

    vendorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Vendor",
    },

    deliveryPartnerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DeliveryPartner",
    },

    products: [
      {
        productId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Product",
        },

        quantity: Number,

        price: Number,
      },
    ],

    totalAmount: Number,

    deliveryCharge: Number,

    tax: Number,

    paymentMethod: {
      type: String,
      enum: ["cod", "online"],
      default: "cod",
    },

    paymentStatus: {
      type: String,
      enum: ["pending", "paid"],
      default: "pending",
    },

    orderStatus: {
      type: String,
      enum: [
        "pending",
        "accepted",
        "packed",
        "ready_for_pickup",   // vendor packed, waiting for delivery partner
        "out_for_delivery",   // delivery partner picked up
        "delivered",
        "cancelled",
      ],
      default: "pending",
    },

    pickupOTP: String,

    orderOTP: String,

    deliveryAddress: {
      fullAddress: String,
      city: String,
      state: String,
      pincode: String,
      landmark: String,
      latitude: Number,
      longitude: Number,
    },

    driverEarning: {
      type: Number,
      default: 0,
    },

    deliveryDistance: {
      type: Number,
      default: 0,
    },

    couponCode: {
      type: String,
      default: "",
    },

    couponDiscount: {
      type: Number,
      default: 0,
    },

    razorpayOrderId: {
      type: String,
      default: "",
    },

    razorpayPaymentId: {
      type: String,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Order", orderSchema);
