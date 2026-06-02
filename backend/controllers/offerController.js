const Offer = require("../models/Offer");

// GET ALL ACTIVE OFFERS (public — used by Flutter app)
const getOffers = async (req, res) => {
  try {
    const offers = await Offer.find({ isActive: true }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET SINGLE SPECIAL OFFER (legacy endpoint — kept for backward compat)
const getSpecialOffer = async (req, res) => {
  try {
    let offer = await Offer.findOne({ isActive: true });
    if (!offer) {
      offer = await Offer.create({
        title: "Get 25% OFF",
        discountText: "25% OFF",
        description: "On your first order today!",
        badgeText: "LIMITED TIME",
        isActive: true,
      });
    }
    res.status(200).json({ success: true, offer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ADD OFFER (admin)
const addOffer = async (req, res) => {
  try {
    const { title, discountText, description, badgeText } = req.body;
    if (!title || !discountText || !description || !badgeText) {
      return res.status(400).json({ success: false, message: "All fields are required" });
    }
    const imagePath = req.file ? req.file.path.replace(/\\/g, "/") : "";
    const offer = await Offer.create({
      title, discountText, description, badgeText,
      image: imagePath,
      isActive: true,
    });
    res.status(201).json({ success: true, message: "Offer created", offer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// UPDATE OFFER (admin)
const updateOffer = async (req, res) => {
  try {
    const { title, discountText, description, badgeText, isActive } = req.body;
    const updates = {};
    if (title !== undefined) updates.title = title;
    if (discountText !== undefined) updates.discountText = discountText;
    if (description !== undefined) updates.description = description;
    if (badgeText !== undefined) updates.badgeText = badgeText;
    if (isActive !== undefined) updates.isActive = isActive;
    if (req.file) updates.image = req.file.path.replace(/\\/g, "/");

    const offer = await Offer.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!offer) return res.status(404).json({ success: false, message: "Offer not found" });
    res.status(200).json({ success: true, message: "Offer updated", offer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE OFFER (admin)
const deleteOffer = async (req, res) => {
  try {
    await Offer.findByIdAndDelete(req.params.id);
    res.status(200).json({ success: true, message: "Offer deleted" });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// TOGGLE OFFER ACTIVE STATUS (admin)
const toggleOffer = async (req, res) => {
  try {
    const offer = await Offer.findById(req.params.id);
    if (!offer) return res.status(404).json({ success: false, message: "Offer not found" });
    offer.isActive = !offer.isActive;
    await offer.save();
    res.status(200).json({ success: true, message: `Offer ${offer.isActive ? "activated" : "deactivated"}`, offer });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET ALL OFFERS (admin — both active & inactive)
const getAllOffersAdmin = async (req, res) => {
  try {
    const offers = await Offer.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, offers });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { getOffers, getSpecialOffer, addOffer, updateOffer, deleteOffer, toggleOffer, getAllOffersAdmin };
