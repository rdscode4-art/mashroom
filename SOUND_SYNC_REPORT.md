# Sound Sync Report — RiFresh Delivery App

**File:** `deliveryapp` (Flutter)  
**Date:** June 9, 2026  
**Topic:** Notification sound aur In-App sound kaise ek saath kaam karte hain, kab kaun sa band hota hai

---

## Sound Sources — Do Alag Systems
e
Poore app mein sirf **ek hi sound file** hai: `order_sound.mp3` (Android) / `order_sound.aiff` (iOS).
Lekin yeh sound **do alag jagah se** play hoti hai:

| # | Source | Library | Kab play hota hai |
|---|--------|---------|-------------------|
| 1 | **OS Notification Sound** | `flutter_local_notifications` | Jab app background mein ho ya screen off ho |
| 2 | **In-App Audio Player** | `audioplayers` (AudioPlayer) | Jab `IncomingOrderScreen` open ho, app foreground mein ho |

Yeh dono **kabhi saath nahi bajtey** — ek doosre ko cancel karte hain. Yahi synchronization ka core logic hai.

---

## Sound File Configuration

### Android Channel Setup (`push_notification_service.dart`)

```dart
AndroidNotificationChannel(
  'order_channel',
  'New Orders',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('order_sound'),  // ← res/raw/order_sound.mp3
  playSound: true,
  enableVibration: true,
)
```

### iOS Config (backend `notificationService.js`)

```js
apns: {
  payload: { aps: {
    sound: 'order_sound.aiff',   // ← app bundle mein hona chahiye
    contentAvailable: true,
  }}
}
```

### In-App AudioPlayer (`incoming_order_screen.dart`)

```dart
final AudioPlayer _audioPlayer = AudioPlayer();

Future<void> _playAlertSound() async {
  await _audioPlayer.setReleaseMode(ReleaseMode.loop);  // ← loop on hai
  await _audioPlayer.play(AssetSource('order_sound.mp3'));
}
```

---

## Situation-wise Sound Behavior

---

### Situation 1 — App BACKGROUND mein hai, naya order aaya

```
Backend → FCM push (type: "new_order") → OS receive karta hai
                                               ↓
                          OS notification show karta hai
                          order_channel sound bajtaa hai ✅
                          (RawResourceAndroidNotificationSound)
                                               ↓
                          IncomingOrderScreen NAHI khulta
                          AudioPlayer NAHI chalta ❌
```

**Sound status:**
- OS notification sound: **BAJTA HAI** ✅
- AudioPlayer: **NAHI BAJTA** ❌

**Note:** Yeh sirf ek baar bajega (loop nahi). Driver ko notification pe tap karna hoga.

---

### Situation 2 — Driver notification pe TAP karta hai (app background se open hota hai)

```dart
// push_notification_service.dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  cancelAllNotifications();  // ← OS notification band
  Future.delayed(Duration(milliseconds: 200), () {
    Get.find<DeliveryController>().fetchAssignedOrder();  // ← poll trigger
  });
});
```

```
Driver notification tap karta hai
        ↓
cancelAllNotifications() → OS sound STOP ✅
        ↓
200ms baad fetchAssignedOrder() call hoti hai
        ↓
assignedOrder update → ever() trigger in _HomeWrapper
        ↓
IncomingOrderScreen navigate hota hai
        ↓
initState() mein:
  cancelAllNotifications()  ← dobara cancel (safety)
  _playAlertSound()          ← AudioPlayer LOOP shuru ✅
```

**Sound status:**
- OS notification sound: **BAND** ✅ (cancelAllNotifications se)
- AudioPlayer: **SHURU** ✅ (loop mode)

---

### Situation 3 — App FOREGROUND mein hai, naya order aaya (polling se detect hua)

Yeh sabse common case hai. Driver app khula hua hai, 5 second polling chal rahi hai.

```dart
// push_notification_service.dart — foreground message handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  bool isOrder = message.data['type'] == 'new_order';
  if (!isOrder) {
    _showLocalNotification(message);   // doosri notifications show hoti hain
  } else {
    // SKIP — app foreground mein hai
    print('Skipping local notification for new_order...');
  }
});
```

```
Polling (har 5s): GET /delivery/order/assigned
        ↓
Response mein naya order mila
        ↓
dc.assignedOrder.value update hota hai
        ↓
ever() watcher trigger in _HomeWrapper:
  - order.id != _lastSeenOrderId  ✅
  - order not in declinedOrderIds ✅
  - orderStatus in [accepted/packed/ready_for_pickup] ✅
  - dc.isAvailable.value == true ✅
        ↓
300ms delay ke baad IncomingOrderScreen navigate
        ↓
IncomingOrderScreen.initState():
  cancelAllNotifications()    ← koi OS notification nahi thi, but safety se call
  _playAlertSound()            ← AudioPlayer LOOP shuru ✅
```

**Sound status:**
- OS notification sound: **NAHI BAJA** (foreground mein FCM notification suppress ki gayi thi)
- AudioPlayer: **SHURU** ✅ (loop mode, IncomingOrderScreen open hone ke saath)

---

### Situation 4 — Driver IncomingOrderScreen pe **ACCEPT** karta hai

```dart
// incoming_order_screen.dart — Accept button
onPressed: () async {
  Navigator.of(context).pop();   // ← screen BAND hoti hai
  await dc.acceptOrder(order.id);
}
```

```
Accept tap
    ↓
Navigator.pop() → IncomingOrderScreen dispose() call
    ↓
dispose() mein:
  _audioPlayer.stop()     ← AudioPlayer BAND ✅
  _audioPlayer.dispose()  ← resources free
  _timer?.cancel()        ← countdown timer band
  _anim.dispose()         ← animation band
```

**Sound status:**
- AudioPlayer: **BAND** ✅ (dispose mein explicitly stop)
- OS notification sound: pehle se cancel tha

---

### Situation 5 — Driver IncomingOrderScreen pe **DECLINE** karta hai

```dart
// incoming_order_screen.dart — Decline button
onPressed: () {
  dc.declinedOrderIds.add(order.id);  // ← id declined set mein daal
  Navigator.of(context).pop();         // ← screen BAND
}
```

```
Decline tap
    ↓
order.id → declinedOrderIds mein add
    ↓
Navigator.pop() → dispose() call
    ↓
  _audioPlayer.stop()     ← AudioPlayer BAND ✅
  _audioPlayer.dispose()
  _timer?.cancel()
    ↓
_HomeWrapper mein _isIncomingOpen = false (via .then() callback)
    ↓
Agli polling (5s baad) → same order milega BUT
  ever() check: declinedOrderIds.contains(order.id) → TRUE
  → IncomingOrderScreen NAHI khulega ✅
  → Sound NAHI bajega ✅
```

**Sound status:**
- AudioPlayer: **BAND** ✅
- Dobara sound: **NAHI BAJEGA** (jab tak app restart na ho)

---

### Situation 6 — 30 second COUNTDOWN expire hota hai (na accept, na decline)

```dart
// incoming_order_screen.dart — Timer
_timer = Timer.periodic(const Duration(seconds: 1), (t) {
  if (_countdown <= 1) {
    t.cancel();
    if (mounted) Navigator.of(context).pop();  // ← auto dismiss
  } else {
    setState(() => _countdown--);
  }
});
```

```
30 seconds guzar jaate hain
    ↓
Timer callback: Navigator.pop()
    ↓
dispose() call
    ↓
  _audioPlayer.stop()   ← AudioPlayer BAND ✅
  _timer?.cancel()
    ↓
_isIncomingOpen = false (via .then())
    ↓
Note: order.id declinedOrderIds mein NAHI add hota
    ↓
Agli polling mein same order phir aa sakta hai
→ IncomingOrderScreen DOBARA khul sakta hai ✅
→ Sound DOBARA bajega ✅
```

**Sound status:**
- AudioPlayer: **BAND** ✅ (dispose se)
- Dobara sound: **HAA BAAJEGA** (timeout = implicit skip, explicit decline nahi)

---

### Situation 7 — App RESUME hota hai (background se foreground)

```dart
// main.dart — _HomeWrapperState
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    PushNotificationService.cancelAllNotifications();  // ← OS notifications clear
    Get.find<DeliveryController>().fetchAssignedOrder();
  }
}
```

```
Driver app pe wapas aata hai
    ↓
didChangeAppLifecycleState(resumed) trigger
    ↓
cancelAllNotifications() → OS notification sound BAND ✅
    ↓
fetchAssignedOrder() → order check
    ↓
agar order hai:
  ever() → IncomingOrderScreen navigate
  _playAlertSound() → AudioPlayer SHURU ✅
agar order nahi:
  koi sound nahi ❌
```

**Sound status:**
- OS notification sound: **BAND** ✅ (clear ho jaata hai)
- AudioPlayer: **SHURU** ✅ (agar pending order hai)

---

### Situation 8 — Koi `order_update` notification aati hai (delivery update, COD etc.)

Yeh notifications **order_channel** pe nahi jaatein, `default_channel` pe jaatein hain.

```dart
// push_notification_service.dart — _showLocalNotification
bool isOrder = message.data['type'] == 'new_order';

AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  isOrder ? 'order_channel' : 'default_channel',   // ← default channel
  ...
  sound: isOrder
      ? const RawResourceAndroidNotificationSound('order_sound')
      : null,   // ← DEFAULT system sound, order_sound NAHI
);
```

```
order_update notification aati hai
    ↓
isOrder = false (type != 'new_order')
    ↓
default_channel use hoti hai
    ↓
System default sound bajtaa hai (ding/ping)
    ↓
order_sound NAHI bajtaa ✅
```

**Sound status:**
- `order_sound`: **NAHI BAJTA** ✅
- System default sound: **BAJTA HAI** (normal notification)

---

## Complete Sound State Table

| Situation | App State | OS Notification Sound | AudioPlayer (In-App) |
|-----------|-----------|----------------------|---------------------|
| Naya order, app background | Background | ✅ BAJTA (order_sound, 1 baar) | ❌ NAHI CHAL RAHA |
| Notification pe tap, screen khulti hai | Background→Foreground | 🔴 BAND (cancel) | ✅ SHURU (loop) |
| Naya order, polling se, app foreground | Foreground | ❌ SUPPRESS HOTI HAI | ✅ SHURU (loop) |
| Driver Accept karta hai | Foreground | 🔴 BAND (pehle se) | 🔴 BAND (dispose) |
| Driver Decline karta hai | Foreground | 🔴 BAND (pehle se) | 🔴 BAND (dispose) |
| 30s countdown expire | Foreground | 🔴 BAND (pehle se) | 🔴 BAND (dispose) |
| App resume (background→front) | Resuming | 🔴 BAND (cancel) | ✅ SHURU (agar order pending) |
| `order_update` notification | Any | 🔔 Default sound | ❌ NAHI CHAL RAHA |

---

## Sound Flow Diagram

```
NAYA ORDER AVAILABLE
        │
        ▼
┌───────────────────┐
│  App kis state    │
│  mein hai?        │
└───────────────────┘
        │
   ┌────┴────┐
   │         │
BACKGROUND  FOREGROUND
   │         │
   ▼         ▼
FCM OS    FCM foreground
notification  mein aata hai
bajtaa       LEKIN suppress
order_sound  hota hai
(1 baar)     (type==new_order)
   │         │
   │         ▼
   │    Polling (5s) ne
   │    already detect
   │    kar liya hoga
   │         │
   │         ▼
Driver ────────────────►  IncomingOrderScreen
notification               OPEN HOTA HAI
tap karta hai                    │
   │                             ▼
   ▼                    cancelAllNotifications()
cancelAllNotifications()   OS sound → BAND 🔴
OS sound → BAND 🔴         AudioPlayer → SHURU ✅
   │                       (loop mode)
   └─────────┬─────────────────┘
             │
             ▼
     ┌───────────────┐
     │ Driver kya    │
     │ karta hai?    │
     └───────────────┘
             │
    ┌────────┼────────┐
    │        │        │
  ACCEPT  DECLINE  TIMEOUT
    │        │     (30s)
    ▼        ▼        ▼
  pop()   pop()    pop()
    │        │        │
    ▼        ▼        ▼
dispose()  dispose()  dispose()
stop() ✅  stop() ✅   stop() ✅
           │
           ▼
     declinedOrderIds
     mein add hota hai
           │
           ▼
     Wohi order
     DOBARA nahi
     aayega (session)

     TIMEOUT ke case mein:
     declinedOrderIds mein
     ADD NAHI hota
     → Order phir aa sakta hai
```

---

## Important Edge Cases

### Edge Case 1 — Double Sound (Theoretical)
Agar kisi reason se `IncomingOrderScreen` open ho aur koi purani OS notification bhi chal rahi ho, tab `initState()` mein `cancelAllNotifications()` call hoti hai **AudioPlayer start hone se pehle**. Yeh ensure karta hai dono kabhi ek saath nahi bajenge.

```dart
// incoming_order_screen.dart initState()
PushNotificationService.cancelAllNotifications();  // pehle yeh
_playAlertSound();                                  // phir yeh
```

### Edge Case 2 — App Restart ke baad Declined Orders
`declinedOrderIds` ek **in-memory** `RxSet` hai. App restart hone pe yeh clear ho jaata hai. Iska matlab hai ki agar driver ne ek order decline kiya aur phir app restart kiya, wahi order dobara `IncomingOrderScreen` pe aayega aur sound dobara bajega.

### Edge Case 3 — Multiple Polls Before Screen Opens
`_HomeWrapper` mein `_isIncomingOpen` flag hai jo prevent karta hai ki ek hi order ke liye multiple `IncomingOrderScreen` na khulein:

```dart
if (!_isIncomingOpen) {
  _isIncomingOpen = true;
  Future.delayed(Duration(milliseconds: 300), () {
    Get.toNamed('/incoming-order', arguments: order)?.then((_) {
      _isIncomingOpen = false;  // screen band hone ke baad reset
    });
  });
}
```

Agar 300ms delay ke dauran polling phir se same order laaye, `_isIncomingOpen = true` hone ki wajah se naya screen nahi khulega aur sound duplicate nahi bajega.

### Edge Case 4 — AudioPlayer dispose ke baad stop()
`dispose()` mein pehle `stop()` phir `dispose()` call hota hai:

```dart
@override
void dispose() {
  _audioPlayer.stop();     // ← sound rukta hai
  _audioPlayer.dispose();  // ← resources release
  ...
}
```

Yeh correct order hai. Agar sirf `dispose()` call karte to some platforms pe sound loop chalta reh sakta tha.

---

## Known Sound-Related Gaps

| Gap | Description | Impact |
|-----|-------------|--------|
| Background sound loop nahi | OS notification sound sirf 1 baar bajta hai, loop nahi | Driver miss kar sakta hai |
| Backend `new_order` type nahi bhejta driver ko | Backend mein driver ke liye koi FCM push nahi hai, sirf polling hai | Background mein OS sound bajtaa hi nahi jab tak notification manually bheja na jaaye |
| iOS `order_sound.aiff` verify nahi | iOS bundle mein file honi chahiye, code mein reference hai lekin deployment confirm nahi | iOS pe sound nahi bajega agar file missing ho |
| Timeout = implicit retry | 30s timeout pe `declinedOrderIds` mein add nahi hota | Order har 5s mein phir se ping karega jab tak koi na le |

---

## Summary

Ek line mein:

> **Jab app foreground mein hai** → sirf `AudioPlayer` (loop) bajta hai, OS notification suppress hoti hai.  
> **Jab app background mein hai** → sirf OS notification sound (1 baar) bajta hai, AudioPlayer nahi chalta.  
> **Jab IncomingOrderScreen band hoti hai** (accept/decline/timeout) → `dispose()` mein `AudioPlayer.stop()` call hoti hai, sound hamesha band ho jaata hai.  
> **Jab app resume hota hai** → OS notifications cancel hoti hain, agar order pending hai to AudioPlayer dobara shuru hota hai.
