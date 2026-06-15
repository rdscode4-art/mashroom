# Order Handling Report — RiFresh Delivery System

**Project:** RiFresh (mushroom-root)  
**Date:** June 9, 2026  
**Scope:** Backend (Node.js/Express/MongoDB) + Driver App (Flutter/GetX)

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Order Data Model](#2-order-data-model)
3. [Delivery Partner Data Model](#3-delivery-partner-data-model)
4. [Backend — Order Placement](#4-backend--order-placement)
5. [Backend — Delivery Partner Lifecycle](#5-backend--delivery-partner-lifecycle)
6. [Backend — Order Discovery Algorithm](#6-backend--order-discovery-algorithm)
7. [Backend — Notification Service](#7-backend--notification-service)
8. [Backend — API Routes Summary](#8-backend--api-routes-summary)
9. [Driver App — Architecture Overview](#9-driver-app--architecture-overview)
10. [Driver App — Authentication Flow](#10-driver-app--authentication-flow)
11. [Driver App — DeliveryController (State Machine)](#11-driver-app--deliverycontroller-state-machine)
12. [Driver App — Polling Mechanism](#12-driver-app--polling-mechanism)
13. [Driver App — Push Notification Service](#13-driver-app--push-notification-service)
14. [Driver App — Screens and UI Flow](#14-driver-app--screens-and-ui-flow)
15. [Driver App — API Service Layer](#15-driver-app--api-service-layer)
16. [End-to-End Order Flow](#16-end-to-end-order-flow)
17. [Earnings and Wallet](#17-earnings-and-wallet)
18. [Security and Auth](#18-security-and-auth)
19. [Known Issues and Gaps](#19-known-issues-and-gaps)

---

## 1. System Overview

The RiFresh platform is a three-sided marketplace:

| Actor | App | Primary Role |
|-------|-----|-------------|
| Customer | `organic_grow` (Flutter) | Places orders |
| Vendor | Admin Panel (React) | Accepts and packs orders |
| Delivery Partner | `deliveryapp` (Flutter) | Picks up and delivers orders |

The backend is a single Node.js/Express monolith at `https://mushroomback.ridealdigitalseva.com/api`. All three sides communicate with it via REST. Push notifications use Firebase Cloud Messaging (FCM) via the Firebase Admin SDK.

Order status flows in one direction through a fixed enum:

```
pending → accepted → packed → ready_for_pickup → out_for_delivery → delivered
                                                                   → cancelled
```

The driver app is only involved from `ready_for_pickup` onward (and also shows orders in `accepted` and `packed` states to allow early assignment).

---

## 2. Order Data Model

**File:** `backend/models/Order.js`

```
Order {
  customerId        → ref: User
  vendorId          → ref: Vendor
  deliveryPartnerId → ref: DeliveryPartner  (null until a driver accepts)

  products[]        → [{ productId, quantity, price }]

  totalAmount       Number
  deliveryCharge    Number   (from Settings.deliveryCharge, default ₹30)
  tax               Number   (totalAmount × Settings.taxPercent / 100, default 5%)

  paymentMethod     "cod" | "online"
  paymentStatus     "pending" | "paid"

  orderStatus       "pending" | "accepted" | "packed" |
                    "ready_for_pickup" | "out_for_delivery" |
                    "delivered" | "cancelled"

  pickupOTP         String   (4-digit, vendor → driver handoff)
  orderOTP          String   (4-digit, driver → customer handoff)

  deliveryAddress   { fullAddress, city, state, pincode, landmark, latitude, longitude }

  driverEarning     Number   (calculated at delivery: baseFare + distance × perKmRate)
  deliveryDistance  Number   (km, Haversine from vendor to customer)

  couponCode        String
  couponDiscount    Number

  razorpayOrderId   String
  razorpayPaymentId String

  timestamps: createdAt, updatedAt
}
```

**Key design decisions:**
- Both OTPs are generated at order placement time, not when status changes. This means `pickupOTP` is always available when a driver finds the order.
- `deliveryPartnerId` being `null` is the primary concurrency guard — only one driver can claim an order via the atomic accept endpoint.
- Earnings are calculated at delivery time (not at accept time) using live settings values.

---

## 3. Delivery Partner Data Model

**File:** `backend/models/DeliveryPartner.js`

```
DeliveryPartner {
  userId            → ref: User
  name, phone, email
  vehicleType       "bike" | "scooter" | "cycle" | "other"
  vehicleNumber     String
  profileImage      String (file path)

  isOnline          Boolean  (driver toggled)
  isAvailable       Boolean  (true = no active order, false = busy with delivery)
  currentLocation   { latitude, longitude }
  activeOrderId     → ref: Order (null when free)

  totalDeliveries   Number   (lifetime count)
  earnings          Number   (current wallet balance in ₹)

  kyc {
    aadharNumber, aadharFront, aadharBack,
    dlNumber, dlImage
  }
  kycStatus         "pending" | "submitted" | "approved" | "rejected"
  kycRejectionReason String
  isApproved        Boolean  (set by admin)
}
```

**Key flags:**
- `isOnline` — controlled by the driver. Going offline stops order assignments.
- `isAvailable` — controlled by the system. Set to `false` when a driver accepts an order; back to `true` on delivery completion.
- `isApproved` — controlled by admin. A partner cannot go online or accept orders until this is `true`.

---

## 4. Backend — Order Placement

**File:** `backend/controllers/orderController.js`  
**Route:** `POST /api/orders/place` (protected)

### Step-by-step flow

**1. Cart validation**  
Fetches the cart for `req.user.id`. Returns 400 if empty.

**2. Delivery address resolution**  
Checks `req.body.deliveryAddress.fullAddress`. If provided, uses it directly. Otherwise falls back to the user's saved profile address. Returns 400 if neither exists.

**3. Address persistence**  
Upserts the resolved address into the `Address` collection (keyed by `userId + fullAddress`), including optional `houseNo`, `floor`, `building`, `area` fields from the body.

**4. Dynamic charges**  
Reads `deliveryCharge` and `taxPercent` from `Settings` (defaults: ₹30 and 5%). Creates a default Settings document if none exists.

**5. Totals calculation**

```
tax = round(cart.totalPrice × taxPercent / 100, 2)
totalAmount = cart.totalPrice + deliveryCharge + tax
```

**6. Coupon validation**  
If `couponCode` is provided:
- Looks up by code (case-insensitive)
- Validates expiry and minimum order value
- Calculates discount (percentage or flat), capped at `cart.totalPrice`
- Subtracts from `totalAmount` (floored at 0)

**7. OTP generation**  
Both `pickupOTP` and `orderOTP` are generated as `Math.floor(1000 + Math.random() * 9000).toString()` — 4-digit strings.

**8. Order creation**

```js
Order.create({
  customerId, vendorId,
  products, totalAmount, deliveryCharge, tax,
  paymentMethod, paymentStatus,   // "paid" if online+razorpayPaymentId present
  orderStatus: "pending",
  deliveryAddress, pickupOTP, orderOTP,
  couponCode, couponDiscount,
  razorpayOrderId, razorpayPaymentId,
})
```

**9. Cart cleared**  
`Cart.deleteOne({ _id: cart._id })`

**10. Vendor push notification**  
Looks up `User.findById(cart.vendorId)` for `fcmToken`. Sends:
- Title: `"New Order Received! 🛍️"`
- Body: `"You have received a new order. Please pack it soon."`
- Data: `{ type: "new_order_vendor", orderId }`

Failures are caught and logged — they do not roll back the order.

---

## 5. Backend — Delivery Partner Lifecycle

**File:** `backend/controllers/deliveryController.js`

### 5.1 Registration and KYC

| Endpoint | Action |
|----------|--------|
| `POST /delivery/register` | Creates `DeliveryPartner` document; upgrades `User.role` to `"delivery"` |
| `POST /delivery/kyc` | Attaches uploaded document paths; sets `kycStatus = "submitted"` |

Admin must approve KYC via admin panel (`isApproved = true`) before the partner can go online.

### 5.2 Toggle Online (`PUT /delivery/toggle-online`)

```js
if (!partner.isApproved) return 403
partner.isOnline = !partner.isOnline
if (!partner.isOnline) partner.isAvailable = true  // reset when going offline
await partner.save()
```

Going offline also resets availability so the partner starts fresh next time.

### 5.3 Location Update (`PUT /delivery/location`)

```js
DeliveryPartner.findOneAndUpdate(
  { userId },
  { currentLocation: { latitude, longitude } }
)
```

Called by the driver app on startup (when going online) via `_updateLocationLoop()`.

### 5.4 Get Assigned Order (`GET /delivery/order/assigned`)

This is the core polling endpoint. Logic:

```
if partner.activeOrderId exists:
    fetch that order
    if order is delivered/cancelled:
        clear activeOrderId, isAvailable = true
        fall through to findAvailablePickupOrder
    else:
        return order

else:
    return findAvailablePickupOrder(partner)
```

### 5.5 Accept Order (`PUT /delivery/order/:orderId/accept`)

Pre-conditions checked:
- `partner.isApproved` must be true
- `partner.isOnline` must be true
- `partner.isAvailable` must be true

Atomic claim using `findOneAndUpdate`:
```js
Order.findOneAndUpdate(
  {
    _id: orderId,
    orderStatus: { $in: ["ready_for_pickup", "packed", "accepted"] },
    deliveryPartnerId: null,  ← race condition guard
  },
  { deliveryPartnerId: partner._id },
  { new: true }
)
```

If another driver claimed it first, this returns `null` → 409 Conflict response.

On success:
```js
partner.isAvailable = false
partner.activeOrderId = order._id
await partner.save()
```

### 5.6 Confirm Pickup (`PUT /delivery/order/:orderId/pickup`)

- Verifies `order.deliveryPartnerId === partner._id`
- Generates `pickupOTP` if somehow missing
- Validates submitted OTP against `order.pickupOTP`
- Sets `order.orderStatus = "out_for_delivery"`
- Sends FCM push to customer:
  - Title: `"Order Out for Delivery! 🚴"`
  - Body: `"Your order has been picked up and is on its way to you."`
  - Data: `{ type: "order_update", orderId }`

### 5.7 Mark Delivered (`PUT /delivery/order/:orderId/deliver`)

- Requires `order.orderStatus === "out_for_delivery"`
- Validates submitted OTP against `order.orderOTP`

**Distance calculation (Haversine formula):**
```js
const deg2rad = (d) => d * (Math.PI / 180)
const distanceKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371
  const dLat = deg2rad(lat2 - lat1)
  const dLon = deg2rad(lon2 - lon1)
  const a = sin(dLat/2)² + cos(lat1)·cos(lat2)·sin(dLon/2)²
  return R * 2 * atan2(√a, √(1-a))
}
```

Uses vendor location (`vendorId.address.location`) to customer location (`deliveryAddress`). Distance is 0 if either side has zero/missing coordinates.

**Earnings calculation:**
```js
calculatedEarning = baseFare + distance × perKmRate
// baseFare default: ₹25
// perKmRate default: ₹5/km
// Both from Settings document
```

**Final updates:**
```js
order.orderStatus = "delivered"
order.paymentStatus = "paid"    // only if paymentMethod === "cod"
order.driverEarning = calculatedEarning
order.deliveryDistance = distance

Vendor.findByIdAndUpdate(vendorId, { $inc: { totalEarnings: order.totalAmount, totalOrders: 1 } })

partner.totalDeliveries += 1
partner.earnings += calculatedEarning
partner.isAvailable = true
partner.activeOrderId = null

DriverTransaction.create({ type: "earning", amount: calculatedEarning, orderId })

sendPushNotification(customer.fcmToken,
  "Order Delivered! ✅",
  "Your order has been successfully delivered. Enjoy!",
  { type: "order_update", orderId }
)
```

---

## 6. Backend — Order Discovery Algorithm

**Function:** `findAvailablePickupOrder(partner)` in `deliveryController.js`

```
1. Guard: isApproved && isOnline && isAvailable → else return null

2. Read deliveryPartnerRadius from Settings (default: 2 km)

3. Query orders:
   - orderStatus IN ["ready_for_pickup", "packed", "accepted"]
   - deliveryPartnerId: null
   - Populated: customerId (name, phone), vendorId (shopName, phone, address),
                products.productId (productName, images, unit)
   - Sorted: createdAt ASC (FIFO)
   - Limit: 20

4. For each order:
   a. Get vendor location (vendorId.address.location)
   b. Get partner location (currentLocation)
   c. If both have valid non-zero coordinates:
        calculate Haversine distance
        if distance > radius → skip
   d. If either side lacks coordinates → do NOT skip
      (local dev / missing GPS fallback)
   e. Ensure pickupOTP exists (generates one if missing for accepted/packed orders)
   f. Return first matching order

5. Return null if none found
```

**Design notes:**
- The radius fallback (skipping distance check when coordinates are missing) is a deliberate local-dev convenience. In production, all vendors and partners are expected to have GPS coordinates saved.
- FIFO ordering ensures older orders are assigned first.
- The 20-order limit prevents unbounded database scans on large datasets.

---

## 7. Backend — Notification Service

**File:** `backend/services/notificationService.js`

Uses Firebase Admin SDK with `sendEachForMulticast` for batched delivery.

```js
const message = {
  notification: { title, body },
  data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
  android: {
    priority: 'high',
    notification: { sound: 'default', ...androidConfig }
  },
  apns: {
    payload: { aps: {
      sound: androidConfig.sound === 'order_sound' ? 'order_sound.aiff' : 'default',
      contentAvailable: true
    }}
  },
  tokens: validTokens
}
```

**Notification triggers:**

| Event | Recipient | Title | Type payload |
|-------|-----------|-------|-------------|
| Order placed | Vendor | "New Order Received! 🛍️" | `new_order_vendor` |
| Pickup confirmed | Customer | "Order Out for Delivery! 🚴" | `order_update` |
| Delivered | Customer | "Order Delivered! ✅" | `order_update` |

**Note:** There is no push notification sent to the driver when a new order becomes available. The driver app discovers orders via **polling** only.

---

## 8. Backend — API Routes Summary

### Order Routes (`/api/orders`)
| Method | Path | Auth | Handler |
|--------|------|------|---------|
| POST | `/place` | JWT | `placeOrder` |

### Delivery Routes (`/api/delivery`)
| Method | Path | Auth | Handler |
|--------|------|------|---------|
| POST | `/register` | JWT | `registerPartner` |
| POST | `/kyc` | JWT | `submitKyc` |
| GET | `/profile` | JWT | `getProfile` |
| PUT | `/profile` | JWT | `updateProfile` |
| GET | `/dashboard` | JWT | `getDashboard` |
| PUT | `/toggle-online` | JWT | `toggleOnline` |
| PUT | `/location` | JWT | `updateLocation` |
| GET | `/order/assigned` | JWT | `getAssignedOrder` |
| GET | `/orders/history` | JWT | `getOrderHistory` |
| PUT | `/order/:orderId/accept` | JWT | `acceptPickup` |
| PUT | `/order/:orderId/pickup` | JWT | `confirmPickup` |
| PUT | `/order/:orderId/deliver` | JWT | `markDelivered` |
| GET | `/wallet/history` | JWT | `getWalletHistory` |
| POST | `/wallet/withdraw` | JWT | `requestWithdrawal` |

All routes are protected by the `protect` middleware (JWT Bearer token verification).

---

## 9. Driver App — Architecture Overview

**Framework:** Flutter with GetX for state management, routing, and dependency injection.  
**HTTP Client:** Dio with Bearer token interceptor.  
**Auth:** OTP-based phone authentication; JWT stored in `SharedPreferences`.  
**Base URL:** `https://mushroomback.ridealdigitalseva.com/api`

```
deliveryapp/lib/
├── main.dart                          ← app entry, Firebase init, routes, _HomeWrapper
├── core/
│   ├── constants/app_constants.dart  ← baseUrl, tokenKey
│   ├── controllers/
│   │   ├── auth_controller.dart      ← login, OTP, profile, FCM sync
│   │   ├── delivery_controller.dart  ← order state machine + polling
│   │   └── wallet_controller.dart    ← balance, transactions, withdrawal
│   ├── models/
│   │   ├── order_model.dart          ← DeliveryOrder, OrderItem
│   │   └── partner_model.dart        ← DeliveryPartner
│   ├── services/api_service.dart     ← all HTTP calls
│   └── theme/app_theme.dart
├── services/
│   └── push_notification_service.dart ← FCM + local notifications
└── views/
    ├── home_screen.dart               ← main dashboard
    ├── incoming_order_screen.dart     ← full-screen order alert
    ├── history_screen.dart
    ├── wallet_screen.dart
    ├── login_screen.dart
    ├── register_partner_screen.dart
    ├── profile_screen.dart
    └── edit_profile_screen.dart
```

---

## 10. Driver App — Authentication Flow

**File:** `core/controllers/auth_controller.dart`

```
App launch
  → AuthController.onInit()
  → ApiService.loadToken() (SharedPreferences)
  → if token exists:
      GET /delivery/profile
      if partner exists and isApproved → navigate /home
      if partner exists but not approved → navigate /register-partner
      if no partner profile → navigate /register-partner
  → if no token:
      stay on /splash → redirect /login after 2s

Login (OTP)
  → POST /auth/send-otp { phone }
  → POST /auth/verify-otp { phone, otp }
  → saves JWT token to SharedPreferences
  → calls PushNotificationService.syncToken() to register FCM token
  → checks profile → routes accordingly
```

---

## 11. Driver App — DeliveryController (State Machine)

**File:** `core/controllers/delivery_controller.dart`

This is the central controller for order management. It uses GetX reactive state (`Rx`, `Rxn`).

### Reactive State

| Observable | Type | Meaning |
|-----------|------|---------|
| `isOnline` | `RxBool` | Driver online/offline toggle |
| `isAvailable` | `RxBool` | No active order assigned |
| `assignedOrder` | `Rxn<DeliveryOrder>` | Current order (null = none) |
| `orderHistory` | `RxList<DeliveryOrder>` | Completed deliveries |
| `isLoading` | `RxBool` | API call in progress |
| `declinedOrderIds` | `RxSet<String>` | Orders declined this session |
| `totalDeliveries` | `RxInt` | Lifetime count |
| `totalEarnings` | `RxDouble` | From dashboard stats |
| `todayDeliveries` | `RxInt` | Today's count |

### Actions

**`toggleOnline()`**
```
PUT /delivery/toggle-online
if going online:
    updateLocation (GPS)
    fetchAssignedOrder
    startPolling (5s interval)
    show green snackbar
if going offline:
    stopPolling
    assignedOrder = null
    declinedOrderIds.clear()
    show grey snackbar
```

**`acceptOrder(orderId)`**
```
PUT /delivery/order/:id/accept
on success:
    isAvailable = false
    assignedOrder = response.order
    show green snackbar "Head to vendor"
on 409/failure:
    assignedOrder = null
    show orange snackbar "Order taken"
```

**`confirmPickup(orderId, otp)`**
```
PUT /delivery/order/:id/pickup  body: { otp }
on success:
    assignedOrder = response.order  (now status: out_for_delivery)
    show blue snackbar "Head to customer"
on error:
    show red snackbar with error message (e.g. "Invalid pickup OTP")
```

**`markDelivered(orderId, otp)`**
```
PUT /delivery/order/:id/deliver  body: { otp }
on success:
    assignedOrder = null
    isAvailable = true
    totalDeliveries++
    todayDeliveries++
    _loadDashboard() (refreshes earnings)
    show green snackbar "Great job!"
on error:
    show red snackbar with error message (e.g. "Invalid delivery OTP")
```

---

## 12. Driver App — Polling Mechanism

**File:** `core/controllers/delivery_controller.dart`

The driver app does **not** use WebSockets or Firebase Realtime Database for order discovery. It polls the backend every 5 seconds.

```dart
Timer.periodic(const Duration(seconds: 5), (_) async {
  if (!isOnline.value) { _pollTimer?.cancel(); return; }
  await fetchAssignedOrder();
});
```

`fetchAssignedOrder()` calls `GET /delivery/order/assigned` and updates `assignedOrder`.

**Order detection in `_HomeWrapper` (`main.dart`):**

```dart
ever(dc.assignedOrder, (order) {
  if (order == null) { _lastSeenOrderId = null; return; }
  if (order.id != _lastSeenOrderId &&           // new order
      !dc.declinedOrderIds.contains(order.id) && // not declined
      ['accepted', 'packed', 'ready_for_pickup'].contains(order.orderStatus) &&
      dc.isAvailable.value) {                     // not already busy
    _lastSeenOrderId = order.id;
    // Navigate to IncomingOrderScreen after 300ms delay
    Get.toNamed('/incoming-order', arguments: order)
  }
});
```

**App lifecycle awareness:**  
`_HomeWrapper` implements `WidgetsBindingObserver`. On `AppLifecycleState.resumed`:
```dart
PushNotificationService.cancelAllNotifications();
Get.find<DeliveryController>().fetchAssignedOrder();
```

This ensures the app syncs immediately when the driver returns from the background.

---

## 13. Driver App — Push Notification Service

**File:** `services/push_notification_service.dart`

### Initialization

```
Firebase.initializeApp()
→ PushNotificationService.init()
  → requestPermission (alert, badge, sound, criticalAlert)
  → setup background message handler
  → init FlutterLocalNotificationsPlugin
  → create Android notification channel "order_channel"
     (sound: order_sound, importance: max, fullScreenIntent: true)
  → listen to foreground messages
  → get FCM token → sendTokenToBackend (PUT /auth/fcm-token)
  → listen for token refresh → re-sync
```

### Android Notification Channel

```dart
AndroidNotificationChannel(
  id: 'order_channel',
  name: 'New Orders',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('order_sound'),
  playSound: true,
  enableVibration: true,
)
```

### Foreground Message Handling

```dart
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['type'] == 'new_order') {
    // Skip local notification — polling + IncomingOrderScreen handles it
  } else {
    _showLocalNotification(message)  // e.g. order_update notifications
  }
})
```

`new_order` type notifications are intentionally suppressed when the app is in the foreground, since the 5-second polling loop + `IncomingOrderScreen` overlay provides a richer UX.

### Background / Tapped Notification

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  cancelAllNotifications();
  // Wait 200ms for GetX to be ready
  Get.find<DeliveryController>().fetchAssignedOrder();
})
```

### Sound File

Custom alert sound: `order_sound.mp3` (Android) / `order_sound.aiff` (iOS).  
Used both in local notifications (`RawResourceAndroidNotificationSound`) and in `IncomingOrderScreen` via `audioplayers` (`AudioPlayer().play(AssetSource('order_sound.mp3'))`).

---

## 14. Driver App — Screens and UI Flow

### 14.1 Splash Screen (`/splash`)

Displays logo and loading indicator for 2 seconds. `AuthController.onInit` handles the actual routing before the fallback kicks in.

### 14.2 Home Screen (`/home`)

The core operational screen. Divided into:

**Online Toggle Card**  
Animated gradient card (green when online, dark when offline). Tapping calls `dc.toggleOnline()`.

**Stats Row**  
Three cards: Today's Deliveries, Total Deliveries, Earnings (tappable → Wallet).

**Order Area (reactive)**  
Driven by `Obx(() => dc.assignedOrder.value)`:

| State | Component | Description |
|-------|-----------|-------------|
| Offline | `_OfflineCard` | "You are offline" message |
| Online, no order | `_WaitingCard` | "Waiting for orders..." |
| Order available, `isAvailable=true` | `_AvailableOrderCard` | Shows vendor/customer info, Accept button |
| Order accepted, `isAvailable=false` | `_ActiveOrderCard` | Full order details with navigation and OTP dialogs |

**`_ActiveOrderCard` — Step Indicator:**
```
[Accept ✓] ——— [Pickup (pending)] ——— [Deliver]
```

**Action buttons in `_ActiveOrderCard`:**

*Before pickup (status: accepted/packed/ready_for_pickup):*
- "Navigate to Store" → opens Google Maps deep link to vendor coordinates
- "I've Picked Up the Order" → shows Pickup OTP dialog

*Out for delivery:*
- "Navigate to Customer" → opens Google Maps deep link to customer coordinates
- "Mark as Delivered" → shows Delivery OTP dialog

**OTP Dialogs:**  
Both dialogs use a 4-character numeric `TextField` (large font, letter-spacing for readability). Submit calls `dc.confirmPickup()` or `dc.markDelivered()` respectively.

### 14.3 Incoming Order Screen (`/incoming-order`)

Full-screen overlay triggered by `_HomeWrapper`'s `ever()` watcher.

- **Countdown:** 30 seconds with animated `LinearProgressIndicator` (green → orange → red)
- **Audio:** `order_sound.mp3` loops via `audioplayers` until screen is dismissed
- **Order summary card:** shortId, vendor info, customer info, item count, total, payment method
- **Earning preview:** Shows `deliveryCharge` as potential earning
- **Accept button:** Calls `dc.acceptOrder()`, pops screen. Sound stops on dispose.
- **Decline button:** Adds `order.id` to `declinedOrderIds`, pops screen. The same order won't trigger the alert again this session.
- **Auto-dismiss:** If countdown reaches 0, pops automatically (equivalent to decline).

### 14.4 History Screen (`/history`)

Lists all completed deliveries via `dc.loadHistory()` → `GET /delivery/orders/history`.  
Each row shows: shortId, vendor name, date, distance (km), and `driverEarning`.

### 14.5 Wallet Screen (`/wallet`)

- Balance card with lifetime earnings and Withdraw button (disabled below ₹100)
- Transaction history (earning entries with `+₹`, withdrawal entries with `-₹` and status badge)
- Withdrawal bottom sheet with two tabs: UPI ID and Bank Transfer
  - UPI: validates `name@upi` format
  - Bank: validates holder name, bank name, account number (9–18 digits), IFSC (regex `^[A-Z]{4}0[A-Z0-9]{6}$`)

---

## 15. Driver App — API Service Layer

**File:** `core/services/api_service.dart`

Dio instance with:
- `baseUrl = AppConstants.baseUrl`
- 15s connect + receive timeouts
- `Authorization: Bearer <token>` injected via request interceptor
- Token loaded from `SharedPreferences` on init, saved on login

**Order-related methods:**

| Method | HTTP | Endpoint | Notes |
|--------|------|----------|-------|
| `getAssignedOrder()` | GET | `/delivery/order/assigned` | Polled every 5s |
| `acceptOrder(orderId)` | PUT | `/delivery/order/:id/accept` | Returns error map on DioException |
| `confirmPickup(orderId, otp)` | PUT | `/delivery/order/:id/pickup` | Throws on DioException |
| `markDelivered(orderId, otp)` | PUT | `/delivery/order/:id/deliver` | Throws on DioException |
| `getOrderHistory()` | GET | `/delivery/orders/history` | |
| `getDashboard()` | GET | `/delivery/dashboard` | Stats + partner state |
| `toggleOnline()` | PUT | `/delivery/toggle-online` | |
| `updateLocation(lat, lng)` | PUT | `/delivery/location` | |

**Error handling difference:** `acceptOrder` returns the error response as a `Map` (enabling the "order taken" UX), while `confirmPickup` and `markDelivered` throw exceptions (relying on GetX snackbars for display).

---

## 16. End-to-End Order Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ CUSTOMER (organic_grow app)                                     │
│                                                                 │
│  Adds items to cart → selects address → applies coupon         │
│  → POST /orders/place                                           │
│       ↳ Order created (status: pending)                         │
│       ↳ pickupOTP + orderOTP generated                          │
│       ↳ FCM push → Vendor: "New Order Received! 🛍️"             │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│ VENDOR (admin panel)                                            │
│                                                                 │
│  Receives notification → reviews order                          │
│  → Accepts order    (status: accepted)                          │
│  → Packs order      (status: packed)                            │
│  → Marks ready      (status: ready_for_pickup)                  │
│  → Shows pickupOTP to driver when they arrive                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│ DRIVER (deliveryapp)                                            │
│                                                                 │
│  Goes online → location updated → polling starts (5s)          │
│                                                                 │
│  Poll: GET /delivery/order/assigned                             │
│       ↳ findAvailablePickupOrder()                              │
│         - finds orders: accepted/packed/ready_for_pickup        │
│         - within radius (default 2 km)                          │
│         - unassigned (deliveryPartnerId: null)                  │
│         - FIFO ordered                                          │
│                                                                 │
│  New order detected → IncomingOrderScreen shown                 │
│       ↳ Countdown timer (30s)                                   │
│       ↳ Alert sound (order_sound.mp3) loops                     │
│       ↳ Order summary displayed                                 │
│                                                                 │
│  Driver ACCEPTS → PUT /delivery/order/:id/accept               │
│       ↳ Atomic claim (deliveryPartnerId: null guard)            │
│       ↳ partner.isAvailable = false                             │
│       ↳ partner.activeOrderId = order._id                       │
│       ↳ HomeScreen shows _ActiveOrderCard                       │
│                                                                 │
│  Driver navigates to vendor (Google Maps deep link)             │
│  Vendor shows pickupOTP → Driver enters it                      │
│  → PUT /delivery/order/:id/pickup  body: { otp }               │
│       ↳ pickupOTP validated                                     │
│       ↳ status: out_for_delivery                                │
│       ↳ FCM push → Customer: "Order Out for Delivery! 🚴"       │
│                                                                 │
│  Driver navigates to customer (Google Maps deep link)           │
│  Customer shows orderOTP → Driver enters it                     │
│  → PUT /delivery/order/:id/deliver  body: { otp }              │
│       ↳ orderOTP validated                                      │
│       ↳ distance calculated (Haversine)                         │
│       ↳ driverEarning = baseFare + distance × perKmRate         │
│       ↳ status: delivered                                       │
│       ↳ COD: paymentStatus = "paid"                             │
│       ↳ vendor.totalEarnings += order.totalAmount               │
│       ↳ partner.earnings += driverEarning                       │
│       ↳ DriverTransaction created (type: earning)               │
│       ↳ partner.isAvailable = true, activeOrderId = null        │
│       ↳ FCM push → Customer: "Order Delivered! ✅"               │
│       ↳ Dashboard refreshed, polling continues                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 17. Earnings and Wallet

### Earning Calculation

At the time of `markDelivered`:

```
earning = baseFare + (distance_km × perKmRate)
```

Values come from `Settings`:
- `deliveryBaseFare` (default ₹25)
- `deliveryPerKmRate` (default ₹5/km)

Distance is the straight-line (Haversine) distance from vendor to customer delivery address. If either location is missing/zero, distance = 0 and earning = baseFare only.

### Wallet Balance

`DeliveryPartner.earnings` is the live wallet balance. It is:
- **Incremented** on each delivery by `driverEarning`
- **Decremented** immediately when a withdrawal is requested (optimistic deduction)
- Restored partially if the admin **rejects** the withdrawal request

### Withdrawal

Minimum: ₹100  
Methods: UPI ID or Bank Transfer (holder name, account number, bank name, IFSC)

Flow:
```
POST /delivery/wallet/withdraw
  ↳ validate amount, method, details
  ↳ partner.earnings -= amount  (immediate deduction)
  ↳ WithdrawalRequest.create({ status: "pending" })
  ↳ DriverTransaction.create({ type: "withdrawal", amount: -amount })
```

Admin approves or rejects via admin panel (not covered in this report).

### Transaction History

`GET /delivery/wallet/history` returns all `DriverTransaction` records for the partner, with `withdrawalId` populated (to show withdrawal status in the UI).

---

## 18. Security and Auth

### JWT Authentication

**File:** `backend/middleware/authMiddleware.js`

All order and delivery endpoints use the `protect` middleware:

```js
const token = req.headers.authorization.split(" ")[1]  // "Bearer <token>"
const decoded = jwt.verify(token, process.env.JWT_SECRET)
req.user = await User.findById(decoded.id).select("-otp -otpExpiry")
```

OTP fields are always stripped from the populated user object.

### Race Condition Protection (Order Acceptance)

The accept endpoint uses a MongoDB atomic `findOneAndUpdate` with `deliveryPartnerId: null` as a filter:

```js
Order.findOneAndUpdate(
  { _id: orderId, orderStatus: { $in: [...] }, deliveryPartnerId: null },
  { deliveryPartnerId: partner._id }
)
```

If two drivers tap "Accept" simultaneously, only one will find `deliveryPartnerId: null` and succeed. The other gets a `null` result → 409 response → "Too Late!" snackbar in the app.

### OTP Verification

- `pickupOTP` — prevents drivers from falsely claiming pickup without physically visiting the vendor
- `orderOTP` — prevents drivers from falsely claiming delivery without reaching the customer
- Both are 4-digit numeric strings. There is no expiry or rate limiting on OTP attempts.

### KYC Gate

A delivery partner cannot go online or accept orders unless `isApproved === true`. This is set by an admin after KYC review. The toggle-online endpoint enforces this check server-side regardless of client state.

---

## 19. Known Issues and Gaps

| Issue | Location | Details |
|-------|----------|---------|
| No push notification to driver | Backend | Drivers discover orders only via 5s polling. No FCM is sent to drivers when a new order is ready. This means up to 5s lag for order awareness. |
| OTP brute-force possible | Backend `confirmPickup`, `markDelivered` | No rate limiting or attempt counter on OTP validation. |
| Earnings use zero distance as fallback | Backend `markDelivered` | If vendor or customer has no GPS coordinates saved, `distance = 0` and the driver earns only `baseFare`. |
| Unused import in push service | Driver app `push_notification_service.dart` | `dart:io` imported but not used. |
| `android` variable unused | Driver app `push_notification_service.dart` | `AndroidNotification? android = message.notification?.android` — variable is extracted but never referenced. |
| Production `print` statements | Driver app | Multiple `print()` calls in `push_notification_service.dart` should be replaced with a proper logging framework. |
| No `pickupOTP` exposed to driver | Driver app UI | The incoming order screen shows `deliveryCharge` as "earning", which is the base delivery fee. Actual `driverEarning` is only known after delivery (based on distance). |
| Declined orders are session-only | Driver app | `declinedOrderIds` is an in-memory `RxSet`. Restarting the app clears the declined list, and the same order will pop up again. |
| Withdrawal rejection does not restore balance | Backend | When a `WithdrawalRequest` is rejected by admin, there is no automatic callback to restore `partner.earnings`. This requires a manual admin step or a separate handler. |
