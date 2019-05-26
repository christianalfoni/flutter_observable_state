import 'package:flutter/material.dart';
import './services.dart' as services;
import './App.dart';

void main() {
  services.initialize();

  runApp(App());
}
