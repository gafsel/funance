import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 0.0,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        if (isLargeScreen) {
          List<List<Widget>> grid = [[]];

          int columns = (constraints.maxWidth / 250).toInt();
          for (var child in children) {
            if (grid.length == columns) {
              grid.add([]);
            }

            grid.last.add(child);
          }

          return Column(
            spacing: spacing,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (List<Widget> row in grid)
                Row(
                  spacing: spacing,
                  mainAxisSize: MainAxisSize.min,
                  children: row,
                ),
            ],
          );
        }

        return Column(spacing: spacing, children: children);
      },
    );
  }
}
