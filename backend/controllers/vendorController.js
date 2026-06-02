const Vendor = require("../models/Vendor");
const Product = require("../models/Product");
const Order = require("../models/Order");
const User = require("../models/User");
const DeliveryPartner = require("../models/DeliveryPartner");
const { sendPushNotification } = require("../services/notificationService");

// ==========================================
// CUSTOMER-FACING APIs (Public)
// ==========================================

// GET ALL VENDORS (approved + online)
const getVendors = async (req, res) => {
  try {
    const vendors = await Vendor.find({
      isApproved: true,
    }).sort({ rating: -1, createdAt: -1 });

    res.status(200).json({
      success: true,
      count: vendors.length,
      vendors,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET NEARBY VENDORS (within dynamic service radius using exact Haversine formula)
const getNearbyVendors = async (req, res) => {
  try {
    const { lat, lng } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: "Latitude and longitude are required",
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);

    // Quick rough bounding box bounding max possible distance (e.g. 100km delta ~ 0.9)
    const delta = 100 * 0.009;

    const rawVendors = await Vendor.find({
      isApproved: true,
      "address.location.latitude": {
        $gte: latitude - delta,
        $lte: latitude + delta,
      },
      "address.location.longitude": {
        $gte: longitude - delta,
        $lte: longitude + delta,
      },
    });

    const deg2rad = (deg) => deg * (Math.PI / 180);
    const calculateDistance = (lat1, lon1, lat2, lon2) => {
      const R = 6371; // Earth's radius in km
      const dLat = deg2rad(lat2 - lat1);
      const dLon = deg2rad(lon2 - lon1);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    const Settings = require("../models/Settings");
    const settings = await Settings.findOne();
    const adminRadius = settings?.deliveryPartnerRadius || 10;

    let vendors = rawVendors.filter(vendor => {
      const vLat = vendor.address?.location?.latitude;
      const vLng = vendor.address?.location?.longitude;
      if (vLat === undefined || vLng === undefined) return false;

      const distance = calculateDistance(latitude, longitude, vLat, vLng);
      vendor._doc.distance = parseFloat(distance.toFixed(1));

      // Filter vendors according to radius set by admin
      const allowedRadius = adminRadius;
      return distance <= allowedRadius;
    });

    if (vendors.length === 0) {
      console.log("⚠️ No nearby vendors found within radius. Service not available in this area.");
      vendors = [];
    }

    vendors.sort((a, b) => b.rating - a.rating);

    res.status(200).json({
      success: true,
      count: vendors.length,
      vendors,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET SINGLE VENDOR BY ID (public)
const getVendorById = async (req, res) => {
  try {
    const vendor = await Vendor.findById(req.params.id);

    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    res.status(200).json({
      success: true,
      vendor,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET ALL PRODUCTS OF A SPECIFIC VENDOR (public)
const getVendorProducts = async (req, res) => {
  try {
    const vendorId = req.params.id;

    const vendor = await Vendor.findById(vendorId);
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor not found",
      });
    }

    const products = await Product.find({
      vendorId: vendorId,
      isAvailable: true,
    })
      .populate("categoryId")
      .sort({ isFeatured: -1, createdAt: -1 });

    res.status(200).json({
      success: true,
      vendor: {
        _id: vendor._id,
        shopName: vendor.shopName,
        rating: vendor.rating,
        deliveryTime: vendor.deliveryTime,
        deliveryCharge: vendor.deliveryCharge,
        minimumOrder: vendor.minimumOrder,
        isOpen: vendor.isOpen,
      },
      count: products.length,
      products,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ==========================================
// VENDOR PANEL APIs (Protected — vendor only)
// ==========================================

// GET VENDOR DASHBOARD STATS
const getVendorDashboard = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    // Count products
    const totalProducts = await Product.countDocuments({
      vendorId: vendor._id,
    });
    const availableProducts = await Product.countDocuments({
      vendorId: vendor._id,
      isAvailable: true,
    });

    // Count orders
    const totalOrders = await Order.countDocuments({
      vendorId: vendor._id,
    });
    const pendingOrders = await Order.countDocuments({
      vendorId: vendor._id,
      orderStatus: "pending",
    });
    const activeOrders = await Order.countDocuments({
      vendorId: vendor._id,
      orderStatus: { $in: ["accepted", "packed", "out_for_delivery"] },
    });
    const completedOrders = await Order.countDocuments({
      vendorId: vendor._id,
      orderStatus: "delivered",
    });

    res.status(200).json({
      success: true,
      vendor,
      stats: {
        totalProducts,
        availableProducts,
        totalOrders,
        pendingOrders,
        activeOrders,
        completedOrders,
        totalEarnings: vendor.totalEarnings,
        rating: vendor.rating,
        totalReviews: vendor.totalReviews,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET VENDOR PROFILE (own)
const getVendorProfile = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found. Please register as a vendor first.",
      });
    }

    res.status(200).json({
      success: true,
      vendor,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// UPDATE VENDOR PROFILE
const updateVendorProfile = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const {
      shopName,
      ownerName,
      phone,
      description,
      deliveryTime,
      minimumOrder,
      deliveryCharge,
      cuisineTags,
      fullAddress,
      city,
      state,
      pincode,
      latitude,
      longitude,
      serviceRadius,
    } = req.body;

    // Update fields if provided
    if (shopName) vendor.shopName = shopName;
    if (ownerName) vendor.ownerName = ownerName;
    if (phone) vendor.phone = phone;
    if (description) vendor.description = description;
    if (deliveryTime) vendor.deliveryTime = deliveryTime;
    if (minimumOrder !== undefined) vendor.minimumOrder = minimumOrder;
    if (deliveryCharge !== undefined) vendor.deliveryCharge = deliveryCharge;
    if (cuisineTags) vendor.cuisineTags = cuisineTags;
    if (serviceRadius !== undefined) vendor.serviceRadius = serviceRadius;

    // Handle shop image upload
    if (req.files && req.files.length > 0) {
      vendor.shopImage = req.files[0].path.replace(/\\/g, "/");
    }

    // Address update
    if (fullAddress || city || state || pincode || latitude || longitude) {
      if (!vendor.address) vendor.address = {};
      if (!vendor.address.location) vendor.address.location = { latitude: 0.0, longitude: 0.0 };

      if (fullAddress) vendor.address.fullAddress = fullAddress;
      if (city) vendor.address.city = city;
      if (state) vendor.address.state = state;
      if (pincode) vendor.address.pincode = pincode;
      if (latitude && !isNaN(parseFloat(latitude))) vendor.address.location.latitude = parseFloat(latitude);
      if (longitude && !isNaN(parseFloat(longitude))) vendor.address.location.longitude = parseFloat(longitude);
    }

    await vendor.save();

    res.status(200).json({
      success: true,
      message: "Vendor profile updated successfully",
      vendor,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// TOGGLE SHOP OPEN/CLOSE
const toggleShopStatus = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    vendor.isOpen = !vendor.isOpen;
    vendor.isOnline = vendor.isOpen; // sync both statuses
    await vendor.save();

    res.status(200).json({
      success: true,
      message: vendor.isOpen
        ? "Shop is now OPEN ✅"
        : "Shop is now CLOSED 🔴",
      isOpen: vendor.isOpen,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET VENDOR'S OWN PRODUCTS (all, including unavailable)
const getMyProducts = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const products = await Product.find({ vendorId: vendor._id })
      .populate("categoryId")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: products.length,
      products,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// TOGGLE PRODUCT AVAILABILITY
const toggleProductAvailability = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const product = await Product.findOne({
      _id: req.params.productId,
      vendorId: vendor._id,
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found or you don't own this product",
      });
    }

    product.isAvailable = !product.isAvailable;
    await product.save();

    res.status(200).json({
      success: true,
      message: product.isAvailable
        ? "Product is now available"
        : "Product is now unavailable",
      isAvailable: product.isAvailable,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET VENDOR'S ORDERS
const getVendorOrders = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(404).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const { status } = req.query;

    const filter = { vendorId: vendor._id };
    if (status && status !== "all") {
      filter.orderStatus = status;
    }

    const orders = await Order.find(filter)
      .populate("customerId", "name phone profileImage")
      .populate("products.productId", "productName images sellingPrice unit")
      .populate("deliveryPartnerId", "name phone vehicleType vehicleNumber")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: orders.length,
      orders,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// UPDATE ORDER STATUS (vendor accepts, packs, cancels)
const updateOrderStatus = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) return res.status(404).json({ success: false, message: "Vendor profile not found" });

    const { orderId } = req.params;
    const { orderStatus } = req.body;

    const validStatuses = ["accepted", "packed", "cancelled"];
    if (!validStatuses.includes(orderStatus)) {
      return res.status(400).json({
        success: false,
        message: `Vendor can only set status to: ${validStatuses.join(", ")}`,
      });
    }

    const order = await Order.findOne({ _id: orderId, vendorId: vendor._id });
    if (!order) return res.status(404).json({ success: false, message: "Order not found" });

    order.orderStatus = orderStatus;

    // When vendor marks order as ACCEPTED or PACKED → broadcast to all online+available partners within radius
    let broadcastCount = 0;
    if (["accepted", "packed"].includes(orderStatus)) {
      if (!order.pickupOTP) {
        order.pickupOTP = String(Math.floor(1000 + Math.random() * 9000));
      }

      const Settings = require("../models/Settings");
      let settings = await Settings.findOne();
      if (!settings) settings = await Settings.create({});
      const broadcastRadius = settings.deliveryPartnerRadius ?? 2; // km

      const deg2rad = (d) => d * (Math.PI / 180);
      const haversine = (lat1, lon1, lat2, lon2) => {
        const R = 6371;
        const dLat = deg2rad(lat2 - lat1);
        const dLon = deg2rad(lon2 - lon1);
        const a = Math.sin(dLat / 2) ** 2 +
          Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2;
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      };

      const vLat = vendor.address?.location?.latitude || 0;
      const vLng = vendor.address?.location?.longitude || 0;

      // Find all online + available partners and get their fcmToken
      const partners = await DeliveryPartner.find({ isOnline: true, isAvailable: true }).populate("userId", "fcmToken");

      // Filter to those within broadcastRadius km of the vendor
      const nearbyPartners = partners.filter(p => {
        const pLat = p.currentLocation?.latitude;
        const pLng = p.currentLocation?.longitude;
        if (!pLat || !pLng) return false;
        return haversine(vLat, vLng, pLat, pLng) <= broadcastRadius;
      });

      if (nearbyPartners.length > 0) {
        broadcastCount = nearbyPartners.length;
        
        // Extract FCM tokens
        const tokens = nearbyPartners.map(p => p.userId?.fcmToken).filter(t => t);
        if (tokens.length > 0) {
          await sendPushNotification(
            tokens, 
            "New Order Available! 📦", 
            "A new pickup request is available near you. Tap to accept.", 
            { type: "new_order" }, 
            { channel_id: "order_channel", sound: "order_sound" }
          );
        }
      }
      // If no partners nearby, order stays "accepted" — vendor sees "no riders available"
    }

    await order.save();

    res.status(200).json({
      success: true,
      message: broadcastCount > 0
        ? `Order accepted! Broadcast sent to ${broadcastCount} nearby rider${broadcastCount > 1 ? 's' : ''}. Waiting for acceptance.`
        : orderStatus === "accepted"
          ? "Order accepted. No riders available nearby right now."
          : `Order status updated to: ${order.orderStatus}`,
      order,
      broadcastCount,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// REGISTER VENDOR PROFILE (onboarding)
const registerVendor = async (req, res) => {
  try {
    let vendor = await Vendor.findOne({ userId: req.user.id });
    if (vendor) {
      return res.status(400).json({
        success: false,
        message: "You already have a vendor profile!",
      });
    }

    const {
      shopName,
      ownerName,
      phone,
      description,
      deliveryTime,
      minimumOrder,
      deliveryCharge,
      cuisineTags,
      fullAddress,
      city,
      state,
      pincode,
      latitude,
      longitude,
      serviceRadius,
    } = req.body;

    let shopImage = "";
    if (req.files && req.files.length > 0) {
      shopImage = req.files[0].path.replace(/\\/g, "/");
    }

    vendor = await Vendor.create({
      userId: req.user.id,
      shopName,
      ownerName,
      phone: phone || req.user.phone,
      shopImage,
      shopBanner: shopImage,
      description,
      deliveryTime: deliveryTime || "30 mins",
      minimumOrder: minimumOrder ? parseFloat(minimumOrder) : 0,
      deliveryCharge: deliveryCharge ? parseFloat(deliveryCharge) : 0,
      cuisineTags: cuisineTags ? (typeof cuisineTags === 'string' ? JSON.parse(cuisineTags) : cuisineTags) : [],
      serviceRadius: serviceRadius ? parseFloat(serviceRadius) : 10,
      isApproved: true, // auto-approve for testing/onboarding simplicity
      isOpen: true,
      isOnline: true,
      address: {
        fullAddress,
        city,
        state,
        pincode,
        location: {
          latitude: (latitude && !isNaN(parseFloat(latitude))) ? parseFloat(latitude) : 0.0,
          longitude: (longitude && !isNaN(parseFloat(longitude))) ? parseFloat(longitude) : 0.0,
        },
      },
    });

    // Update user role to vendor
    await User.findByIdAndUpdate(req.user.id, { role: "vendor" });

    res.status(201).json({
      success: true,
      message: "Vendor onboarded successfully! Welcome to RiFresh Odisha 🚀",
      vendor,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  // Customer-facing
  getVendors,
  getNearbyVendors,
  getVendorById,
  getVendorProducts,
  // Vendor panel
  getVendorDashboard,
  getVendorProfile,
  updateVendorProfile,
  toggleShopStatus,
  getMyProducts,
  toggleProductAvailability,
  getVendorOrders,
  updateOrderStatus,
  registerVendor,
};
