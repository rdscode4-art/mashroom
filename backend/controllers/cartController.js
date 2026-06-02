const Cart = require("../models/Cart");
const Product = require("../models/Product");

// GET USER'S CURRENT CART
const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ userId: req.user.id })
      .populate("vendorId", "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen")
      .populate("products.productId", "productName images sellingPrice mrpPrice unit weight stock isAvailable");

    if (!cart) {
      return res.status(200).json({
        success: true,
        cart: null,
        message: "Cart is empty",
      });
    }

    res.status(200).json({
      success: true,
      cart,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// ADD ITEM TO CART (with single-vendor lock)
const addToCart = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const userId = req.user.id;

    if (!productId) {
      return res.status(400).json({
        success: false,
        message: "productId is required",
      });
    }

    const qty = parseInt(quantity) || 1;

    // 1. Get the product to find its vendor
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    if (!product.isAvailable) {
      return res.status(400).json({
        success: false,
        message: "Product is currently unavailable",
      });
    }

    // 2. Check if user already has a cart
    let cart = await Cart.findOne({ userId });

    if (!cart) {
      // CASE 1: No cart exists → create new cart with this vendor
      cart = await Cart.create({
        userId,
        vendorId: product.vendorId,
        products: [
          {
            productId: product._id,
            quantity: qty,
            price: product.sellingPrice || product.mrpPrice,
          },
        ],
      });

      // Recalculate total
      cart.totalPrice = cart.products.reduce(
        (sum, item) => sum + item.price * item.quantity,
        0
      );
      await cart.save();

      // Populate and return
      await cart.populate(
        "vendorId",
        "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen"
      );
      await cart.populate(
        "products.productId",
        "productName images sellingPrice mrpPrice unit weight stock isAvailable"
      );

      return res.status(201).json({
        success: true,
        message: "Item added to cart",
        cart,
      });
    }

    // CASE 3: Cart exists but DIFFERENT vendor → conflict!
    if (cart.vendorId.toString() !== product.vendorId.toString()) {
      return res.status(409).json({
        success: false,
        conflict: true,
        message:
          "Your cart has items from another store. Do you want to replace your cart?",
        currentVendorId: cart.vendorId,
        newVendorId: product.vendorId,
      });
    }

    // CASE 2: Same vendor → add or increment
    const existingItemIndex = cart.products.findIndex(
      (p) => p.productId.toString() === productId
    );

    if (existingItemIndex >= 0) {
      cart.products[existingItemIndex].quantity += qty;
    } else {
      cart.products.push({
        productId: product._id,
        quantity: qty,
        price: product.sellingPrice || product.mrpPrice,
      });
    }

    // Recalculate total
    cart.totalPrice = cart.products.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    await cart.save();

    await cart.populate(
      "vendorId",
      "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen"
    );
    await cart.populate(
      "products.productId",
      "productName images sellingPrice mrpPrice unit weight stock isAvailable"
    );

    res.status(200).json({
      success: true,
      message: "Item added to cart",
      cart,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// REPLACE CART (user confirmed vendor switch)
const replaceCart = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const userId = req.user.id;

    const qty = parseInt(quantity) || 1;

    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    // Delete old cart and create new one with new vendor
    await Cart.deleteOne({ userId });

    const cart = await Cart.create({
      userId,
      vendorId: product.vendorId,
      products: [
        {
          productId: product._id,
          quantity: qty,
          price: product.sellingPrice || product.mrpPrice,
        },
      ],
      totalPrice: (product.sellingPrice || product.mrpPrice) * qty,
    });

    await cart.populate(
      "vendorId",
      "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen"
    );
    await cart.populate(
      "products.productId",
      "productName images sellingPrice mrpPrice unit weight stock isAvailable"
    );

    res.status(200).json({
      success: true,
      message: "Cart replaced with new store items",
      cart,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// UPDATE ITEM QUANTITY IN CART
const updateCartItem = async (req, res) => {
  try {
    const { productId, quantity } = req.body;
    const userId = req.user.id;

    const qty = parseInt(quantity);

    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found",
      });
    }

    const itemIndex = cart.products.findIndex(
      (p) => p.productId.toString() === productId
    );

    if (itemIndex < 0) {
      return res.status(404).json({
        success: false,
        message: "Item not found in cart",
      });
    }

    if (qty <= 0) {
      // Remove item if quantity is 0 or less
      cart.products.splice(itemIndex, 1);

      // If cart is now empty, delete it
      if (cart.products.length === 0) {
        await Cart.deleteOne({ _id: cart._id });
        return res.status(200).json({
          success: true,
          message: "Cart is now empty",
          cart: null,
        });
      }
    } else {
      cart.products[itemIndex].quantity = qty;
    }

    // Recalculate total
    cart.totalPrice = cart.products.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    await cart.save();

    await cart.populate(
      "vendorId",
      "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen"
    );
    await cart.populate(
      "products.productId",
      "productName images sellingPrice mrpPrice unit weight stock isAvailable"
    );

    res.status(200).json({
      success: true,
      message: "Cart updated",
      cart,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// REMOVE SINGLE ITEM FROM CART
const removeCartItem = async (req, res) => {
  try {
    const { productId } = req.params;
    const userId = req.user.id;

    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(404).json({
        success: false,
        message: "Cart not found",
      });
    }

    cart.products = cart.products.filter(
      (p) => p.productId.toString() !== productId
    );

    // If cart is now empty, delete it
    if (cart.products.length === 0) {
      await Cart.deleteOne({ _id: cart._id });
      return res.status(200).json({
        success: true,
        message: "Cart is now empty",
        cart: null,
      });
    }

    // Recalculate total
    cart.totalPrice = cart.products.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    await cart.save();

    await cart.populate(
      "vendorId",
      "shopName shopImage deliveryTime deliveryCharge minimumOrder isOpen"
    );
    await cart.populate(
      "products.productId",
      "productName images sellingPrice mrpPrice unit weight stock isAvailable"
    );

    res.status(200).json({
      success: true,
      message: "Item removed from cart",
      cart,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// CLEAR ENTIRE CART
const clearCart = async (req, res) => {
  try {
    await Cart.deleteOne({ userId: req.user.id });

    res.status(200).json({
      success: true,
      message: "Cart cleared",
      cart: null,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  getCart,
  addToCart,
  replaceCart,
  updateCartItem,
  removeCartItem,
  clearCart,
};
