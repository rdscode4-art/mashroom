import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:organic_grow/config/app_color.dart';
import 'package:organic_grow/config/app_typography.dart';
import 'package:organic_grow/core/controllers/checkout_controller.dart';
import 'package:organic_grow/core/controllers/profile_controller.dart';
import 'package:organic_grow/core/models/user_model.dart';
import 'package:organic_grow/core/services/api_services.dart';

class AddAddressWithMapScreen extends StatefulWidget {
  const AddAddressWithMapScreen({super.key, required this.cc, this.addressToEdit});

  final CheckoutController cc;
  final SavedAddress? addressToEdit; // If editing an existing address

  @override
  State<AddAddressWithMapScreen> createState() => _AddAddressWithMapScreenState();
}

class _AddAddressWithMapScreenState extends State<AddAddressWithMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentLatLng = const LatLng(20.2961, 85.8245); // Default: Bhubaneswar, India
  bool _isSearching = false;
  bool _isLocating = false;
  bool _isCameraMoving = false; // Tracks map drag state for pin lift animation

  // Controllers
  final _searchCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

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
  void initState() {
    super.initState();
    // Prefill form if editing
    if (widget.addressToEdit != null) {
      final addr = widget.addressToEdit!;
      _houseCtrl.text = addr.houseNo;
      _floorCtrl.text = addr.floor;
      _buildingCtrl.text = addr.building;
      _areaCtrl.text = addr.area;
      _landmarkCtrl.text = addr.landmark;
      _cityCtrl.text = addr.city;
      _stateCtrl.text = addr.state;
      _pincodeCtrl.text = addr.pincode;
      _addressType = addr.addressType;
      _currentLatLng = LatLng(addr.latitude, addr.longitude);
      _latCtrl.text = addr.latitude.toString();
      _lngCtrl.text = addr.longitude.toString();
    } else {
      _latCtrl.text = _currentLatLng.latitude.toString();
      _lngCtrl.text = _currentLatLng.longitude.toString();
      // Try to center on user's current GPS location immediately
      _moveToCurrentLocation();
    }

    // Attach listeners for manual coordinate editing
    _latCtrl.addListener(_onManualCoordinateChange);
    _lngCtrl.addListener(_onManualCoordinateChange);
  }

  @override
  void dispose() {
    _latCtrl.removeListener(_onManualCoordinateChange);
    _lngCtrl.removeListener(_onManualCoordinateChange);

    _searchCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _houseCtrl.dispose();
    _floorCtrl.dispose();
    _buildingCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Prevent recursive triggers when coordinates are changed from map vs keyboard
  bool _isCoordinatesUpdating = false;

  void _onManualCoordinateChange() {
    if (_isCoordinatesUpdating) return;
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat != null && lng != null) {
      if (lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0) {
        _isCoordinatesUpdating = true;
        _currentLatLng = LatLng(lat, lng);
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLatLng));
        _reverseGeocode(_currentLatLng, updateCoordsInUI: false);
        _isCoordinatesUpdating = false;
      }
    }
  }

  /// Center map on user's active GPS coordinate
  Future<void> _moveToCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLatLng = newLatLng;
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      _reverseGeocode(newLatLng);
    } catch (e) {
      Get.snackbar(
        "Location Error",
        e.toString().replaceAll("Exception: ", ""),
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  /// Geocodes address text search and pans the map camera to search result
  Future<void> _searchAndFlyToAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        
        setState(() {
          _currentLatLng = target;
          _isCoordinatesUpdating = true;
          _latCtrl.text = target.latitude.toStringAsFixed(6);
          _lngCtrl.text = target.longitude.toStringAsFixed(6);
          _isCoordinatesUpdating = false;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
        _reverseGeocode(target);
        FocusScope.of(context).unfocus();
      } else {
        throw Exception("No location matches found.");
      }
    } catch (e) {
      Get.snackbar(
        "Search Failed",
        "Could not resolve searched location. Pin it manually on the map.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// Reverse geocodes coordinates to fill manual address forms
  Future<void> _reverseGeocode(LatLng coordinates, {bool updateCoordsInUI = true}) async {
    try {
      final placemarks = await placemarkFromCoordinates(coordinates.latitude, coordinates.longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        
        setState(() {
          if (updateCoordsInUI) {
            _isCoordinatesUpdating = true;
            _latCtrl.text = coordinates.latitude.toStringAsFixed(6);
            _lngCtrl.text = coordinates.longitude.toStringAsFixed(6);
            _isCoordinatesUpdating = false;
          }

          // Build a readable area name from localized components
          final street = pm.street ?? '';
          final subLocality = pm.subLocality ?? '';
          final locality = pm.locality ?? '';
          
          final areaList = <String>[];
          if (street.isNotEmpty && !street.contains('+') && street != pm.name) areaList.add(street);
          if (subLocality.isNotEmpty) areaList.add(subLocality);
          if (locality.isNotEmpty && locality != subLocality) areaList.add(locality);

          _areaCtrl.text = areaList.join(", ");
          
          _cityCtrl.text = pm.subAdministrativeArea?.isNotEmpty == true 
              ? pm.subAdministrativeArea! 
              : (pm.locality?.isNotEmpty == true ? pm.locality! : '');
              
          _stateCtrl.text = pm.administrativeArea ?? '';
          _pincodeCtrl.text = pm.postalCode ?? '';
        });
      }
    } catch (_) {
      // Platform geocoder rate limit or offline. Let user enter details manually.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.addressToEdit == null ? 'Add Address' : 'Edit Address',
            style: AppTypography.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Map Panel with Floating Search Bar Overlay and Floating Center Pin
            Text('Locate on Map',
                style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold, color: AppColor.textColor)),
            const SizedBox(height: 8),
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Native Google Map with EagerGestureRecognizer
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLatLng,
                        zoom: 15,
                      ),
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      }.toSet(),
                      onMapCreated: (ctrl) {
                        _mapController = ctrl;
                        _reverseGeocode(_currentLatLng);
                      },
                      onCameraMoveStarted: () {
                        // Trigger pin lift animation in real-time when panning starts
                        setState(() {
                          _isCameraMoving = true;
                        });
                      },
                      onCameraMove: (pos) {
                        _currentLatLng = pos.target;
                      },
                      onCameraIdle: () {
                        // Drop center pin and reverse-geocode when camera stops moving
                        setState(() {
                          _isCameraMoving = false;
                          _isCoordinatesUpdating = true;
                          _latCtrl.text = _currentLatLng.latitude.toStringAsFixed(6);
                          _lngCtrl.text = _currentLatLng.longitude.toStringAsFixed(6);
                          _isCoordinatesUpdating = false;
                        });
                        _reverseGeocode(_currentLatLng);
                      },
                      onTap: (pos) {
                        // Smoothly center the map under the pin when tapped
                        _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
                      },
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                    ),

                    // Premium Floating Center Pin with lift & drop animation
                    IgnorePointer(
                      child: Center(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(bottom: _isCameraMoving ? 52 : 36),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_pin,
                                color: AppColor.primaryColor,
                                size: 48,
                              ),
                              // Interactive shadow underneath
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: _isCameraMoving ? 14 : 6,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: _isCameraMoving ? 8 : 2,
                                      spreadRadius: _isCameraMoving ? 4 : 1,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Floating Autocomplete Search Bar Overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search place / area...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColor.primaryColor, size: 20),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primaryColor)),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColor.primaryColor, size: 20),
                                    onPressed: () => _searchAndFlyToAddress(_searchCtrl.text),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _searchAndFlyToAddress,
                        ),
                      ),
                    ),
                    
                    // Floating Current Location Recenter Button
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        heroTag: "recenter_location",
                        onPressed: _moveToCurrentLocation,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColor.primaryColor,
                        child: _isLocating 
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: AppColor.primaryColor,
                                    strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Note: Coordinate fields are completely removed from visible UI as requested, 
            // but still maintained in backend/controllers for saving.

            const Divider(thickness: 1.2),
            const SizedBox(height: 12),

            // 2. Structured Address Fields (Manual Details)
            Text('Address Type',
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold, color: AppColor.textColor.withValues(alpha: 0.8))),
            const SizedBox(height: 8),
            Row(
              children: ['home', 'work', 'other'].map((t) {
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
              }).toList(),
            ),
            const SizedBox(height: 16),

            // House No & Floor
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(
                    ctrl: _houseCtrl,
                    label: 'House / Flat No. *',
                    hint: 'e.g. 42B, Flat 301',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    ctrl: _floorCtrl,
                    label: 'Floor',
                    hint: 'e.g. 3rd',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildField(
              ctrl: _buildingCtrl,
              label: 'Building / Society',
              hint: 'e.g. Green Valley Apts',
            ),
            const SizedBox(height: 12),

            _buildField(
              ctrl: _areaCtrl,
              label: 'Area / Street / Sector',
              hint: 'e.g. MG Road, Sector 14',
            ),
            const SizedBox(height: 12),

            _buildField(
              ctrl: _landmarkCtrl,
              label: 'Landmark (Optional)',
              hint: 'e.g. Near City Mall',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    ctrl: _cityCtrl,
                    label: 'City *',
                    hint: 'e.g. Bhubaneswar',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    ctrl: _stateCtrl,
                    label: 'State',
                    hint: 'e.g. Odisha',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildField(
              ctrl: _pincodeCtrl,
              label: 'Pincode *',
              hint: '6-digit pincode',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 30),

            // Save address button
            Obx(() => SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.cc.isSavingAddress.value
                    ? null
                    : () async {
                        final latVal = double.tryParse(_latCtrl.text) ?? 0.0;
                        final lngVal = double.tryParse(_lngCtrl.text) ?? 0.0;
                        final ok = await widget.cc.saveNewAddress(
                          houseNo: _houseCtrl.text,
                          floor: _floorCtrl.text,
                          building: _buildingCtrl.text,
                          area: _areaCtrl.text,
                          landmark: _landmarkCtrl.text,
                          city: _cityCtrl.text,
                          state: _stateCtrl.text,
                          pincode: _pincodeCtrl.text,
                          addressType: _addressType,
                          latitude: latVal,
                          longitude: lngVal,
                          addressId: widget.addressToEdit?.id,
                        );
                        if (ok) {
                          // Automatically set this newly saved address as the active coordinates
                          final pc = Get.isRegistered<ProfileController>()
                              ? Get.find<ProfileController>()
                              : Get.put(ProfileController());
                          
                          // Format address string
                          List<String> parts = [];
                          if (_houseCtrl.text.isNotEmpty) parts.add(_houseCtrl.text);
                          if (_buildingCtrl.text.isNotEmpty) parts.add(_buildingCtrl.text);
                          if (_areaCtrl.text.isNotEmpty) parts.add(_areaCtrl.text);
                          if (_cityCtrl.text.isNotEmpty) parts.add(_cityCtrl.text);
                          if (_pincodeCtrl.text.isNotEmpty) parts.add(_pincodeCtrl.text);
                          final fullAddr = parts.isEmpty ? 'New Address' : parts.join(", ");
                          
                          pc.latitude.value = latVal;
                          pc.longitude.value = lngVal;
                          
                          // Update active address on the home screen header
                          final updatedUser = pc.user.value;
                          pc.user.value = User(
                            id: updatedUser.id,
                            name: updatedUser.name,
                            email: updatedUser.email,
                            phone: updatedUser.phone,
                            address: fullAddr,
                            image: updatedUser.image,
                            role: updatedUser.role,
                          );
                          
                          // Sync coordinate update to user's active backend location
                          await ApiService.updateLocation(
                            latitude: latVal,
                            longitude: lngVal,
                            fullAddress: fullAddr,
                            city: _cityCtrl.text,
                            state: _stateCtrl.text,
                            pincode: _pincodeCtrl.text,
                          );
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: widget.cc.isSavingAddress.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        widget.addressToEdit == null ? 'Save Address' : 'Update Address',
                        style: AppTypography.buttonMedium.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // Textfield Builder Helper
  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600, color: AppColor.textColor.withValues(alpha: 0.8))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTypography.bodyMedium.copyWith(color: AppColor.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
