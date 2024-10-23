library pictus;

import 'package:flutter/material.dart';

enum CropRatio {
  r1_1(title: '1 : 1', ratio: 1 / 1, icon: Icons.crop_din),
  r16_9(title: '16 : 9', ratio: 16 / 9, icon: Icons.crop_16_9),
  r3_2(title: '3 : 2', ratio: 3 / 2, icon: Icons.crop_3_2),
  r5_4(title: '5 : 4', ratio: 5 / 4, icon: Icons.crop_5_4),
  r7_5(title: '7 : 5', ratio: 7 / 5, icon: Icons.crop_7_5),
  free(title: 'custom', ratio: null, icon: Icons.crop_free);

  final String title;
  final double? ratio;
  final IconData icon;

  const CropRatio({required this.title, required this.ratio, required this.icon});
}
