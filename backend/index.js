const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const connectDB = require("./config/db");

const authRoutes = require("./routes/authRoutes");
const productRoutes = require("./routes/productRoutes");
const categoryRoutes = require("./routes/categoryRoutes");
const vendorRoutes = require("./routes/vendorRoutes");
const cartRoutes = require("./routes/cartRoutes");
const wishlistRoutes = require("./routes/wishlistRoutes");
const offerRoutes = require("./routes/offerRoutes");
const orderRoutes = require("./routes/orderRoutes");
const adminRoutes = require("./routes/adminRoutes");
const reviewRoutes = require("./routes/reviewRoutes");
const couponRoutes = require("./routes/couponRoutes");
const deliveryRoutes = require("./routes/deliveryRoutes");
const paymentRoutes = require("./routes/paymentRoutes");

const app = express();

connectDB();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/categories", categoryRoutes);
app.use("/api/vendors", vendorRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/wishlist", wishlistRoutes);
app.use("/api/offers", offerRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/coupons", couponRoutes);
app.use("/api/delivery", deliveryRoutes);
app.use("/api/payment", paymentRoutes);

// Public settings endpoint — Flutter app reads delivery charge & tax without auth
const Settings = require("./models/Settings");
app.get("/api/settings", async (req, res) => {
  try {
    let s = await Settings.findOne();
    if (!s) s = await Settings.create({});
    res.json({ success: true, settings: s });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});

// Public banners endpoint — Flutter app fetches active banners without auth
const Banner = require("./models/Banner");
app.get("/api/banners", async (req, res) => {
  try {
    const banners = await Banner.find({ isActive: true }).sort({ createdAt: -1 });
    res.json({ success: true, banners });
  } catch (e) {
    res.status(500).json({ success: false, message: e.message });
  }
});


app.use(
  "/uploads",
  express.static(
    path.join(__dirname, "uploads")
  )
);

// Vendor panel is served independently by Vite from ../vendor_panel.

app.get("/", (req, res) => {
  res.send("RiFresh India API Running. Vendor panel runs separately at http://localhost:4174");
});

/*
app.get("/", (req, res) => {
  res.send("RiFresh India API Running 🚀. Open http://localhost:5000/vendor-panel for the Vendor Web Panel!");
});

*/

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
