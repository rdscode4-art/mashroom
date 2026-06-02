import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../core/controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController auth = Get.find();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo / Header
              Center(
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: AppTheme.primary, size: 56),
                  ),
                  const SizedBox(height: 20),
                  Text('RiFresh Delivery',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.textColor)),
                  const SizedBox(height: 6),
                  Text('Delivery Partner Portal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted)),
                ]),
              ),
              const SizedBox(height: 48),

              if (!_otpSent) ...[
                Text('Phone Number',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  style: TextStyle(color: AppTheme.textColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '10-digit mobile number',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.primary),
                    filled: true,
                    fillColor: AppTheme.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.8)),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading.value ? null : () async {
                      if (_phoneCtrl.text.length < 10) return;
                      try {
                        await auth.sendOtp(_phoneCtrl.text);
                        setState(() => _otpSent = true);
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isLoading.value
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )),
              ] else ...[
                Text('Enter OTP sent to ${_phoneCtrl.text}',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 20),
                Center(
                  child: Pinput(
                    controller: _otpCtrl,
                    length: 4,
                    defaultPinTheme: PinTheme(
                      width: 60, height: 60,
                      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 60, height: 60,
                      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: const Border.fromBorderSide(BorderSide(color: AppTheme.primary, width: 2)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading.value ? null : () async {
                      if (_otpCtrl.text.length < 4) return;
                      try {
                        await auth.verifyOtp(_phoneCtrl.text, _otpCtrl.text);
                      } catch (_) {}
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: auth.isLoading.value
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify & Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                    child: Text('Change Number', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
