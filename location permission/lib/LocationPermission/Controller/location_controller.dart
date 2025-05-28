import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationLog {
  final String requestId;
  final double lat;
  final double lng;
  final double speed;

  LocationLog(this.requestId, this.lat, this.lng, this.speed);

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'lat': lat,
    'lng': lng,
    'speed': speed,
  };

  static LocationLog fromJson(Map<String, dynamic> json) => LocationLog(
    json['requestId'],
    json['lat'],
    json['lng'],
    json['speed'],
  );
}

class LocationController extends ChangeNotifier {
  Position? currentPosition;
  List<LocationLog> locationLogs = [];
  bool updatingLocation = false;
  Timer? _timer;
  late FlutterLocalNotificationsPlugin _localNotifications;
  int _requestCounter = 0;

  double? _lastLat;
  double? _lastLng;

  LocationController() {
    _initNotifications();
    _loadSavedLocations();
  }

  Future<void> _initNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _showNotification(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Updates',
      channelDescription: 'Notifications for location updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      0,
      'Location Update',
      message,
      platformDetails,
    );
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('location_logs') ?? [];
    _requestCounter = prefs.getInt('request_counter') ?? 0;

    locationLogs = saved.map((s) {
      final Map<String, dynamic> json = Map<String, dynamic>.from(
        (Uri.parse(s).queryParameters).map(
              (k, v) => MapEntry(k, double.tryParse(v) ?? v),
        ),
      );
      return LocationLog.fromJson(json);
    }).toList();

    notifyListeners();
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = locationLogs.map((log) {
      final json = log.toJson().map((k, v) => MapEntry(k, v.toString()));
      return Uri(queryParameters: json).toString();
    }).toList();
    await prefs.setStringList('location_logs', saved);
    await prefs.setInt('request_counter', _requestCounter);
  }

  Future<void> _updateLocation() async {
    try {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Skip update if location change is < 5 meters
      if (_lastLat != null && _lastLng != null) {
        final distance = Geolocator.distanceBetween(
          _lastLat!,
          _lastLng!,
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        if (distance < 5) return;
      }

      _lastLat = currentPosition!.latitude;
      _lastLng = currentPosition!.longitude;

      _requestCounter++;

      final log = LocationLog(
        'request$_requestCounter',
        currentPosition!.latitude,
        currentPosition!.longitude,
        currentPosition!.speed,
      );

      locationLogs.insert(0, log); // latest first
      await _saveLocations();
      notifyListeners();

      // Show location update notification
      await _showNotification(
        'request$_requestCounter: Lat ${log.lat.toStringAsFixed(4)}, '
            'Lng ${log.lng.toStringAsFixed(4)}, Speed ${log.speed.toStringAsFixed(2)}',
      );
    } catch (e) {
      await _showNotification('Location update failed: $e');
    }
  }

  void startLocationUpdates() {
    if (updatingLocation) return;
    updatingLocation = true;
    notifyListeners();

    _showNotification('Location updates started');
    _updateLocation();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _updateLocation();
    });
  }

  void stopLocationUpdates() {
    if (!updatingLocation) return;
    _timer?.cancel();
    updatingLocation = false;
    notifyListeners();
    _showNotification('Location updates stopped');
  }

  Future<void> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final snackBar = SnackBar(
      content: Text(
        permission == LocationPermission.always || permission == LocationPermission.whileInUse
            ? 'Location permission granted'
            : 'Location permission denied',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    final snackBar = SnackBar(
      content: const Text('Notification permission (Android handled by default)'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
