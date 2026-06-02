import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/checkout_controller.dart';
import 'package:organic_grow/core/controllers/cart_controller.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:organic_grow/views/sub_pages/add_address_with_map_screen.dart';

class CheckoutScreen extends StatelessWidget {
  CheckoutScreen({super.key});

  final CheckoutController cc = Get.put(CheckoutController());
  final CartController cartController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkout',
            style: AppTypography.h3
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      // ── Layout: pinned address card + scrollable content ──────────
      body: Column(
        children: [
          // ── PINNED ADDRESS CARD (never scrolls) ───────────────────
          _PinnedAddressCard(cc: cc),
          // ── SCROLLABLE CONTENT ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('Order Summary'),
                  const SizedBox(height: 12),
                  _OrderSummaryCard(cartController: cartController, cc: cc),
                  const SizedBox(height: 24),
                  _SectionTitle('Apply Coupon'),
                  const SizedBox(height: 12),
                  _CouponSection(cc: cc),
                  const SizedBox(height: 24),
                  _SectionTitle('Payment Method'),
                  const SizedBox(height: 12),
                  _PaymentTile(
                      value: 'cod',
                      title: 'Cash on Delivery',
                      subtitle: 'Pay when your order arrives',
                      icon: Icons.money_rounded,
                      color: Colors.green,
                      cc: cc),
                  const SizedBox(height: 12),
                  _PaymentTile(
                      value: 'online',
                      title: 'Pay Online',
                      subtitle: 'Cards, UPI, Net Banking',
                      icon: Icons.credit_card_rounded,
                      color: Colors.blue,
                      cc: cc),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _PlaceOrderBar(cc: cc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINNED ADDRESS CARD — sits above the scroll, always visible
// ─────────────────────────────────────────────────────────────────────────────
class _PinnedAddressCard extends StatelessWidget {
  const _PinnedAddressCard({required this.cc});
  final CheckoutController cc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final addr = cc.selectedAddress;
      final isLoading = cc.isLoadingAddresses.value;

      return Material(
        color: AppColor.primaryColor,
        elevation: 3,
        child: InkWell(
          onTap: () => _openAddressSheet(context, cc),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon bubble
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    addr != null ? addr.icon : Icons.add_location_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Address text
                Expanded(
                  child: isLoading
                      ? Text('Loading addresses…',
                          style: AppTypography.bodySmall
                              .copyWith(color: Colors.white70))
                      : addr != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Delivering to',
                                    style: AppTypography.caption.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(addr.shortLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                if (addr.subLine.isNotEmpty)
                                  Text(addr.subLine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption
                                          .copyWith(color: Colors.white70)),
                              ],
                            )
                          : Text('Tap to add delivery address',
                              style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                // Change / Add pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    addr != null ? 'Change' : 'Add',
                    style: AppTypography.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS BOTTOM SHEET — saved addresses list + add new
// ─────────────────────────────────────────────────────────────────────────────
void _openAddressSheet(BuildContext context, CheckoutController cc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddressSheet(cc: cc),
  );
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.cc});
  final CheckoutController cc;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  bool _showForm = false;

  // Form controllers
  final _houseCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  String _addressType = 'home';

  @override
  void dispose() {
    _houseCtrl.dispose();
    _floorCtrl.dispose();
    _buildingCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (!_showForm) ...[
              _sheetHeader(context),
              const SizedBox(height: 16),
              _savedList(context),
              const SizedBox(height: 12),
              _addNewButton(context),
            ] else ...[
              _formHeader(context),
              const SizedBox(height: 16),
              _addressForm(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sheetHeader(BuildContext context) => Row(children: [
        const Icon(Icons.location_on_rounded,
            color: AppColor.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text('Select Delivery Address',
            style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold, color: AppColor.textColor)),
      ]);

  Widget _savedList(BuildContext context) {
    final cc = widget.cc;
    if (cc.savedAddresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('No saved addresses yet.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColor.textColor.withValues(alpha: 0.5))),
      );
    }
    return Obx(() => Column(
          children: List.generate(cc.savedAddresses.length, (i) {
            final addr = cc.savedAddresses[i];
            final isSelected = cc.selectedIndex.value == i;
            return GestureDetector(
              onTap: () {
                cc.selectAddress(i);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColor.primaryColor.withValues(alpha: 0.07)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColor.primaryColor
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isSelected
                              ? AppColor.primaryColor
                              : Colors.grey[400]!)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(addr.icon,
                        color: isSelected
                            ? AppColor.primaryColor
                            : Colors.grey[500],
                        size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr.shortLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textColor)),
                          if (addr.subLine.isNotEmpty)
                            Text(addr.subLine,
                                style: AppTypography.caption.copyWith(
                                    color: AppColor.textColor
                                        .withValues(alpha: 0.55))),
                          if (addr.landmark.isNotEmpty)
                            Text('Near ${addr.landmark}',
                                style: AppTypography.caption.copyWith(
                                    color: AppColor.textColor
                                        .withValues(alpha: 0.45))),
                        ]),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_location_alt_rounded,
                        color: isSelected ? AppColor.primaryColor : Colors.grey[600],
                        size: 20),
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Get.to(() => AddAddressWithMapScreen(cc: widget.cc, addressToEdit: addr));
                    },
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColor.primaryColor, size: 20),
                ]),
              ),
            );
          }),
        ));
  }

  Widget _addNewButton(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context); // Close bottom sheet
            Get.to(() => AddAddressWithMapScreen(cc: widget.cc));
          },
          icon: const Icon(Icons.add_rounded, color: AppColor.primaryColor),
          label: Text('Add New Address',
              style: AppTypography.buttonMedium
                  .copyWith(color: AppColor.primaryColor)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppColor.primaryColor, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  Widget _formHeader(BuildContext context) => Row(children: [
        GestureDetector(
          onTap: () => setState(() => _showForm = false),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColor.primaryColor, size: 22),
        ),
        const SizedBox(width: 10),
        Text('New Address',
            style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold, color: AppColor.textColor)),
      ]);

  Widget _addressForm(BuildContext context) {
    final cc = widget.cc;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Address type chips
      Row(children: ['home', 'work', 'other'].map((t) {
        final sel = _addressType == t;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(t[0].toUpperCase() + t.substring(1)),
            selected: sel,
            onSelected: (_) => setState(() => _addressType = t),
            selectedColor: AppColor.primaryColor.withValues(alpha: 0.15),
            labelStyle: AppTypography.caption.copyWith(
                color: sel ? AppColor.primaryColor : AppColor.textColor,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal),
            side: BorderSide(
                color: sel ? AppColor.primaryColor : Colors.grey.shade300),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
        );
      }).toList()),
      const SizedBox(height: 14),
      // House + Floor
      Row(children: [
        Expanded(
            flex: 3,
            child: _Field(
                ctrl: _houseCtrl,
                label: 'House / Flat No. *',
                hint: 'e.g. 42B, Flat 301')),
        const SizedBox(width: 10),
        Expanded(
            flex: 2,
            child: _Field(ctrl: _floorCtrl, label: 'Floor', hint: 'e.g. 3rd')),
      ]),
      const SizedBox(height: 12),
      _Field(
          ctrl: _buildingCtrl,
          label: 'Building / Society',
          hint: 'e.g. Green Valley Apts'),
      const SizedBox(height: 12),
      _Field(
          ctrl: _areaCtrl,
          label: 'Area / Street / Sector',
          hint: 'e.g. MG Road, Sector 14'),
      const SizedBox(height: 12),
      _Field(
          ctrl: _landmarkCtrl,
          label: 'Landmark (Optional)',
          hint: 'e.g. Near City Mall'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _Field(
                ctrl: _cityCtrl, label: 'City *', hint: 'e.g. Bhubaneswar')),
        const SizedBox(width: 10),
        Expanded(
            child:
                _Field(ctrl: _stateCtrl, label: 'State', hint: 'e.g. Odisha')),
      ]),
      const SizedBox(height: 12),
      _Field(
          ctrl: _pincodeCtrl,
          label: 'Pincode *',
          hint: '6-digit pincode',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ]),
      const SizedBox(height: 20),
      Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: cc.isSavingAddress.value
                  ? null
                  : () async {
                      final ok = await cc.saveNewAddress(
                        houseNo: _houseCtrl.text,
                        floor: _floorCtrl.text,
                        building: _buildingCtrl.text,
                        area: _areaCtrl.text,
                        landmark: _landmarkCtrl.text,
                        city: _cityCtrl.text,
                        state: _stateCtrl.text,
                        pincode: _pincodeCtrl.text,
                        addressType: _addressType,
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: cc.isSavingAddress.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Save & Deliver Here',
                      style: AppTypography.buttonLarge.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.cartController, required this.cc});
  final CartController cartController;
  final CheckoutController cc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Obx(() {
        final subtotal = cartController.totalAmount.value;
        final delivery = cc.deliveryCharge.value;
        final taxPct = cc.taxPercent.value;
        final tax = subtotal * (taxPct / 100);
        final grandTotal = subtotal + delivery + tax - cc.couponDiscount.value;
        return Column(children: [
          ...cartController.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(item.name,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColor.textColor,
                                fontWeight: FontWeight.w600)),
                        Text('${item.unit} × ${item.quantity}',
                            style: AppTypography.caption.copyWith(
                                color:
                                    AppColor.textColor.withValues(alpha: 0.5))),
                      ])),
                  Text('₹${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textColor)),
                ]),
              )),
          const Divider(height: 20),
          _SummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _SummaryRow('Tax (${taxPct.toStringAsFixed(0)}%)', '₹${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _SummaryRow('Delivery Charge', '₹${delivery.toStringAsFixed(0)}'),
          if (cc.couponDiscount.value > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Coupon (${cc.couponCode.value})',
                    style: AppTypography.bodySmall.copyWith(
                        color: Colors.green[700])),
                Text('- ₹${cc.couponDiscount.value.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.green[700])),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold)),
            Text('₹${grandTotal.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColor.primaryColor)),
          ]),
        ]);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYMENT TILE
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  const _PaymentTile(
      {required this.value,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.cc});
  final String value, title, subtitle;
  final IconData icon;
  final Color color;
  final CheckoutController cc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = cc.selectedPaymentMethod.value == value;
      return InkWell(
        onTap: () => cc.setPaymentMethod(value),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.08)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? color : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: AppTypography.bodyLarge.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: AppColor.textColor)),
                  Text(subtitle,
                      style: AppTypography.caption.copyWith(
                          color: AppColor.textColor.withValues(alpha: 0.55))),
                ])),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('y'), color: color, size: 22)
                  : Icon(Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('n'),
                      color: Colors.grey[400],
                      size: 22),
            ),
          ]),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUPON SECTION
// ─────────────────────────────────────────────────────────────────────────────
class _CouponSection extends StatefulWidget {
  const _CouponSection({required this.cc});
  final CheckoutController cc;
  @override
  State<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<_CouponSection> {
  final _ctrl = TextEditingController();
  bool _showList = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cc = widget.cc;
      final applied = cc.couponApplied.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input row
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: !applied,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.bodyMedium.copyWith(
                    color: AppColor.textColor, fontWeight: FontWeight.w600,
                    letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: AppTypography.bodySmall.copyWith(
                      color: AppColor.textColor.withValues(alpha: 0.35),
                      letterSpacing: 0),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: applied
                              ? Colors.green
                              : AppColor.textColor.withValues(alpha: 0.15))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: applied
                              ? Colors.green
                              : AppColor.textColor.withValues(alpha: 0.15))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColor.primaryColor, width: 1.8)),
                  suffixIcon: applied
                      ? const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 20)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: cc.isValidatingCoupon.value
                    ? null
                    : applied
                        ? () {
                            cc.removeCoupon();
                            _ctrl.clear();
                          }
                        : () => cc.applyCoupon(_ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      applied ? Colors.red[400] : AppColor.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: cc.isValidatingCoupon.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        applied ? 'Remove' : 'Apply',
                        style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ]),

          // Feedback message
          if (cc.couponMessage.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Icon(
                  applied
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  size: 14,
                  color: applied ? Colors.green : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  cc.couponMessage.value,
                  style: AppTypography.caption.copyWith(
                      color: applied ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),

          // "View available coupons" toggle
          if (!applied) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _showList = !_showList),
              child: Row(children: [
                const Icon(Icons.local_offer_rounded,
                    size: 14, color: AppColor.primaryColor),
                const SizedBox(width: 6),
                Text(
                  _showList ? 'Hide available coupons' : 'View available coupons',
                  style: AppTypography.caption.copyWith(
                      color: AppColor.primaryColor, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _showList
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColor.primaryColor,
                ),
              ]),
            ),
            if (_showList) _CouponListSheet(cc: cc, onSelect: (code) {
              _ctrl.text = code;
              cc.applyCoupon(code);
            }),
          ],
        ],
      );
    });
  }
}

class _CouponListSheet extends StatefulWidget {
  const _CouponListSheet({required this.cc, required this.onSelect});
  final CheckoutController cc;
  final void Function(String code) onSelect;
  @override
  State<_CouponListSheet> createState() => _CouponListSheetState();
}

class _CouponListSheetState extends State<_CouponListSheet> {
  List<Map<String, dynamic>> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.fetchActiveCoupons();
      if (mounted) setState(() { _coupons = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(
            color: AppColor.primaryColor, strokeWidth: 2)),
      );
    }
    if (_coupons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text('No coupons available right now.',
            style: AppTypography.caption.copyWith(
                color: AppColor.textColor.withValues(alpha: 0.5))),
      );
    }
    return Column(
      children: _coupons.map((c) {
        final isPercent = c['discountType'] == 'percentage';
        final val = isPercent
            ? '${c['discountValue']}% OFF'
            : '₹${c['discountValue']} OFF';
        final minOrder = (c['minimumOrder'] ?? 0) as num;
        return GestureDetector(
          onTap: () => widget.onSelect(c['code'] as String),
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColor.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColor.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(c['code'] as String,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(val,
                      style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.textColor)),
                  if (minOrder > 0)
                    Text('Min order ₹$minOrder',
                        style: AppTypography.caption.copyWith(
                            color: AppColor.textColor.withValues(alpha: 0.5))),
                ]),
              ),
              Text('TAP',
                  style: AppTypography.caption.copyWith(
                      color: AppColor.primaryColor,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE ORDER BOTTOM BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({required this.cc});
  final CheckoutController cc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final isLoading = cc.isPlacingOrder.value;
          final total = cc.grandTotal;
          return ElevatedButton(
            onPressed: isLoading ? null : () => cc.placeOrder(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.btnColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Place Order',
                        style: AppTypography.buttonLarge.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('₹${total.toStringAsFixed(0)}',
                          style: AppTypography.caption.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.h4
          .copyWith(fontWeight: FontWeight.bold, color: AppColor.textColor));
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySmall.copyWith(
                  color: AppColor.textColor.withValues(alpha: 0.65))),
          Text(value,
              style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600, color: AppColor.textColor)),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColor.textColor.withValues(alpha: 0.7))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodySmall
              .copyWith(color: AppColor.textColor.withValues(alpha: 0.3)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColor.textColor.withValues(alpha: 0.15))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColor.textColor.withValues(alpha: 0.15))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColor.primaryColor, width: 1.8)),
        ),
      ),
    ]);
  }
}
