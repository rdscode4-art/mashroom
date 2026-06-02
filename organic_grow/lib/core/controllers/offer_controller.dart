import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/models/offer_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class OfferController extends GetxController {
  var isLoading = false.obs;
  var offers = <Offer>[].obs;

  // Keep legacy single-offer accessor for any code that still uses it
  Offer? get currentOffer => offers.isNotEmpty ? offers.first : null;

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    try {
      isLoading.value = true;
      final list = await ApiService.fetchOffers();
      offers.assignAll(list);
    } catch (e) {
      debugPrint('Failed to fetch offers: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
