library pictus;

import 'package:flutter/material.dart';

enum CropRatio {
  free(title: 'Custom', ratio: null, icon: Icons.crop_free),
  r1_1(title: '1 : 1', ratio: 1 / 1, icon: Icons.crop_din),
  r16_9(title: '16 : 9', ratio: 16 / 9, icon: Icons.crop_16_9),
  r3_2(title: '3 : 2', ratio: 3 / 2, icon: Icons.crop_3_2),
  r4_3(title: '4 : 3', ratio: 4 / 3, icon: Icons.crop_5_4);

  final String title;
  final double? ratio;
  final IconData icon;

  const CropRatio({required this.title, required this.ratio, required this.icon});
}
