import 'package:flutter/material.dart';

class Utils {
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Learning':
        return Colors.blue;
      case 'Working':
        return Colors.red;
      case 'General':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
