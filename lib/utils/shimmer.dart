library my_afse.shimmer;

import "package:flutter/material.dart";
import "package:shimmer/shimmer.dart";

/// Loading blocks o' shiny~
class CustomShimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;

  const CustomShimmer({
    this.width,
    this.height = 16,
    this.radius = 5,
    this.padding = EdgeInsets.zero,
    final Key? key,
  }) : super(key: key);

  @override
  CustomShimmerState createState() => CustomShimmerState();
}

class CustomShimmerState extends State<CustomShimmer> {
  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceVariant,
      highlightColor: colorScheme.surface,
      child: Padding(
        padding: widget.padding,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          width: widget.width,
          height: widget.height,
        ),
      ),
    );
  }
}
