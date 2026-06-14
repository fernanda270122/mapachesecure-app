import 'package:flutter/material.dart';

class ResponsiveUtil {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }
}

extension ResponsiveExtension on BuildContext {
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;

  double wp(double percentage) => (width * percentage) / 100;

  double hp(double percentage) => (height * percentage) / 100;

  double sp(double size) {
    const baseWidth = 375.0;
    return size * (width / baseWidth);
  }
}

