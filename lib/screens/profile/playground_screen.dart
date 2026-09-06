import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../services/safety_location_service.dart';
import '../../services/news_service.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../utils/app_haptics.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _setMockLocation() async {
    final query = _locationController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      if (query.contains(',') && double.tryParse(query.split(',')[0].trim()) != null) {
        final parts = query.split(',');
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        
        SafetyLocationService.instance.enableMockLocation(lat, lng);
        await NewsService.instance.fetchLocalNews(forceRefresh: true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mock location set to $lat, $lng')),
          );
        }
      } else {
        List<geo.Location> locations = await geo.Geocoding().locationFromAddress(query);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          SafetyLocationService.instance.enableMockLocation(loc.latitude, loc.longitude, locationName: query);
          await NewsService.instance.fetchLocalNews(forceRefresh: true, customCityHint: query);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mock location set to ${loc.latitude}, ${loc.longitude}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not resolve location: $query')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearMockLocation() {
    AppHaptics.cardTap();
    SafetyLocationService.instance.disableMockLocation();
    NewsService.instance.fetchLocalNews(forceRefresh: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mock location cleared. Resuming GPS tracking.')),
    );
    setState(() {}); // refresh UI to hide active banner
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            AppHaptics.cardTap();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Developer Playground',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mock Location Services',
                style: TextStyle(
                  color: const Color(0xFFD9779F),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Enter an area name, pincode, or precise "lat, lng" coordinates to spoof the device telemetry. This will update the Map and News streams globally.',
                style: TextStyle(
                  color: const Color(0xFF908A99),
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 32.h),
              
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14081B),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFD9779F).withValues(alpha: 0.3)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                child: TextField(
                  controller: _locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'e.g. Times Square, NY or 40.7, -73.9',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    icon: Icon(Icons.travel_explore_rounded, color: const Color(0xFFD9779F)),
                  ),
                  onSubmitted: (_) => _setMockLocation(),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              Row(
                children: [
                  Expanded(
                    child: LiquidGlassContainer(
                      onTap: _isLoading ? null : () {
                        AppHaptics.cardTap();
                        _setMockLocation();
                      },
                      borderRadius: 16,
                      tintColor: const Color(0xFFD9779F),
                      tintOpacity: 0.25,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: _isLoading 
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Set Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  LiquidGlassContainer(
                    onTap: _clearMockLocation,
                    borderRadius: 16,
                    tintColor: Colors.white,
                    tintOpacity: 0.1,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Center(
                      child: Icon(Icons.location_off_rounded, color: Colors.white, size: 22.sp),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 48.h),
              
              if (SafetyLocationService.instance.isMockingLocation)
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'MOCK LOCATION ACTIVE\nDevice telemetry is currently spoofed.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
