import 'package:get/get.dart';
import 'package:organic_grow/routing/route_constant.dart';
import 'package:organic_grow/views/dashBoard_screen.dart';
import 'package:organic_grow/views/home_screen/home_screen.dart';
import 'package:organic_grow/views/login_screen/login_screen.dart';
import 'package:organic_grow/views/splash_screen.dart';
import 'package:organic_grow/views/register_screen/register_screen.dart';
import 'package:organic_grow/views/product_list_screen.dart';
import 'package:organic_grow/views/product_detail_screen.dart';
import 'package:organic_grow/views/vendor_store_screen.dart';
import 'package:organic_grow/views/vendor_panel_screen.dart';
import 'package:organic_grow/views/all_vendors_screen.dart';

// Separate imports for all sub-screens
import 'package:organic_grow/views/sub_pages/edit_profile_screen.dart';
import 'package:organic_grow/views/sub_pages/order_history_screen.dart';
import 'package:organic_grow/views/sub_pages/wishlist_screen.dart';
import 'package:organic_grow/views/sub_pages/notifications_screen.dart';
import 'package:organic_grow/views/sub_pages/help_screen.dart';
import 'package:organic_grow/views/sub_pages/privacy_policy_screen.dart';
import 'package:organic_grow/views/sub_pages/terms_of_service_screen.dart';
import 'package:organic_grow/views/sub_pages/about_app_screen.dart';
import 'package:organic_grow/views/sub_pages/checkout_screen.dart';
import 'package:organic_grow/views/sub_pages/order_success_screen.dart';
import 'package:organic_grow/views/sub_pages/write_review_screen.dart';
import 'package:organic_grow/views/sub_pages/track_order_screen.dart';
import 'package:organic_grow/views/search_screen.dart';

final List<GetPage> getPages = [
  GetPage( 
    name: RouteConstant.loginPage,
    page: () => LoginScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage( 
    name: RouteConstant.registerPage,
    page: () => RegisterScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage( 
    name: RouteConstant.homePage,
    page: () => HomeScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage( 
    name: RouteConstant.splashPage,
    page: () => SplashScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage( 
    name: RouteConstant.dashBoardPae,
    page: () => DashBoardScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/product-list',
    page: () => ProductListScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/category-products',
    page: () => ProductListScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/product-detail',
    page: () => ProductDetailScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/vendor-store',
    page: () => VendorStoreScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/vendor-panel',
    page: () => VendorPanelScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/all-vendors',
    page: () => const AllVendorsScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/edit-profile',
    page: () => EditProfileScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/orders',
    page: () => const OrderHistoryScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/wishlist',
    page: () => const WishlistScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/notifications',
    page: () => const NotificationsScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/help',
    page: () => const HelpScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/privacy',
    page: () => const PrivacyPolicyScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/terms',
    page: () => const TermsOfServiceScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/about',
    page: () => const AboutAppScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/checkout',
    page: () => CheckoutScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/order-success',
    page: () => const OrderSuccessScreen(),
    transition: Transition.fadeIn,
  ),
  GetPage(
    name: '/write-review',
    page: () => const WriteReviewScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/track-order',
    page: () => const TrackOrderScreen(),
    transition: Transition.rightToLeft,
  ),
  GetPage(
    name: '/search',
    page: () => SearchScreen(),
    transition: Transition.fadeIn,
  ),
];
