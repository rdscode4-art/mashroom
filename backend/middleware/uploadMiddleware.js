const multer = require("multer");
const path = require("path");
const fs = require("fs");

// PRODUCT STORAGE
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/products";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname));
  },
});

// PROFILE IMAGE STORAGE
const profileStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/profiles";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, "profile-" + req.user.id + "-" + Date.now() + path.extname(file.originalname));
  },
});

// CATEGORY IMAGE STORAGE
const categoryStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/categories";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, "category-" + Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname));
  },
});

// BANNER IMAGE STORAGE
const bannerStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/banners";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, "banner-" + Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname));
  },
});

// OFFER IMAGE STORAGE
const offerStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/offers";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, "offer-" + Date.now() + "-" + Math.round(Math.random() * 1e9) + path.extname(file.originalname));
  },
});

// KYC DOCUMENT STORAGE
const kycStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = "uploads/kyc";
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, "kyc-" + req.user.id + "-" + file.fieldname + "-" + Date.now() + path.extname(file.originalname));
  },
});

// FILE FILTER (all)
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Only images allowed"), false);
  }
};

const upload = multer({ storage, fileFilter });
const uploadProfile = multer({ storage: profileStorage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } });
const uploadCategory = multer({ storage: categoryStorage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } });
const uploadBanner = multer({ storage: bannerStorage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } });
const uploadOffer = multer({ storage: offerStorage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } });
const uploadKyc = multer({ storage: kycStorage, fileFilter, limits: { fileSize: 10 * 1024 * 1024 } });

module.exports = { upload, uploadProfile, uploadCategory, uploadBanner, uploadOffer, uploadKyc };
