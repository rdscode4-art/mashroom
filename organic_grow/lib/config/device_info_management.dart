
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  static Future<String> getDeviceToken() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final platform = getAppType();
      final deviceId = await getDeviceId();
      return 'token_${platform}_${deviceId}_$timestamp';
    } catch (e) {
      return 'default_device_token_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  static String getAppType() {
    return Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web';
  }

  static Future<String> getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      }
      return 'unknown_device';
    } catch (e) {
      return 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}
