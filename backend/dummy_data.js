const mongoose = require("mongoose");
const dotenv = require("dotenv");
const User = require("./models/User");
const Vendor = require("./models/Vendor");
const Product = require("./models/Product");
const Category = require("./models/Category");

dotenv.config();

const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log("MongoDB connected");
  } catch (error) {
    console.error("MongoDB connection FAIL", error);
    process.exit(1);
  }
};

const importData = async () => {
  try {
    await connectDB();

    console.log("Clearing old data...");
    await User.deleteMany();
    await Vendor.deleteMany();
    await Product.deleteMany();
    await Category.deleteMany();

    console.log("Creating categories...");
    const cat1 = await Category.create({ name: "Fresh Vegetables", icon: "eco" });
    const cat2 = await Category.create({ name: "Organic Fruits", icon: "apple" });
    const cat3 = await Category.create({ name: "Mushrooms", icon: "grass" });

    console.log("Creating dummy vendor user...");
    const vendorUser = await User.create({
      name: "Ramesh Farmer",
      phone: "9876543210",
      email: "vendor@rifresh.com",
      role: "vendor",
      isVerified: true,
      address: {
        fullAddress: "Plot 42, Patia",
        city: "Bhubaneswar",
        state: "Odisha",
        pincode: "751024",
        location: { latitude: 20.34, longitude: 85.81 },
      },
    });

    console.log("Creating dummy customer user...");
    const customerUser = await User.create({
      name: "Rahul Customer",
      phone: "9988776655",
      email: "customer@rifresh.com",
      role: "customer",
      isVerified: true,
    });

    console.log("Creating vendor profile...");
    const vendorProfile = await Vendor.create({
      userId: vendorUser._id,
      shopName: "RiFresh Mushroom Farm",
      ownerName: "Ramesh Farmer",
      phone: "9876543210",
      shopImage: "uploads/shop_banner.jpg", // Assuming some dummy image string
      shopBanner: "uploads/shop_banner.jpg",
      description: "We sell the freshest organic mushrooms and vegetables directly from our farm in Patia.",
      rating: 4.8,
      totalReviews: 124,
      totalOrders: 450,
      totalEarnings: 45000,
      deliveryTime: "25-30 mins",
      minimumOrder: 99,
      deliveryCharge: 20,
      isOpen: true,
      isApproved: true,
      isOnline: true,
      cuisineTags: ["Organic", "Mushroom", "Vegetables"],
      address: {
        fullAddress: "Plot 42, Farm Road, Patia",
        city: "Bhubaneswar",
        state: "Odisha",
        pincode: "751024",
        location: { latitude: 20.34, longitude: 85.81 },
      },
    });

    console.log("Creating dummy products...");
    await Product.create([
      {
        vendorId: vendorProfile._id,
        categoryId: cat3._id,
        productName: "Button Mushroom",
        description: "Fresh white button mushrooms harvested today.",
        images: ["uploads/product1.jpg"],
        mrpPrice: 120,
        sellingPrice: 100,
        stock: 50,
        unit: "kg",
        weight: "500g",
        isFeatured: true,
        isAvailable: true,
      },
      {
        vendorId: vendorProfile._id,
        categoryId: cat3._id,
        productName: "Oyster Mushroom",
        description: "Organic oyster mushrooms, rich in protein.",
        images: ["uploads/product2.jpg"],
        mrpPrice: 150,
        sellingPrice: 130,
        stock: 30,
        unit: "kg",
        weight: "250g",
        isFeatured: true,
        isAvailable: true,
      },
      {
        vendorId: vendorProfile._id,
        categoryId: cat1._id,
        productName: "Farm Fresh Tomatoes",
        description: "Red and juicy tomatoes without any pesticides.",
        images: ["uploads/product3.jpg"],
        mrpPrice: 60,
        sellingPrice: 45,
        stock: 100,
        unit: "kg",
        weight: "1 kg",
        isFeatured: false,
        isAvailable: true,
      },
    ]);

    console.log("Data Imported Successfully! ✅");
    console.log("-----------------------------------------");
    console.log(`Test Vendor Phone: 9876543210`);
    console.log(`Test Customer Phone: 9988776655`);
    console.log("-----------------------------------------");
    process.exit();
  } catch (error) {
    console.error("Error with import: ", error);
    process.exit(1);
  }
};

importData();
