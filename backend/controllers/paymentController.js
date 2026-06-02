const Razorpay = require("razorpay");
const crypto = require("crypto");

const createOrder = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount) return res.status(400).json({ success: false, message: "Amount is required" });

    // Validate that keys are present
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      console.warn("Razorpay keys are missing in .env file.");
      return res.status(500).json({ success: false, message: "Payment gateway is not configured properly." });
    }

    const razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });

    const options = {
      amount: Math.round(amount * 100), // Razorpay expects amount in smallest currency unit (paise)
      currency: "INR",
      receipt: "receipt_" + Date.now() + "_" + Math.floor(Math.random() * 1000),
    };

    const order = await razorpay.orders.create(options);
    res.json({ success: true, orderId: order.id, amount: order.amount, key: process.env.RAZORPAY_KEY_ID });
  } catch (error) {
    console.error("Razorpay createOrder error:", error);
    res.status(500).json({ success: false, message: error.message || "Failed to create payment order" });
  }
};

const verifyPayment = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ success: false, message: "Missing Razorpay parameters" });
    }

    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest("hex");

    if (expectedSignature === razorpay_signature) {
      res.json({ success: true, message: "Payment verified successfully" });
    } else {
      res.status(400).json({ success: false, message: "Invalid payment signature" });
    }
  } catch (error) {
    console.error("Razorpay verifyPayment error:", error);
    res.status(500).json({ success: false, message: "Failed to verify payment" });
  }
};

module.exports = { createOrder, verifyPayment };
