// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';

// class ConnectivityController extends GetxController {
//   final RxBool _isConnected = true.obs;
//   bool get isConnected => _isConnected.value;

//   StreamSubscription? _subscription;

//   @override
//   void onInit() {
//     super.onInit();
//     _checkInitialConnection();

//     // Listen to connectivity changes
//     _subscription = Connectivity().onConnectivityChanged.listen((result) async {
//       bool hasInternet = await InternetConnectionChecker.instance.hasConnection;
//       _isConnected.value = hasInternet;
//     });
//   }

//   Future<void> _checkInitialConnection() async {
//     bool hasInternet = await InternetConnectionChecker.instance.hasConnection;
//     _isConnected.value = hasInternet;
//   }

//   @override
//   void onClose() {
//     _subscription?.cancel();
//     super.onClose();
//   }
// }



import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityController extends GetxController {
  final RxBool _isConnected = true.obs;
  bool get isConnected => _isConnected.value;

  @override
  void onInit() {
    super.onInit();
    checkConnection(); // one-time check when page loads
  }

  /// ✅ Call this manually when needed (e.g. Retry button)
  Future<void> checkConnection() async {
    bool hasInternet = await InternetConnectionChecker.instance.hasConnection;
    _isConnected.value = hasInternet;
  }
}
