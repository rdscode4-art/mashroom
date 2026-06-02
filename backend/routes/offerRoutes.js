const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const { uploadOffer } = require("../middleware/uploadMiddleware");
const {
  getOffers, getSpecialOffer,
  addOffer, updateOffer, deleteOffer, toggleOffer, getAllOffersAdmin
} = require("../controllers/offerController");

const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === "admin") return next();
  res.status(403).json({ success: false, message: "Admin access required" });
};

// Public
router.get("/", getOffers);                                              // all active offers
router.get("/special", getSpecialOffer);                                 // legacy single offer

// Admin protected
router.get("/all", protect, isAdmin, getAllOffersAdmin);
router.post("/", protect, isAdmin, uploadOffer.single("image"), addOffer);
router.put("/:id", protect, isAdmin, uploadOffer.single("image"), updateOffer);
router.delete("/:id", protect, isAdmin, deleteOffer);
router.put("/:id/toggle", protect, isAdmin, toggleOffer);

module.exports = router;
