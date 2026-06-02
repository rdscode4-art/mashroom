import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/controllers/wallet_controller.dart';
import '../core/theme/app_theme.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = Get.put(WalletController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: wc.fetchWalletHistory,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: wc.fetchWalletHistory,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── GLASSMORPHIC BALANCE CARD ──
                Obx(() => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF14241C),
                            Color(0xFF0F1E19),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AVAILABLE BALANCE',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SECURED',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${wc.balance.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(color: AppTheme.border.withOpacity(0.5), height: 1),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LIFETIME EARNINGS',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${wc.totalEarnings.value.toStringAsFixed(2)}',
                                    style: TextStyle(color: AppTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: wc.balance.value < 100
                                    ? null
                                    : () => _showPayoutBottomSheet(context, wc),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppTheme.border,
                                  disabledForegroundColor: AppTheme.textMuted,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                                label: const Text(
                                  'Withdraw',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (wc.balance.value < 100) ...[
                            const SizedBox(height: 12),
                            Text(
                              '* Minimum withdrawal limit is ₹100',
                              style: TextStyle(color: AppTheme.accent.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    )),
                const SizedBox(height: 28),

                // ── RECENT TRANSACTIONS HEADER ──
                Text(
                  'TRANSACTION HISTORY',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // ── TRANSACTIONS LIST ──
                Obx(() {
                  if (wc.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    );
                  }
                  if (wc.transactions.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted.withOpacity(0.5), size: 48),
                          const SizedBox(height: 14),
                          Text(
                            'No transactions recorded yet',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wc.transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = wc.transactions[index];
                      return _TransactionItem(tx: tx);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPayoutBottomSheet(BuildContext context, WalletController wc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayoutBottomSheetForm(wc: wc),
    );
  }
}

// ── TRANSACTION ITEM COMPONENT ──
class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final type = tx['type'] ?? 'earning';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final desc = tx['description'] ?? '';
    final dateStr = tx['createdAt'] ?? '';
    final rawWithdrawal = tx['withdrawalId'];
    final wReq = rawWithdrawal is Map<String, dynamic> ? rawWithdrawal : null;
    final wStatus = wReq?['status'] ?? 'pending';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      formattedDate = '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      formattedDate = dateStr;
    }

    Color badgeBg;
    Color badgeText;
    IconData icon;
    String sign;

    if (type == 'earning') {
      badgeBg = AppTheme.primary.withOpacity(0.12);
      badgeText = AppTheme.primary;
      icon = Icons.add_circle_outline_rounded;
      sign = '+';
    } else {
      sign = '-';
      icon = Icons.arrow_outward_rounded;
      if (wStatus == 'pending') {
        badgeBg = AppTheme.accent.withOpacity(0.12);
        badgeText = AppTheme.accent;
      } else if (wStatus == 'approved') {
        badgeBg = AppTheme.danger.withOpacity(0.12);
        badgeText = AppTheme.danger;
      } else {
        // rejected
        badgeBg = Colors.grey.withOpacity(0.15);
        badgeText = Colors.grey;
        icon = Icons.undo_rounded;
        sign = '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeText, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign₹${amount.abs().toStringAsFixed(1)}',
                style: TextStyle(
                  color: badgeText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (type == 'withdrawal') ...[
                const SizedBox(height: 2),
                Text(
                  wStatus.toUpperCase(),
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── PAYOUT BOTTOM SHEET FORM ──
class _PayoutBottomSheetForm extends StatefulWidget {
  const _PayoutBottomSheetForm({required this.wc});
  final WalletController wc;

  @override
  State<_PayoutBottomSheetForm> createState() => _PayoutBottomSheetFormState();
}

class _PayoutBottomSheetFormState extends State<_PayoutBottomSheetForm> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _upiController = TextEditingController();
  final _holderController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _upiController.dispose();
    _holderController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final method = _tabController.index == 0 ? 'upi' : 'bank';

    bool success = false;
    if (method == 'upi') {
      success = await widget.wc.submitWithdrawal(
        amount: amount,
        method: 'upi',
        upiId: _upiController.text.trim(),
      );
    } else {
      success = await widget.wc.submitWithdrawal(
        amount: amount,
        method: 'bank',
        bankDetails: {
          'holderName': _holderController.text.trim(),
          'bankName': _bankController.text.trim(),
          'accountNumber': _accountController.text.trim(),
          'ifscCode': _ifscController.text.trim().toUpperCase(),
        },
      );
    }

    if (success) {
      Get.back(); // Closes the payout bottom sheet
      Get.dialog(
        AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 54),
              ),
              const SizedBox(height: 20),
              Text(
                'Payout Requested! 🎉',
                style: TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your withdrawal request of ₹${amount.toStringAsFixed(0)} has been submitted successfully.\n\nIt will be reviewed and processed by our admin team shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Awesome', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Request Payout',
                style: TextStyle(color: AppTheme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Select transfer method and specify the amount.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Payout Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppTheme.textColor),
                decoration: InputDecoration(
                  labelText: 'Amount to Withdraw (₹)',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  hintText: 'Min ₹100',
                  hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primary),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter withdrawal amount';
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null) return 'Enter a valid decimal number';
                  if (numVal < 100) return 'Minimum withdrawal is ₹100';
                  if (numVal > widget.wc.balance.value) return 'Insufficient wallet balance';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Custom TabBar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: const [
                    Tab(child: Text('UPI ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Tab(child: Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TabBar View Content
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return IndexedStack(
                    index: _tabController.index,
                    children: [
                      // UPI ID View
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _upiController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'UPI ID (VPA)',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                              hintText: 'e.g. name@upi',
                              hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primary),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                            ),
                            validator: (val) {
                              if (_tabController.index != 0) return null;
                              if (val == null || val.trim().isEmpty) return 'UPI ID is required';
                              final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
                              if (!upiRegex.hasMatch(val.trim())) return 'Please enter a valid UPI format (e.g. name@okaxis)';
                              return null;
                            },
                          ),
                        ],
                      ),

                      // Bank Transfer View
                      Column(
                        children: [
                          TextFormField(
                            controller: _holderController,
                            keyboardType: TextInputType.name,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Account Holder Name',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                            ),
                            validator: (val) {
                              if (_tabController.index != 1) return null;
                              if (val == null || val.trim().isEmpty) return 'Holder name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _bankController,
                            keyboardType: TextInputType.text,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Bank Name',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.account_balance_rounded, color: AppTheme.primary),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                            ),
                            validator: (val) {
                              if (_tabController.index != 1) return null;
                              if (val == null || val.trim().isEmpty) return 'Bank name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _accountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'Account Number',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.primary),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                            ),
                            validator: (val) {
                              if (_tabController.index != 1) return null;
                              if (val == null || val.trim().isEmpty) return 'Account number is required';
                              if (val.trim().length < 9 || val.trim().length > 18) return 'Enter a valid bank account number (9 to 18 digits)';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _ifscController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: AppTheme.textColor),
                            decoration: InputDecoration(
                              labelText: 'IFSC Code',
                              labelStyle: TextStyle(color: AppTheme.textMuted),
                              hintText: 'e.g. SBIN0001234',
                              hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.domain_verification_rounded, color: AppTheme.primary),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
                            ),
                            validator: (val) {
                              if (_tabController.index != 1) return null;
                              if (val == null || val.trim().isEmpty) return 'IFSC is required';
                              final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
                              if (!ifscRegex.hasMatch(val.trim().toUpperCase())) return 'Please enter a valid IFSC code (e.g. SBIN0012345)';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.wc.isSubmitting.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.border,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: widget.wc.isSubmitting.value
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                          : const Text(
                              'Request Payout Withdrawal',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
