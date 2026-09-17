import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/platform/app_platform.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';

class StatementUploadPanel extends StatefulWidget {
  final List<String> allowedExtensions;

  /// Recebe o arquivo já lido. O painel entrega bytes, não caminho: é o que a
  /// web tem para oferecer e o que o Storage quer em qualquer plataforma.
  final void Function(PickedDocument document) onFileSelected;
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

  Future<void> _handleDroppedFiles(List<DropItem> files) async {
    if (files.isEmpty) return;

    final DropItem dropped = files.first;


    // `readAsBytes` do desktop_drop funciona nas duas pontas: no desktop lê do
    // disco, na web lê o blob que o navegador entregou.
    _accept(
      PickedDocument(
        name: dropped.name,
        bytes: await dropped.readAsBytes(),
        // Na web o `path` do item arrastado é uma URL de blob, não um
        // caminho. Guardá-la convidaria alguém a tentar abri-la mais tarde.
        path: AppPlatform.hasFileSystem ? dropped.path : null,
      ),
    );
  }

  Future<void> _pickFile() async {
    // `withData: true` é o que faz o seletor devolver os bytes. Sem ele, na
    // web `PlatformFile.bytes` vem nulo e `path` também — não sobrava nada
    // para enviar.
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;

    final PlatformFile picked = result.files.single;
    final Uint8List? bytes = picked.bytes ?? _readFromDisk(picked.path);

    if (bytes == null) {
      _warn(context.l10n.uploadFileUnreadable);
      return;
    }

    _accept(
      PickedDocument(name: picked.name, bytes: bytes, path: picked.path),
    );
  }

  /// Plano B de desktop/mobile: o seletor pode devolver só o caminho.
  ///
  /// Na web nunca há caminho, e `AppPlatform.hasFileSystem` é constante de
  /// compilação — o `dart:io` some do bundle do navegador.
  ///
  /// A leitura é síncrona de propósito: é um arquivo de no máximo 10 MB que o
  /// usuário acabou de escolher, e o caminho assíncrono só adiantaria a
  /// resposta de um diálogo que já fechou.
  Uint8List? _readFromDisk(String? path) {
    if (path == null || !AppPlatform.hasFileSystem) return null;

    try {
      return File(path).readAsBytesSync();
    } catch (_) {
      // Arquivo que sumiu entre a escolha e a leitura.
      return null;
    }
  }

  /// Só entrega o arquivo para quem vai enviá-lo se ele tiver conteúdo, for de
  /// um formato aceito e couber no limite da análise. Mandar para o Storage um
  /// arquivo que o servidor vai recusar gasta a banda do usuário para
  /// terminar em erro.
  void _accept(PickedDocument document) {
    final l10n = context.l10n;

    if (!StatementUploadLimits.isAllowedExtension(
      document.name,
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
    // download cancelado, blob revogado) chega aqui vazio. Zero byte passaria
    // no limite e subiria um arquivo vazio para a análise.
    if (document.sizeInBytes == 0) {
      _warn(l10n.uploadFileUnreadable);
      return;
    }

    if (!StatementUploadLimits.isWithinLimit(document.sizeInBytes)) {
      _warn(
        l10n.uploadFileTooLarge(
          _humanSize(document.sizeInBytes),
          StatementUploadLimits.maxMegabytes,
        ),
      );
      return;
    }

    widget.onFileSelected(document);
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
