import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/app.dart';
import 'package:recicla_radar_sp/core/map/sp_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SpMap.configureTileCache();
  final prefs = await SharedPreferences.getInstance();
  runApp(ReciclaRadarApp(prefs: prefs));
}
