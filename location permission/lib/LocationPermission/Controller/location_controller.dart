import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationLog {
  final String requestId;
  final double lat;
  final double lng;
  final double speed;

  LocationLog({
    required this.requestId,
    required this.lat,
    required this.lng,
    required this.speed,
  });
}

class LocationController extends ChangeNotifier {
  Position? currentPosition;
  List<LocationLog> locationLogs = [];
  bool updatingLocation = false;
  Timer? _timer;
  int _requestCounter = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  LocationController() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'location_channel',
      'Location Updates',
      channelDescription: 'Shows notifications for location updates',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> requestLocationPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission granted.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
    }
  }

  Future<void> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permission granted.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification permission denied.')));
    }
  }

  Future<void> startLocationUpdates() async {
    updatingLocation = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _getLocation();
    });

    await _getLocation(); // Get the first location immediately
  }

  Future<void> _getLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    currentPosition = position;

    _requestCounter++; // Increment the request number

    final log = LocationLog(
      requestId: 'Request $_requestCounter',
      lat: position.latitude,
      lng: position.longitude,
      speed: position.speed,
    );

    locationLogs.insert(0, log);

    notifyListeners();

    await showNotification("Location Update", "Lat: ${log.lat}, Lng: ${log.lng}");
  }

  void stopLocationUpdates() {
    _timer?.cancel();
    updatingLocation = false;
    notifyListeners();
  }
}
