import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/models/product_model.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/models/cart_item_model.dart';
import 'package:organic_grow/core/controllers/home_page_controller.dart';
import 'package:organic_grow/core/controllers/wishlist_controller.dart';
import 'package:organic_grow/core/services/api_services.dart';

class ProductDetailScreen extends StatelessWidget {
  ProductDetailScreen({super.key});

  final CartController cartController = Get.isRegistered<CartController>()
      ? Get.find<CartController>()
      : Get.put(CartController());
  final WishlistController wishlistController = Get.isRegistered<WishlistController>()
      ? Get.find<WishlistController>()
      : Get.put(WishlistController());
  final RxInt quantity = 1.obs;

  @override
  Widget build(BuildContext context) {
    // Retrieve product safely from arguments
    final Product product = Get.arguments as Product;

    // Resolve vendor name dynamically if empty
    final HomeController homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    String sellerName = product.vendorName;
    if (sellerName.isEmpty && product.vendorId.isNotEmpty) {
      final v = homeController.vendors.firstWhereOrNull((vendor) => vendor.id == product.vendorId);
      if (v != null) {
        sellerName = v.shopName;
      }
    }
    if (sellerName.isEmpty) {
      sellerName = 'Organic Grow Store';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Gorgeous Scrollable Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Dynamic Image Header with custom back/wishlist overlays
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                stretch: true,
                backgroundColor: AppColor.primaryColor,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Get.back(),
                  ),
                ),
                actions: [
                  Obx(() {
                    final isFav = wishlistController.isFavorite(product.id);
                    return Container(
                      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? Colors.pink : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          wishlistController.toggleWishlist(product);
                        },
                      ),
                    );
                  }),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Render dynamic Image
                      product.image.startsWith('http')
                          ? Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                            )
                          : Image.asset(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                            ),
                      // Soft organic gradient overlay on image base
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.02),
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Product Info and Details Panel
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -28, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.eco_rounded, color: AppColor.primaryColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '100% Organic',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColor.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              product.stock > 0 ? 'In Stock' : 'Out of Stock',
                              style: AppTypography.caption.copyWith(
                                color: product.stock > 0 ? AppColor.primaryColor : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Unit description
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppTypography.h2.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Unit: 1 ${product.unit}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColor.textColor.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Price Badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${product.price.toStringAsFixed(2)}',
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '/ per ${product.unit}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColor.textColor.withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Rating overview
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Guaranteed Freshness 🌟',
                              style: AppTypography.caption.copyWith(
                                color: AppColor.textColor.withOpacity(0.5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Product Description
                        Text(
                          'Product Description',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColor.textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColor.textColor.withOpacity(0.65),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 28),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Sold By Card
                        if (product.vendorId.isNotEmpty) ...[
                          Text(
                            'Sold By',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColor.textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Get.toNamed('/vendor-store', arguments: product.vendorId);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColor.primaryColor.withOpacity(0.15),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primaryColor.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColor.primaryColor.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: AppColor.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sellerName,
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColor.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tap to visit store and explore more products',
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.grey[500],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColor.primaryColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                        ],

                        // Reviews Section
                        _ReviewsSection(product: product),

                        const SizedBox(height: 28),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Quantity Selector Card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Choose Quantity',
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColor.textColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).dividerColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  _buildQtyActionButton(
                                    icon: Icons.remove_rounded,
                                    onTap: () {
                                      if (quantity.value > 1) quantity.value--;
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 18),
                                    child: Obx(
                                      () => Text(
                                        '${quantity.value}',
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _buildQtyActionButton(
                                    icon: Icons.add_rounded,
                                    onTap: () {
                                      if (quantity.value < product.stock) {
                                        quantity.value++;
                                      } else {
                                        Get.snackbar(
                                          'Stock Limit',
                                          'Only ${product.stock} items are available in stock.',
                                          backgroundColor: Colors.amber[800],
                                          colorText: Colors.white,
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Massive spacing to ensure scroll clears the bottom bar
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Sticky Floating Bottom Action Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Total pricing summary
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Price',
                            style: AppTypography.caption.copyWith(
                              color: AppColor.textColor.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(
                            () => Text(
                              '₹${(product.price * quantity.value).toStringAsFixed(2)}',
                              style: AppTypography.h2.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColor.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Add to Basket button
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: () {
                          cartController.addToCart(
                            CartItem(
                              id: product.id,
                              name: product.name,
                              price: product.price,
                              image: product.image,
                              quantity: quantity.value,
                              vendorId: product.vendorId,
                              vendorName: sellerName,
                              unit: product.unit,
                            ),
                          );
                          Get.snackbar(
                            'Added to Basket 🛍️',
                            '${quantity.value}x ${product.name} added successfully!',
                            backgroundColor: AppColor.primaryColor,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            borderRadius: 16,
                            margin: const EdgeInsets.all(16),
                            icon: const Icon(Icons.shopping_basket_rounded, color: Colors.white),
                            duration: const Duration(seconds: 2),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          'Add to Basket',
                          style: AppTypography.buttonLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColor.primaryColor),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFF4F9F5),
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco_rounded,
        size: 80,
        color: AppColor.primaryColor,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVIEWS SECTION — loads reviews + write-review button
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.product});
  final Product product;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  bool _canReview = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reviews = await ApiService.fetchProductReviews(widget.product.id);
      Map<String, dynamic>? eligibility;
      if (ApiService.userToken != null) {
        try {
          eligibility = await ApiService.canReviewProduct(widget.product.id);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _canReview = eligibility?['canReview'] == true;
          _alreadyReviewed = eligibility?['reason'] == 'already_reviewed';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<double>(
        0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0));
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Ratings & Reviews',
            style: AppTypography.h4
                .copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor)),
        if (_canReview)
          GestureDetector(
            onTap: () async {
              final result = await Get.toNamed('/write-review', arguments: {
                'productId': widget.product.id,
                'vendorId': widget.product.vendorId,
                'productName': widget.product.name,
              });
              if (result == true) _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColor.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.rate_review_rounded,
                    color: AppColor.primaryColor, size: 14),
                const SizedBox(width: 4),
                Text('Write Review',
                    style: AppTypography.caption.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          )
        else if (_alreadyReviewed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Reviewed ✓',
                style: AppTypography.caption.copyWith(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ),
      ]),
      const SizedBox(height: 14),

      if (_loading)
        const Center(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(
              color: AppColor.primaryColor, strokeWidth: 2),
        ))
      else if (_reviews.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(children: [
            const Icon(Icons.star_border_rounded,
                color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No reviews yet. Be the first to review this product!',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColor.textColor.withValues(alpha: 0.55)),
              ),
            ),
          ]),
        )
      else ...[
        // Average rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Text(_avgRating.toStringAsFixed(1),
                style: AppTypography.h1.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.amber[700])),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < _avgRating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 18,
                        )),
              ),
              const SizedBox(height: 4),
              Text('${_reviews.length} review${_reviews.length == 1 ? '' : 's'}',
                  style: AppTypography.caption.copyWith(
                      color: AppColor.textColor.withValues(alpha: 0.55))),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // Review list (max 5 shown)
        ..._reviews.take(5).map((r) => _ReviewTile(review: r)),

        if (_reviews.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${_reviews.length - 5} more reviews',
              style: AppTypography.caption.copyWith(
                  color: AppColor.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    ]);
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final user = review['userId'] as Map<String, dynamic>?;
    final name = user?['name'] as String? ?? 'Anonymous';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final text = review['reviewText'] as String? ?? '';
    final createdAt = review['createdAt'] as String? ?? '';
    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        const months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        dateStr = '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColor.primaryColor.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColor.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold, color: AppColor.textColor)),
              if (dateStr.isNotEmpty)
                Text(dateStr,
                    style: AppTypography.caption.copyWith(
                        color: AppColor.textColor.withValues(alpha: 0.45))),
            ]),
          ),
          Row(
            children: List.generate(
                5,
                (i) => Icon(
                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 14,
                    )),
          ),
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(text,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColor.textColor.withValues(alpha: 0.7),
                  height: 1.5)),
        ],
      ]),
    );
  }
}
