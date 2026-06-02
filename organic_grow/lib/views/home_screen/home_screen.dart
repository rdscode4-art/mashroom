import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';
import 'package:organic_grow/core/controllers/checkout_controller.dart';
import 'package:organic_grow/views/sub_pages/add_address_with_map_screen.dart';
import 'package:organic_grow/views/home_screen/widget/carousel_slider_widget.dart';
import 'package:organic_grow/views/home_screen/widget/categories_section_widget.dart';
import 'package:organic_grow/views/home_screen/widget/featured_product_widget.dart';
import 'package:organic_grow/views/home_screen/widget/special_offer.dart';
import 'package:organic_grow/views/home_screen/widget/vendor_section_widget.dart';
import 'package:organic_grow/views/sub_pages/wishlist_screen.dart';

class HomeScreen extends GetView<HomeController> {
  HomeScreen({super.key});

  final HomeController homeController = Get.put(HomeController());
  final ProfileController profileController = Get.put(ProfileController());
  final CheckoutController checkoutController = Get.isRegistered<CheckoutController>()
      ? Get.find<CheckoutController>()
      : Get.put(CheckoutController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: AppColor.primaryColor,
        onRefresh: homeController.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Zomato-Style Premium Location & Search Header
              _buildHeader(context),
              
              const SizedBox(height: 16),
              
              // 2. Carousel Slider
              Obx(() => _buildCarouselSlider()),
              
              const SizedBox(height: 24),
              
              // 3. Double-Row Categories Grid ("What's on your mind?")
              Obx(() => _buildCategoriesSection()),
              
              const SizedBox(height: 24),

              // 4. Nearby Stores Section (Zomato-style vendor cards with filter row)
              Obx(() => _buildVendorSection()),
              
              const SizedBox(height: 24),
              
              // 5. Special Offers Section
              Obx(() => _buildSpecialOffersSection()),
              
              const SizedBox(height: 24),
              
              // 6. Featured Products Section
              Obx(() => _buildFeaturedProductsSection()),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Zomato style neutral header with red location pin, dynamic location text & profile image
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Location + Profile Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showLocationSelectorBottomSheet(context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Deliver to',
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.grey[600],
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Obx(() {
                                  final user = profileController.user.value;
                                  return Text(
                                    user.address.isNotEmpty ? user.address : 'Locating...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColor.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Heart / Wishlist icon
                  GestureDetector(
                    onTap: () => Get.to(() => const WishlistScreen()),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Profile Photo
                  Obx(() {
                    final user = profileController.user.value;
                    final hasProfileImage = user.image.isNotEmpty && !user.image.contains('assets/');
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColor.primaryColor.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: hasProfileImage
                            ? NetworkImage(user.image)
                            : const AssetImage('assets/user_profile.jpg') as ImageProvider,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 18),
              
              // Always visible sticky-style Search Bar
              _buildSearchBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              readOnly: true,
              onTap: () {
                Get.toNamed('/search');
              },
              decoration: InputDecoration(
                hintText: "Search 'organic fruits', 'fresh veggies'...",
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColor.primaryColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() =>
      homeController.isLoading.value ? const CarouselSliderWidgetShimmer() : CarouselSliderWidget();

  Widget _buildCategoriesSection() =>
      homeController.isLoading.value ? const CategoriesSectionWidgetShimmer() : CategoriesSectionWidget();

  Widget _buildVendorSection() =>
      homeController.isLoading.value ? const VendorSectionWidgetShimmer() : VendorSectionWidget();

  Widget _buildFeaturedProductsSection() =>
      homeController.isLoading.value ? const FeaturedProductWidgetShimmer() : FeaturedProductWidget();

  Widget _buildSpecialOffersSection() =>
      homeController.isLoading.value ? const SpecialOffersWidgetShimmer() : SpecialOffersWidget();

  void _showLocationSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Delivery Location 📍',
                      style: AppTypography.h4.copyWith(
                        color: AppColor.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(height: 20),
                
                // Action 1: Use Current GPS location
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location_rounded, color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Use Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent)),
                  subtitle: const Text('Fetch precise coordinates from device GPS', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    Get.back();
                    await profileController.fetchAndSaveCurrentLocation();
                  },
                ),
                
                // Action 2: Select location on Map
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_outlined, color: Colors.amber, size: 20),
                  ),
                  title: const Text('Select Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                  subtitle: const Text('Pin your exact address using Google Maps', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Get.back();
                    Get.to(() => AddAddressWithMapScreen(cc: checkoutController));
                  },
                ),
                const SizedBox(height: 12),
                
                Text(
                  'Saved Addresses',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Saved Addresses list
                Expanded(
                  child: Obx(() {
                    final list = checkoutController.savedAddresses;
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No saved addresses yet.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final addr = list[index];
                        final type = addr.addressType.toLowerCase();
                        IconData icon = Icons.location_on_outlined;
                        if (type == 'home') icon = Icons.home_outlined;
                        if (type == 'work') icon = Icons.work_outline_rounded;
                        
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColor.primaryColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: AppColor.primaryColor, size: 20),
                          ),
                          title: Text(addr.addressType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(addr.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            // Update active location coordinates in profile controller
                            profileController.latitude.value = addr.latitude;
                            profileController.longitude.value = addr.longitude;
                            profileController.user.update((val) {
                              if (val != null) {
                                val.address = addr.fullAddress;
                              }
                            });
                            Get.back();
                            Get.snackbar(
                              'Location Updated 📍',
                              'Delivering to ${addr.addressType.toUpperCase()}',
                              backgroundColor: AppColor.primaryColor,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
