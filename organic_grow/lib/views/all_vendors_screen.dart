import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/models/vendor_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class AllVendorsScreen extends StatefulWidget {
  const AllVendorsScreen({super.key});

  @override
  State<AllVendorsScreen> createState() => _AllVendorsScreenState();
}

class _AllVendorsScreenState extends State<AllVendorsScreen> {
  late final HomeController homeController;
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString selectedTag = 'All'.obs;

  @override
  void initState() {
    super.initState();
    homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
  }

  // List of tags extracted from all vendors
  List<String> get tags {
    final allTags = <String>{'All'};
    for (var vendor in homeController.vendors) {
      allTags.addAll(vendor.cuisineTags);
    }
    return allTags.toList();
  }

  // Filtered vendors list
  List<Vendor> get filteredVendors {
    return homeController.vendors.where((vendor) {
      final matchesSearch = vendor.shopName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          vendor.description.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          vendor.cuisineTags.any((t) => t.toLowerCase().contains(searchQuery.value.toLowerCase()));

      final matchesTag = selectedTag.value == 'All' || vendor.cuisineTags.contains(selectedTag.value);

      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'All Stores 🏪',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.textColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (val) => searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Search stores, cuisines or items...',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColor.greyColor),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColor.primaryColor),
                  suffixIcon: Obx(() => searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppColor.greyColor),
                          onPressed: () {
                            searchController.clear();
                            searchQuery.value = '';
                          },
                        )
                      : const SizedBox.shrink()),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Tag Filters
          Obx(() {
            final currentTags = tags;
            if (currentTags.length <= 1) return const SizedBox.shrink();

            return Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: currentTags.length,
                itemBuilder: (context, index) {
                  final tag = currentTags[index];
                  final isSelected = selectedTag.value == tag;
                  return GestureDetector(
                    onTap: () => selectedTag.value = tag,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColor.primaryColor : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColor.primaryColor : Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          tag,
                          style: AppTypography.buttonMedium.copyWith(
                            color: isSelected ? Colors.white : AppColor.textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // 3. Vendor Cards List
          Expanded(
            child: Obx(() {
              final list = filteredVendors;

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_rounded, size: 64, color: AppColor.greyColor.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No matching stores found',
                        style: AppTypography.h4.copyWith(color: AppColor.greyColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try searching for another keyword or tag',
                        style: AppTypography.bodyMedium.copyWith(color: AppColor.greyColor),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final vendor = list[index];
                  final String shopImageUrl = vendor.shopImage.isNotEmpty
                      ? ApiService.buildImageUrl(vendor.shopImage)
                      : '';

                  return GestureDetector(
                    onTap: () {
                      Get.toNamed('/vendor-store', arguments: vendor.id);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: SizedBox(
                              height: 130,
                              width: double.infinity,
                              child: shopImageUrl.isNotEmpty
                                  ? Image.network(
                                      shopImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(vendor),
                                    )
                                  : _buildPlaceholder(vendor),
                            ),
                          ),
                          // Details
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vendor.shopName,
                                        style: AppTypography.h4.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: vendor.isOpen
                                            ? AppColor.primaryColor.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        vendor.isOpen ? 'Open' : 'Closed',
                                        style: AppTypography.caption.copyWith(
                                          color: vendor.isOpen ? AppColor.primaryColor : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColor.primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            vendor.rating > 0 ? vendor.rating.toStringAsFixed(1) : 'New',
                                            style: AppTypography.caption.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time_rounded, size: 14, color: AppColor.greyColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      vendor.deliveryTime,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColor.greyColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (vendor.distance != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(Icons.directions_walk_rounded, size: 14, color: AppColor.greyColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${vendor.distance!.toStringAsFixed(1)} km',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColor.greyColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (vendor.cuisineTags.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: vendor.cuisineTags.take(4).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColor.primaryColor.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tag,
                                          style: AppTypography.caption.copyWith(
                                            color: AppColor.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Vendor vendor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primaryColor.withOpacity(0.15),
            AppColor.secondaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 40, color: AppColor.primaryColor.withOpacity(0.4)),
            const SizedBox(height: 6),
            Text(
              vendor.shopName,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColor.primaryColor.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
