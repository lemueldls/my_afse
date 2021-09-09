library my_afse.shimmer;

import "package:flutter/material.dart";
import "package:shimmer/shimmer.dart";

import "settings.dart";

class CustomShimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;

  const CustomShimmer({
    Key? key,
    this.width,
    this.height = 16.0,
    this.radius = 5.0,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  _CustomShimmerState createState() => _CustomShimmerState();
}

class _CustomShimmerState extends State<CustomShimmer> {
  @override
  build(context) {
    final dark = settings.dark;

    return Shimmer.fromColors(
      baseColor: dark ? Colors.grey.shade600 : Colors.grey.shade300,
      highlightColor: dark ? Colors.grey.shade700 : Colors.grey[350]!,
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
