const express = require("express");
const router = express.Router();
const { validateCoupon, getActiveCoupons } = require("../controllers/couponController");

router.get("/", getActiveCoupons);          // public — list all valid coupons
router.post("/validate", validateCoupon);   // public — validate + calculate discount

module.exports = router;
