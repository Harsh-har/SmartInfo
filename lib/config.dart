// config.dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> loadAppConfig() async {
  final configString = await rootBundle.loadString('assets/config.json');
  return jsonDecode(configString);
}