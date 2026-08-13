/// Shimmer loading placeholder for cards and lists.
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class SidadShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SidadShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SidadShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SidadShimmerList({super.key, this.itemCount = 5, this.itemHeight = 80});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SidadShimmer(height: itemHeight),
        ),
      ),
    );
  }
}
