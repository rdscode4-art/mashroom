const express = require("express");

const router = express.Router();

const {
  addCategory,
  getCategories,
} = require("../controllers/categoryController");

const {
  protect,
} = require("../middleware/authMiddleware");

router.post("/add", protect, addCategory);

router.get("/", getCategories);

module.exports = router;