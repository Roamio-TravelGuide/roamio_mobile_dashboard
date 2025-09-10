
import 'package:flutter/material.dart';
import 'core/config/env_config.dart';
import 'app/app.dart'; // This should contain your MaterialApp with GoRouter


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  runApp(const MyApp());
}
