
// import 'package:flutter/material.dart';
// import 'core/config/env_config.dart';
// import 'app/app.dart'; // This should contain your MaterialApp with GoRouter


// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await EnvConfig.load();
//   runApp(const MyApp());
// }

// main.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show ResourceOptions;
import 'core/config/env_config.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  runApp(const MyApp());
}