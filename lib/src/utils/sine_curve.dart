import 'dart:math';

import 'package:flutter/animation.dart';

class SineCurve extends Curve {
  const SineCurve({this.waves = 1});

  final int waves;

  @override
  double transformInternal(double t) {
    return -sin(waves * 2 * pi * t);
  }
}
