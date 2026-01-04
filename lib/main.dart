import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'providers/medication_provider.dart';
import 'providers/user_provider.dart';

import 'firebase_options.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize timezones and notifications early for background reliability
  tz.initializeTimeZones();
  try {
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).toString();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    debugPrint('Could not set local location: $e');
  }
  
  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await localNotificationsPlugin.initialize(initializationSettings);

  // Create high importance notification channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'medication_reminders',
    'Medication Reminders',
    description: 'Reminders to take your medication',
    importance: Importance.max,
  );
  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request notifications permission for Android 13+
  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MedsureApp(),
    ),
  );
}

class MedsureApp extends StatelessWidget {
  const MedsureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medsure',
      debugShowCheckedModeBanner: false,
      theme: MedsureTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
