import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';
import 'package:organic_grow/core/controllers/order_controller.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/views/cart_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key}) {
    Get.lazyPut<ProfileController>(() => ProfileController());
  }

  final ProfileController userController = Get.find();
  OrderController get orderController => Get.isRegistered<OrderController>() ? Get.find<OrderController>() : Get.put(OrderController());
  WishlistController get wishlistController => Get.isRegistered<WishlistController>() ? Get.find<WishlistController>() : Get.put(WishlistController());
  CartController get cartController => Get.isRegistered<CartController>() ? Get.find<CartController>() : Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        final user = userController.user.value;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              // 1. Beautiful Curved Background Banner
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20), // Jungle Green
                      Color(0xFF4CAF50), // Fresh Emerald Green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle Organic Shapes / Accents inside the banner
                    Positioned(
                      top: -50,
                      right: -30,
                      child: CircleAvatar(
                        radius: 110,
                        backgroundColor: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -40,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    // App Bar / Title inside banner
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'My Profile',
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Main Scrollable Content
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 70), // Push content down past the app bar area

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B5E20).withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Beautiful Avatar Frame with fallback image support
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppColor.secondaryColor.withOpacity(0.1),
                                      child: ClipOval(
                                        child: user.image.startsWith('http')
                                            ? Image.network(
                                                user.image,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person_rounded,
                                                    size: 55,
                                                    color: AppColor.primaryColor,
                                                  );
                                                },
                                              )
                                            : Image.asset(
                                                user.image,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.person_rounded,
                                                    size: 55,
                                                    color: AppColor.primaryColor,
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                ),
                                // Edit camera icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColor.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user.name,
                              style: AppTypography.h2.copyWith(
                                color: AppColor.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColor.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Interactive Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.shopping_bag_outlined,
                              value: orderController.orders.length.toString(),
                              label: 'Orders',
                              color: AppColor.primaryColor,
                              onTap: () => Get.toNamed('/orders'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.favorite_outline_rounded,
                              value: wishlistController.wishlistItems.length.toString(),
                              label: 'Wishlist',
                              color: const Color(0xFFE91E63),
                              onTap: () => Get.toNamed('/wishlist'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatItem(
                              icon: Icons.shopping_cart_outlined,
                              value: cartController.cartItems.length.toString(),
                              label: 'Cart',
                              color: const Color(0xFFFFB300),
                              onTap: () => Get.to(() => CartScreen()),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Personal Information Group
                      _buildSectionTitle('Personal Details'),
                      const SizedBox(height: 8),
                      _buildGroupContainer([
                        _buildInfoTile(
                          icon: Icons.phone_android_rounded,
                          title: 'Phone Number',
                          subtitle: user.phone,
                          color: AppColor.primaryColor,
                        ),
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                        _buildInfoTile(
                          icon: Icons.location_on_rounded,
                          title: 'Delivery Address',
                          subtitle: user.address,
                          color: Colors.orange,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Account Actions Group
                      _buildSectionTitle('My Account'),
                      const SizedBox(height: 8),
                      _buildGroupContainer([
                        _buildActionTile(
                          icon: Icons.edit_note_rounded,
                          label: 'Edit Profile',
                          color: Colors.blue,
                          onTap: () => Get.toNamed('/edit-profile'),
                        ),
                        if (user.role == 'vendor') ...[
                          Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                          _buildActionTile(
                            icon: Icons.storefront_rounded,
                            label: 'Store Management',
                            color: Colors.orange,
                            onTap: () => Get.toNamed('/vendor-panel'),
                          ),
                        ],
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                        _buildActionTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Order History',
                          color: Colors.teal,
                          onTap: () => Get.toNamed('/orders'),
                        ),
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                        _buildActionTile(
                          icon: Icons.favorite_rounded,
                          label: 'Wishlist',
                          color: Colors.pink,
                          onTap: () => Get.toNamed('/wishlist'),
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // Support & Settings Group
                      _buildSectionTitle('App Settings'),
                      const SizedBox(height: 8),
                      _buildGroupContainer([
                        _buildActionTile(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          color: Colors.purple,
                          onTap: () => Get.toNamed('/notifications'),
                        ),
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                        _buildActionTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Help & Support',
                          color: Colors.indigo,
                          onTap: () => Get.toNamed('/help'),
                        ),
                        Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor),
                        _buildActionTile(
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          color: Colors.redAccent,
                          onTap: () => _showLogoutDialog(),
                          isLogout: true,
                        ),
                      ]),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Section titles
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColor.textColor.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContainer(List<Widget> children) {
    final context = Get.context!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final context = Get.context!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColor.textColor.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Personal Info custom tile
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColor.textColor.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColor.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action custom tile
  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: AppTypography.bodyMedium.copyWith(
          color: isLogout ? Colors.redAccent : AppColor.textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isLogout ? Colors.redAccent.withOpacity(0.5) : AppColor.textColor.withOpacity(0.3),
      ),
    );
  }

  void _showLogoutDialog() {
    final context = Get.context!;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).cardColor,
        titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColor.textColor,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your RiFresh India account?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColor.textColor.withOpacity(0.6),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColor.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Get.back();
                    await ApiService.clearToken();
                    Get.offAllNamed('/login_screen');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Logout',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}