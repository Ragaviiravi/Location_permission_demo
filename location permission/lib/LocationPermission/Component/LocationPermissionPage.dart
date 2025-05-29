import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controller/location_controller.dart';

class LocationPermissionPage extends StatelessWidget {
  const LocationPermissionPage({super.key});

  Future<void> _confirmStartLocationUpdates(BuildContext context, LocationController controller) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Location Updates?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Do you want to start receiving location updates every 30 seconds?',
          style: TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('YES'),
          ),
        ],
      ),
    );

    if (result == true) {
      controller.startLocationUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocationController(),
      child: Consumer<LocationController>(
        builder: (context, controller, _) {
          final screenWidth = MediaQuery.of(context).size.width;

          return Scaffold(

            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Container(
                    color: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Test App',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Request Location Permission
                        ElevatedButton(
                          onPressed: () => controller.requestLocationPermission(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF), // Blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Request Location Permission'),
                        ),

                        const SizedBox(height: 20),


                        ElevatedButton(
                          onPressed: () => controller.requestNotificationPermission(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFCC00), // Yellow
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Request Notification Permission'),
                        ),

                        const SizedBox(height: 20),


                        ElevatedButton(
                          onPressed: () => _confirmStartLocationUpdates(context, controller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34C759), // Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Start Location Update'),
                        ),

                        const SizedBox(height: 20),


                        ElevatedButton(
                          onPressed: () {
                            if (controller.updatingLocation) {
                              controller.stopLocationUpdates();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Location updates are not active')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30), // Red
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Stop Location Update'),
                        ),

                      ],
                    ),
                  ),

                  // Bottom white section
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Live Location:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          color: Colors.blue.shade50,
                          child: ListTile(
                            title: const Text('Latest Location Data'),
                            subtitle: Text(
                              controller.currentPosition != null
                                  ? 'Lat: ${controller.currentPosition!.latitude.toStringAsFixed(3)} | '
                                  'Lng: ${controller.currentPosition!.longitude.toStringAsFixed(3)} | '
                                  'Speed: ${controller.currentPosition!.speed.toStringAsFixed(1)} m/s'
                                  : 'No location data available',
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (controller.locationLogs.isNotEmpty) ...[
                          const Text(
                            'Location Logs:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...controller.locationLogs.map(
                                (log) => Card(
                              color: Colors.grey.shade200,
                              child: ListTile(
                                title: Text(log.requestId),
                                subtitle: Text(
                                  'Lat: ${log.lat.toStringAsFixed(3)} | '
                                      'Lng: ${log.lng.toStringAsFixed(3)} | '
                                      'Speed: ${log.speed.toStringAsFixed(3)} m/s',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          );
        },
      ),
    );
  }
}
