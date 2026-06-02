import 'package:get/get.dart';
import 'package:organic_grow/views/cart_screen.dart';
import 'package:organic_grow/views/categories_screen.dart';
import 'package:organic_grow/views/home_screen/home_screen.dart';
import 'package:organic_grow/views/profile_screen.dart';
import 'package:organic_grow/views/settings_screen.dart';

class DashBoardController extends GetxController {
  var selectedIndex = 2.obs;

  final screens = [
    ProfileScreen(),
    CategoriesScreen(),
    HomeScreen(),
    CartScreen(),
    SettingsScreen(),
  ];

  void onTabChange(int index) {
    selectedIndex.value = index;
  }
}
