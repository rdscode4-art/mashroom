import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:organic_grow/core/models/user_model.dart';
import 'package:organic_grow/core/services/api_services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProfileController extends GetxController {
  var isLoading = false.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  // Structured address fields from backend — used by checkout to pre-fill
  var savedHouseNo = ''.obs;
  var savedFloor = ''.obs;
  var savedBuilding = ''.obs;
  var savedArea = ''.obs;
  var savedLandmark = ''.obs;
  var savedCity = ''.obs;
  var savedState = ''.obs;
  var savedPincode = ''.obs;

  var user = User(
    id: '1',
    name: 'Ram Kumar',
    email: 'ram.kumar@example.com',
    phone: '+91 9876543210',
    address: '123 Green Street, Organic City',
    image: 'assets/user_profile.jpg',
  ).obs;

  @override
  void onInit() {
    super.onInit();
    // Auto-fetch profile on controller initialize if token is present
    if (ApiService.userToken != null) {
      fetchUserProfile().then((_) {
        fetchAndSaveCurrentLocation(); // Prompt and update location dynamically
      });
    }
  }

  /// Prompts location permissions, fetches coordinates, reverse geocodes and updates backend
  Future<void> fetchAndSaveCurrentLocation() async {
    print("📍 [Location Flow] Starting fetchAndSaveCurrentLocation...");
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("📍 [Location Flow] GPS service is disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print("📍 [Location Flow] Check permission response: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print("📍 [Location Flow] Request permission response: $permission");
        if (permission == LocationPermission.denied) {
          print("📍 [Location Flow] Permission denied by user.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("📍 [Location Flow] Permission permanently denied.");
        return;
      }

      print("📍 [Location Flow] Fetching GPS Coordinates...");
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low, // Lower accuracy fetches instantly
          timeLimit: const Duration(seconds: 5), // Keep a strict timeout of 5s
        );
      } catch (e) {
        print("📍 [Location Flow] getCurrentPosition failed/timed out, attempting last known fallback: $e");
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        print("📍 [Location Flow] Failed to retrieve coordinates from GPS.");
        return;
      }
      print("📍 [Location Flow] Coordinates obtained: Lat: ${position.latitude}, Lon: ${position.longitude}");
      latitude.value = position.latitude;
      longitude.value = position.longitude;

      print("📍 [Location Flow] Reverse Geocoding coordinates...");
      List<Placemark> placemarks;
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        print("📍 [Location Flow] Reverse geocoding failed: $e");
        placemarks = [];
      }

      String fullAddress = "";
      String city = "";
      String state = "";
      String pincode = "";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        city = place.locality ?? '';
        state = place.administrativeArea ?? '';
        pincode = place.postalCode ?? '';
        
        List<String> addressParts = [];
        if (place.name != null && place.name!.isNotEmpty) addressParts.add(place.name!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        fullAddress = addressParts.join(', ');
      } else {
        fullAddress = "Lat: ${position.latitude}, Lon: ${position.longitude}";
      }
      print("📍 [Location Flow] Address constructed: $fullAddress");

      print("📍 [Location Flow] Syncing location to backend via ApiService...");
      final response = await ApiService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fullAddress: fullAddress,
        city: city,
        state: state,
        pincode: pincode,
      );

      print("📍 [Location Flow] Backend API Response: $response");
      if (response['success'] == true) {
        print("📍 [Location Flow] Success! Syncing ProfileController user state...");
        await fetchUserProfile();
      }
    } catch (e) {
      print("📍 [Location Flow] UNCAUGHT ERROR: $e");
    }
  }

  /// Fetches authenticated user profile from backend using ApiService
  Future<void> fetchUserProfile() async {
    print("📍 [Location Flow] fetchUserProfile started...");
    try {
      isLoading.value = true;
      final response = await ApiService.fetchProfile();
      print("📍 [Location Flow] fetchUserProfile API Response: $response");
      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'];
        
        // Safely parse the nested address object from backend response
        String addressString = 'No Address Set';
        final addressData = userData['address'];
        print("📍 [Location Flow] Raw addressData from DB: $addressData");
        if (addressData != null && addressData is Map) {
          double parsedLat = 0.0;
          double parsedLng = 0.0;
          final locationData = addressData['location'];
          if (locationData != null && locationData is Map) {
            parsedLat = (locationData['latitude'] as num?)?.toDouble() ?? 0.0;
            parsedLng = (locationData['longitude'] as num?)?.toDouble() ?? 0.0;
          }
          latitude.value = parsedLat;
          longitude.value = parsedLng;

          // Store structured fields for checkout pre-fill
          savedHouseNo.value = addressData['houseNo']?.toString() ?? '';
          savedFloor.value = addressData['floor']?.toString() ?? '';
          savedBuilding.value = addressData['building']?.toString() ?? '';
          savedArea.value = addressData['area']?.toString() ?? '';
          savedLandmark.value = addressData['landmark']?.toString() ?? '';
          savedCity.value = addressData['city']?.toString() ?? '';
          savedState.value = addressData['state']?.toString() ?? '';
          savedPincode.value = addressData['pincode']?.toString() ?? '';

          final fullAddr = addressData['fullAddress'] ?? '';
          final city = addressData['city'] ?? '';
          final stateStr = addressData['state'] ?? '';
          final pincode = addressData['pincode'] ?? '';
          
          List<String> parts = [];
          if (fullAddr.toString().trim().isNotEmpty) parts.add(fullAddr.toString().trim());
          if (city.toString().trim().isNotEmpty) parts.add(city.toString().trim());
          if (stateStr.toString().trim().isNotEmpty) parts.add(stateStr.toString().trim());
          if (pincode.toString().trim().isNotEmpty) parts.add(pincode.toString().trim());
          
          if (parts.isNotEmpty) {
            addressString = parts.join(', ');
          }
        } else if (addressData != null && addressData is String && addressData.trim().isNotEmpty) {
          addressString = addressData;
        }
        print("📍 [Location Flow] Parsed addressString: $addressString");

        String imagePath = (userData['profileImage'] != null && userData['profileImage'].toString().trim().isNotEmpty) 
            ? userData['profileImage'].toString() 
            : 'assets/user_profile.jpg';
        
        if (imagePath.isNotEmpty && !imagePath.startsWith('http') && !imagePath.startsWith('assets/')) {
          // Normalize backslashes (Windows) to forward slashes
          imagePath = imagePath.replaceAll('\\', '/');
          imagePath = '${ApiService.imageBaseUrl}$imagePath';
        }

        // Map backend User schema onto core/models/user_model
        final mappedUser = User(
          id: userData['_id'] ?? '',
          name: (userData['name'] != null && userData['name'].toString().trim().isNotEmpty) 
              ? userData['name'].toString() 
              : 'Guest User',
          email: (userData['email'] != null && userData['email'].toString().trim().isNotEmpty) 
              ? userData['email'].toString() 
              : 'no-email@organicgrow.com',
          phone: userData['phone']?.toString() ?? '',
          address: addressString,
          image: imagePath,
          role: userData['role'] ?? 'customer',
        );

        print("📍 [Location Flow] Setting user reactive value to: ${mappedUser.toJson()}");
        user.value = mappedUser;
      }
    } catch (e, stack) {
      print("📍 [Location Flow] ERROR inside fetchUserProfile: $e\n$stack");
    } finally {
      isLoading.value = false;
    }
  }

  void updateUser(User newUser) {
    user.value = newUser;
  }

  /// Persists profile changes (name, email) to backend via API
  Future<void> updateProfile(String name, String email) async {
    try {
      isLoading.value = true;
      final response = await ApiService.updateProfile(name: name, email: email);
      if (response['success'] == true) {
        // Refresh local state from backend
        await fetchUserProfile();
      }
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      rethrow; // Let the screen handle it for snackbar
    } finally {
      isLoading.value = false;
    }
  }

  /// Uploads a profile photo and refreshes user state
  Future<void> uploadProfilePhoto(String filePath) async {
    try {
      isLoading.value = true;
      final response = await ApiService.uploadProfilePhoto(filePath);
      if (response['success'] == true) {
        await fetchUserProfile();
      }
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}