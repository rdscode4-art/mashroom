const Product = require("../models/Product");
const Vendor = require("../models/Vendor");

// ADD PRODUCT (vendor adds from their panel)
const addProduct = async (req, res) => {
  try {
    // Find vendor profile linked to logged-in user
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(403).json({
        success: false,
        message: "You must have a vendor profile to add products",
      });
    }

    const {
      categoryId,
      productName,
      description,
      mrpPrice,
      sellingPrice,
      stock,
      unit,
      weight,
      tags,
      isFeatured,
    } = req.body;

    const images = [];

    if (req.files) {
      req.files.forEach((file) => {
        images.push(file.path.replace(/\\/g, "/"));
      });
    }

    const product = await Product.create({
      vendorId: vendor._id,
      categoryId,
      productName,
      description,
      images,
      mrpPrice,
      sellingPrice,
      stock,
      unit,
      weight,
      tags: tags ? (typeof tags === "string" ? JSON.parse(tags) : tags) : [],
      isFeatured: isFeatured === "true" || isFeatured === true,
    });

    res.status(201).json({
      success: true,
      message: "Product added successfully",
      product,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// UPDATE PRODUCT
const updateProduct = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(403).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const product = await Product.findOne({
      _id: req.params.id,
      vendorId: vendor._id,
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found or you don't own this product",
      });
    }

    const {
      categoryId,
      productName,
      description,
      mrpPrice,
      sellingPrice,
      stock,
      unit,
      weight,
      tags,
      isFeatured,
      isAvailable,
    } = req.body;

    if (categoryId) product.categoryId = categoryId;
    if (productName) product.productName = productName;
    if (description) product.description = description;
    if (mrpPrice !== undefined) product.mrpPrice = mrpPrice;
    if (sellingPrice !== undefined) product.sellingPrice = sellingPrice;
    if (stock !== undefined) product.stock = stock;
    if (unit) product.unit = unit;
    if (weight) product.weight = weight;
    if (tags) product.tags = typeof tags === "string" ? JSON.parse(tags) : tags;
    if (isFeatured !== undefined)
      product.isFeatured = isFeatured === "true" || isFeatured === true;
    if (isAvailable !== undefined)
      product.isAvailable = isAvailable === "true" || isAvailable === true;

    // Handle new images upload (append or replace)
    if (req.files && req.files.length > 0) {
      const newImages = req.files.map((file) =>
        file.path.replace(/\\/g, "/")
      );
      product.images = newImages; // Replace images
    }

    await product.save();

    res.status(200).json({
      success: true,
      message: "Product updated successfully",
      product,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// GET ALL PRODUCTS (public, supports location filtering)
const getProducts = async (req, res) => {
  try {
    const { lat, lng, q, featured, category } = req.query;
    let filter = {};

    if (q) {
      filter.productName = { $regex: q, $options: "i" };
    }

    if (featured === "true") {
      filter.isFeatured = true;
    }

    if (category) {
      filter.categoryId = category;
    }

    if (lat && lng) {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);

      // 1. Fetch all approved vendors
      const rawVendors = await Vendor.find({ isApproved: true });

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

      // 2. Filter vendors within dynamic radius set by admin
      const Settings = require("../models/Settings");
      const settings = await Settings.findOne();
      const adminRadius = settings?.deliveryPartnerRadius || 10;

      const nearbyVendorIds = rawVendors
        .filter((vendor) => {
          const vLat = vendor.address?.location?.latitude;
          const vLng = vendor.address?.location?.longitude;
          if (vLat === undefined || vLng === undefined) return false;

          const distance = calculateDistance(latitude, longitude, vLat, vLng);
          const allowedRadius = adminRadius;
          return distance <= allowedRadius;
        })
        .map((vendor) => vendor._id);

      // 3. Set filter to only return products from these nearby vendors
      if (nearbyVendorIds.length > 0) {
        filter.vendorId = { $in: nearbyVendorIds };
      } else {
        console.log(`⚠️ No nearby vendors found within ${adminRadius}km radius. Service not available in this area.`);
        filter.vendorId = { $in: [] }; // Enforce empty product list returning no products
      }
    }

    const products = await Product.find(filter)
      .populate("categoryId")
      .populate("vendorId", "shopName rating deliveryTime isOpen")
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

// GET SINGLE PRODUCT
const getSingleProduct = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate("categoryId")
      .populate("vendorId", "shopName rating deliveryTime deliveryCharge isOpen shopImage");

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    res.status(200).json({
      success: true,
      product,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// DELETE PRODUCT
const deleteProduct = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ userId: req.user.id });
    if (!vendor) {
      return res.status(403).json({
        success: false,
        message: "Vendor profile not found",
      });
    }

    const product = await Product.findOne({
      _id: req.params.id,
      vendorId: vendor._id,
    });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found or you don't own this product",
      });
    }

    await product.deleteOne();

    res.status(200).json({
      success: true,
      message: "Product deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  addProduct,
  updateProduct,
  getProducts,
  getSingleProduct,
  deleteProduct,
};