import 'dart:io';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';

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
  State<StatementUploadPanel> createState() => StatementUploadPanelState();
}

class StatementUploadPanelState extends State<StatementUploadPanel>
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
    if (files.isEmpty) return;

    final dropped = files.first;

    _accept(File(dropped.path as String), dropped.name as String);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
    );

    if (result == null || result.files.single.path == null) return;

    _accept(File(result.files.single.path!), result.files.single.name);
  }

  /// Porta única do painel, para o teste exercitar a mesma barreira que o
  /// seletor de arquivos e o arrastar-e-soltar atravessam.
  @visibleForTesting
  void acceptForTest(File file, String name) => _accept(file, name);

  /// Só entrega o arquivo para quem vai enviá-lo se ele existir, for de um
  /// formato aceito e couber no limite da análise. Mandar para o Storage um
  /// arquivo que o servidor vai recusar gasta a banda do usuário para
  /// terminar em erro.
  void _accept(File file, String name) {
    final l10n = context.l10n;

    if (!StatementUploadLimits.isAllowedExtension(
      name,
      widget.allowedExtensions,
    )) {
      _warn(
        l10n.uploadUnsupportedFormat(
          widget.allowedExtensions.join(", ").toUpperCase(),
        ),
      );
      return;
    }

    // Arquivo que sumiu entre a escolha e o envio (pasta temporária limpa,
    // download cancelado) não pode virar "0 byte", que passaria no limite e
    // subiria um arquivo vazio para a análise.
    if (!file.existsSync()) {
      _warn(l10n.uploadFileUnreadable);
      return;
    }

    final bytes = file.lengthSync();

    if (!StatementUploadLimits.isWithinLimit(bytes)) {
      _warn(
        l10n.uploadFileTooLarge(
          _humanSize(bytes),
          StatementUploadLimits.maxMegabytes,
        ),
      );
      return;
    }

    widget.onFileSelected(file, name);
  }

  void _warn(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _humanSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);

    return megabytes >= 1
        ? '${megabytes.toStringAsFixed(1)} MB'
        : '${(bytes / 1024).round()} KB';
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
