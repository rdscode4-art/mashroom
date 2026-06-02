import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WalletController extends GetxController {
  var balance = 0.0.obs;
  var totalEarnings = 0.0.obs;
  var transactions = <dynamic>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWalletHistory();
  }

  Future<void> fetchWalletHistory() async {
    try {
      isLoading.value = true;
      final res = await ApiService.getWalletHistory();
      if (res['success'] == true) {
        balance.value = (res['balance'] as num?)?.toDouble() ?? 0.0;
        transactions.value = res['transactions'] as List<dynamic>? ?? [];
        
        // Calculate total earnings from transactions (all positive type=='earning')
        double total = 0.0;
        for (var tx in transactions) {
          if (tx['type'] == 'earning') {
            total += (tx['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }
        totalEarnings.value = total;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load wallet data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitWithdrawal({
    required double amount,
    required String method,
    String? upiId,
    Map<String, dynamic>? bankDetails,
  }) async {
    if (amount < 100) {
      Get.snackbar(
        'Invalid Amount',
        'Minimum payout amount is ₹100',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    if (amount > balance.value) {
      Get.snackbar(
        'Insufficient Funds',
        'Requested amount exceeds available balance',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isSubmitting.value = true;
      final res = await ApiService.requestWithdrawal(
        amount: amount,
        method: method,
        upiId: upiId,
        bankDetails: bankDetails,
      );

      if (res['success'] == true) {
        Get.snackbar(
          'Success',
          res['message'] ?? 'Withdrawal request submitted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchWalletHistory();
        return true;
      } else {
        Get.snackbar(
          'Failed',
          res['message'] ?? 'Withdrawal request failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
