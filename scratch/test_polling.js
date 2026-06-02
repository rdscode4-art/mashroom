const mongoose = require('mongoose');
const DeliveryPartner = require('../backend/models/DeliveryPartner');
const Order = require('../backend/models/Order');
const Settings = require('../backend/models/Settings');
require('dotenv').config({ path: '../backend/.env' });

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  
  const partner = await DeliveryPartner.findOne();
  if (!partner) {
    console.log("No partner found.");
    process.exit(0);
  }

  const orders = await Order.find({
    orderStatus: { $in: ["ready_for_pickup", "packed", "accepted"] },
    deliveryPartnerId: null,
  }).populate("vendorId").populate("customerId");

  console.log("Found orders in DB matching query:", orders.length);
  orders.forEach(o => {
    console.log(`- Order ${o._id} | Status: ${o.orderStatus} | Vendor: ${o.vendorId?.shopName}`);
  });

  const deg2rad = (d) => d * (Math.PI / 180);
  const distanceKm = (lat1, lon1, lat2, lon2) => {
    const R = 6371;
    const dLat = deg2rad(lat2 - lat1);
    const dLon = deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) * Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  };

  const pLat = partner.currentLocation?.latitude;
  const pLng = partner.currentLocation?.longitude;
  const radius = 2;

  console.log(`\nPartner GPS: ${pLat}, ${pLng}`);
  
  for (const order of orders) {
    const vLat = order.vendorId?.address?.location?.latitude;
    const vLng = order.vendorId?.address?.location?.longitude;
    const hasLocations =
      typeof pLat === "number" && typeof pLng === "number" && pLat !== 0 && pLng !== 0 &&
      typeof vLat === "number" && typeof vLng === "number" && vLat !== 0 && vLng !== 0;

    console.log(`Order ${o._id} Vendor GPS: ${vLat}, ${vLng}. hasLocations: ${hasLocations}`);

    if (hasLocations) {
      const dist = distanceKm(pLat, pLng, vLat, vLng);
      console.log(`  Distance: ${dist} km. Radius: ${radius}`);
      if (dist > radius) {
        console.log("  SKIPPED due to distance.");
        continue;
      }
    }
    
    console.log("  => THIS ORDER WILL BE RETURNED!");
    break;
  }

  process.exit(0);
}

test();
