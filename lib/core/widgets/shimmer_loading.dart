import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
      highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerLoading(width: 100, height: 100, borderRadius: 50),
          SizedBox(height: 16),
          ShimmerLoading(width: 150, height: 20),
          SizedBox(height: 8),
          ShimmerLoading(width: 100, height: 14),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ShimmerLoading(width: 60, height: 40),
              ShimmerLoading(width: 60, height: 40),
              ShimmerLoading(width: 60, height: 40),
            ],
          ),
          SizedBox(height: 24),
          ShimmerLoading(height: 80),
          SizedBox(height: 12),
          ShimmerLoading(height: 80),
        ],
      ),
    );
  }
}

class FollowAnalysisShimmer extends StatelessWidget {
  const FollowAnalysisShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerLoading(height: 72)),
              SizedBox(width: 8),
              Expanded(child: ShimmerLoading(height: 72)),
              SizedBox(width: 8),
              Expanded(child: ShimmerLoading(height: 72)),
            ],
          ),
          SizedBox(height: 24),
          ShimmerLoading(height: 220),
          SizedBox(height: 16),
          ShimmerLoading(height: 220),
          SizedBox(height: 16),
          ShimmerLoading(height: 220),
        ],
      ),
    );
  }
}

class ListShimmer extends StatelessWidget {
  final int itemCount;

  const ListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ShimmerLoading(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(width: 120, height: 14),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
