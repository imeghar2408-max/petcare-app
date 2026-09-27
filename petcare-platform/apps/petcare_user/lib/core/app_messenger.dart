import 'package:flutter/material.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppSnackBar(String text) {
  rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
}
