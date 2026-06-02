const express = require("express");
const { upload } = require("../middleware/uploadMiddleware");

const router = express.Router();

const {
  addProduct,
  updateProduct,
  getProducts,
  getSingleProduct,
  deleteProduct,
} = require("../controllers/productController");

const {
  protect,
} = require("../middleware/authMiddleware");

// Add a new product
router.post(
  "/add",
  protect,
  upload.array("images", 5),
  addProduct
);

// Update an existing product
router.put(
  "/:id",
  protect,
  upload.array("images", 5),
  updateProduct
);

// Get all products
router.get("/", getProducts);

// Get a single product
router.get("/:id", getSingleProduct);

// Delete a product
router.delete(
  "/:id",
  protect,
  deleteProduct
);

module.exports = router;
