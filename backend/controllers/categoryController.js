const Category = require("../models/Category");
const Product = require("../models/Product");


// ADD CATEGORY
const addCategory = async (req, res) => {
  try {
    const { name } = req.body;

    const category = await Category.create({
      name,
    });

    res.status(201).json({
      success: true,
      message: "Category added successfully",
      category,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


// GET CATEGORIES (with real product count per category)
const getCategories = async (req, res) => {
  try {
    const categories = await Category.find();

    // Count products per category in one aggregation query
    const productCounts = await Product.aggregate([
      { $group: { _id: "$categoryId", count: { $sum: 1 } } },
    ]);

    // Build a lookup map: categoryId -> count
    const countMap = {};
    productCounts.forEach((item) => {
      if (item._id) countMap[item._id.toString()] = item.count;
    });

    // Attach productCount to each category
    const categoriesWithCount = categories.map((cat) => ({
      ...cat.toObject(),
      productCount: countMap[cat._id.toString()] || 0,
    }));

    res.status(200).json({
      success: true,
      categories: categoriesWithCount,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};


module.exports = {
  addCategory,
  getCategories,
};