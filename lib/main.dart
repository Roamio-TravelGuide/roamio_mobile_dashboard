import 'package:flutter/material.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No need to load environment variables anymore - using hardcoded values
  runApp(const MyApp());
}