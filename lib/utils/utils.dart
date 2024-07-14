import 'package:flutter/material.dart';

class Utils {
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Learning':
        return Colors.blue;
      case 'Working':
        return Colors.cyan;
      case 'General':
        return Colors.green;
      case 'Other':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
