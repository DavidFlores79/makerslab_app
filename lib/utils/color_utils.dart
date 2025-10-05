import 'package:flutter/material.dart';

Color colorFromHex(String hexColor) {
  final c = hexColor.replaceAll('#', '').trim();
  if (c.length == 6) {
    return Color(int.parse('FF$c', radix: 16));
  } else if (c.length == 8) {
    return Color(int.parse(c, radix: 16));
  } else {
    return Colors.grey;
  }
}
