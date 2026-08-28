import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/bookings/presentation/bookings_provider.dart';
import 'features/destinations/presentation/spots_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => BookingsProvider()),
      ],
      child: const TourismApp(),
    ),
  );
}
