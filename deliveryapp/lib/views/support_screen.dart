import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../core/services/api_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageCtrl = TextEditingController();
  String _selectedSubject = 'Order Delivery Delay';
  bool _isSubmitting = false;
  bool _isLoadingTickets = true;
  String _supportPhone = '1800-123-4567'; // Default fallback support helpline

  List<dynamic> _pastTickets = [];

  final List<String> _subjects = [
    'Order Delivery Delay',
    'Wallet / Earning Settlement',
    'Address Unreachable / Customer Issues',
    'App Bug / GPS Issues',
    'Other General Queries',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndTickets();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndTickets() async {
    setState(() => _isLoadingTickets = true);
    try {
      // 1. Load active system support number from settings
      final settingsRes = await ApiService.fetchSettings();
      if (settingsRes['success'] == true && settingsRes['settings'] != null) {
        final sNum = settingsRes['settings']['supportNumber'] as String?;
        if (sNum != null && sNum.trim().isNotEmpty) {
          setState(() {
            _supportPhone = sNum.trim();
          });
        }
      }
    } catch (_) {}

    try {
      // 2. Fetch partner's raised support tickets
      final tickets = await ApiService.getSupportTickets();
      setState(() {
        _pastTickets = tickets;
      });
    } catch (_) {} finally {
      setState(() => _isLoadingTickets = false);
    }
  }

  Future<void> _callHelpline() async {
    final cleanPhone = _supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not place a call to $_supportPhone',
          backgroundColor: AppTheme.danger,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Helpline call failed.',
          backgroundColor: AppTheme.danger, colorText: Colors.white);
    }
  }

  Future<void> _submitTicket() async {
    if (_messageCtrl.text.trim().isEmpty) {
      Get.snackbar('Message Required', 'Please enter a description for your issue.',
          backgroundColor: AppTheme.accent, colorText: Colors.black);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.submitSupportTicket(
        subject: _selectedSubject,
        message: _messageCtrl.text.trim(),
      );

      if (res['success'] == true) {
        Get.snackbar('Ticket Submitted ✅', 'Our support team will review your query shortly.',
            backgroundColor: AppTheme.primary, colorText: Colors.white);
        _messageCtrl.clear();
        // Refresh list
        _loadSettingsAndTickets();
      }
    } catch (e) {
      Get.snackbar('Submission Failed', e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: AppTheme.danger, colorText: Colors.white);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Partner Support', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [
              Tab(icon: Icon(Icons.help_rounded), text: 'Help & Raise Ticket'),
              Tab(icon: Icon(Icons.history_edu_rounded), text: 'My Support History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Form, FAQ, Helpline
            _buildRaiseTicketTab(context),

            // Tab 2: Past tickets list
            _buildHistoryTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRaiseTicketTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 1. Helpline Call Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Direct Manager Helpline',
                      style: TextStyle(color: AppTheme.textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(_supportPhone,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _callHelpline,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Call Now'),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // 2. Raise Ticket Heading
        Text('Raise a Support Ticket',
            style: TextStyle(color: AppTheme.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
        Text('Having issues? Describe them to get a quick resolution.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 14),

        // 3. Dropdown Subject Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              style: TextStyle(color: AppTheme.textColor, fontSize: 14),
              items: _subjects.map((String sub) {
                return DropdownMenuItem<String>(
                  value: sub,
                  child: Text(sub),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSubject = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4. Message TextField
        TextField(
          controller: _messageCtrl,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter details of the issue (e.g. Order pickup is taking longer at the store, customer address is wrong...)',
            hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 13),
            filled: true,
            fillColor: AppTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Submit Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Submit Ticket',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 32),

        // 6. Partner FAQs section
        Text('Frequently Asked Questions (FAQ)',
            style: TextStyle(color: AppTheme.textColor, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildFaqTile(
          question: 'How do I withdraw my earnings?',
          answer: 'Go to the Wallet screen, enter the desired withdrawal amount, select your payment method (UPI or Bank), and request withdrawal. Withdrawals are processed within 24 hours.',
        ),
        _buildFaqTile(
          question: 'What if the store is closed or pickup is delayed?',
          answer: 'Please raise a support ticket under "Order Delivery Delay" with the store name and delay details. Our operations manager will check and adjust your delivery SLA.',
        ),
        _buildFaqTile(
          question: 'What to do if the customer is unreachable?',
          answer: 'Attempt to call the customer at least twice. If they do not respond, call support or raise a ticket under "Address Unreachable" before leaving the delivery location.',
        ),
      ]),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    if (_isLoadingTickets) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_pastTickets.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.history_toggle_off_rounded, color: AppTheme.textMuted.withValues(alpha: 0.4), size: 64),
          const SizedBox(height: 12),
          Text('No support tickets raised yet.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _loadSettingsAndTickets,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: _pastTickets.length,
        itemBuilder: (context, index) {
          final t = _pastTickets[index];
          final subject = t['subject'] ?? 'Help Request';
          final message = t['message'] ?? '';
          final status = t['status'] ?? 'open';
          final dateStr = t['createdAt'] != null 
              ? DateTime.parse(t['createdAt'] as String).toLocal().toString().substring(0, 16)
              : '';

          Color statusColor = Colors.orange;
          if (status == 'closed') statusColor = Colors.green;
          if (status == 'pending') statusColor = Colors.amber;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Text(subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(message,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 0.6),
                const SizedBox(height: 8),
                Text(dateStr, style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        title: Text(question,
            style: TextStyle(color: AppTheme.textColor, fontSize: 14, fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        textColor: AppTheme.primary,
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textMuted,
        children: [
          Text(answer,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
