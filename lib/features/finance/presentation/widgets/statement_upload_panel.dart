import 'dart:io';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';

class StatementUploadPanel extends StatefulWidget {
  final List<String> allowedExtensions;
  final Function(File file, String name) onFileSelected;
  final String title;
  final String dragOverTitle;
  final String supportedFormatsText;
  final String selectFileButtonText;

  const StatementUploadPanel({
    super.key,
    required this.allowedExtensions,
    required this.onFileSelected,
    required this.title,
    required this.dragOverTitle,
    required this.supportedFormatsText,
    required this.selectFileButtonText,
  });

  @override
  State<StatementUploadPanel> createState() => _StatementUploadPanelState();
}

class _StatementUploadPanelState extends State<StatementUploadPanel>
    with SingleTickerProviderStateMixin {
  bool _dragging = false;
  late AnimationController _borderAnimationController;

  @override
  void initState() {
    super.initState();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    super.dispose();
  }

  void _onDragEntered() {
    setState(() {
      _dragging = true;
    });
    _borderAnimationController.repeat();
  }

  void _onDragExited() {
    setState(() {
      _dragging = false;
    });
    _borderAnimationController.stop();
  }

  Future<void> _handleDroppedFiles(List<dynamic> files) async {
    if (files.isNotEmpty) {
      final file = files.first;
      final name = file.name as String;
      final extension = name.split('.').last.toLowerCase();

      if (widget.allowedExtensions.contains(extension)) {
        widget.onFileSelected(File(file.path), name);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Formato não suportado. Use apenas: ${widget.allowedExtensions.join(", ").toUpperCase()}',
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      widget.onFileSelected(File(path), name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderPainterColor = _dragging
        ? AppColors.brightCyan
        : AppColors.deepTurquoise.withValues(alpha: 0.5);

    return DropTarget(
      onDragEntered: (_) => _onDragEntered(),
      onDragExited: (_) => _onDragExited(),
      onDragDone: (detail) {
        _onDragExited();
        _handleDroppedFiles(detail.files);
      },
      child: AnimatedBuilder(
        animation: _borderAnimationController,
        builder: (context, child) {
          return CustomPaint(
            painter: DashedBorderPainter(
              color: borderPainterColor,
              strokeWidth: 2.0,
              gap: 6.0,
              dashLength: 10.0,
              phase: _dragging ? _borderAnimationController.value : 0.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _dragging
                    ? LinearGradient(
                        colors: AppGradients.turquoiseBlue.colors
                            .map((c) => c.withValues(alpha: 0.2))
                            .toList(),
                        begin: AppGradients.turquoiseBlue.begin,
                        end: AppGradients.turquoiseBlue.end,
                      )
                    : null,
                color: _dragging
                    ? null
                    : AppColors.deepTurquoise.withValues(alpha: 0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _dragging
                          ? Icons.file_download
                          : Icons.cloud_upload_outlined,
                      size: 64,
                      color: _dragging
                          ? AppColors.brightCyan
                          : AppColors.deepTurquoise,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _dragging ? widget.dragOverTitle : widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _dragging
                            ? AppColors.brightCyan
                            : AppColors.darkNavy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.supportedFormatsText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_dragging) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(widget.selectFileButtonText),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.deepTurquoise,
                          side: const BorderSide(
                            color: AppColors.deepTurquoise,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double phase; // value from 0.0 to 1.0

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 4.0,
    this.dashLength = 8.0,
    this.phase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(16),
        ),
      );

    final dashPath = _buildDashedPath(path, dashLength, gap, phase);
    canvas.drawPath(dashPath, paint);
  }

  Path _buildDashedPath(
    Path source,
    double dashLength,
    double gap,
    double phase,
  ) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = (phase * (dashLength + gap)) % (dashLength + gap);
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLength : gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(
              distance,
              (distance + len).clamp(0.0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.phase != phase;
  }
}
