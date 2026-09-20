import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/platform/app_platform.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
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

    // Pasta arrastada. `readAsBytes` numa pasta falha, e falhava calada: o
    // usuário soltava a pasta e não acontecia nada.
    if (dropped is DropItemDirectory) {
      _warn(context.l10n.uploadFolderNotSupported);
      return;
    }

    // O tamanho vem ANTES dos bytes: um extrato de 50 MB não precisa passar
    // pela memória do app só para ser recusado.
    final int declaredSize = await dropped.length();

    if (!mounted || _rejectsDeclaredSize(declaredSize)) return;

    // `readAsBytes` do desktop_drop funciona nas duas pontas: no desktop lê do
    // disco, na web lê o blob que o navegador entregou.
    final Uint8List bytes = await dropped.readAsBytes();

    if (!mounted) return;

    _accept(
      PickedDocument(
        name: dropped.name,
        bytes: bytes,
        // Na web o `path` do item arrastado é uma URL de blob, não um
        // caminho. Guardá-la convidaria alguém a tentar abri-la mais tarde.
        path: AppPlatform.hasFileSystem ? dropped.path : null,
      ),
    );
  }

  /// true quando o tamanho declarado já reprova o arquivo — e avisa.
  ///
  /// Zero significa "não sei": alguns seletores não declaram tamanho. Aí não
  /// dá para decidir nada aqui, e quem resolve é a checagem final, sobre os
  /// bytes de verdade.
  ///
  /// ONDE ISTO DE FATO ECONOMIZA MEMÓRIA: no arrastar-e-soltar e na escolha
  /// fora da web. Na web o `file_picker` lê os bytes DENTRO de `pickFiles`,
  /// antes de devolver qualquer coisa — não há caminho no navegador, então
  /// não existe um "só os metadados" para pedir. Ali esta checagem apenas
  /// evita o trabalho seguinte (validar, montar o documento, subir ao
  /// Storage); o arquivo já passou pela memória.
  bool _rejectsDeclaredSize(int size) {
    if (size <= 0 || StatementUploadLimits.isWithinLimit(size)) return false;

    _warn(
      context.l10n.uploadFileTooLarge(
        _humanSize(size),
        StatementUploadLimits.maxMegabytes,
      ),
    );

    return true;
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: widget.allowedExtensions,
      // Na web não existe caminho: os bytes são a única forma de receber o
      // arquivo, e sem isto `bytes` e `path` vinham os dois nulos. Fora da
      // web pedimos só o caminho, para poder recusar pelo tamanho ANTES de
      // carregar o arquivo inteiro na memória.
      withData: !AppPlatform.hasFileSystem,
    );

    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;

    final PlatformFile picked = result.files.single;

    if (_rejectsDeclaredSize(picked.size)) return;

    final Uint8List? bytes = picked.bytes ?? _readFromDisk(picked.path);

    if (bytes == null) {
      _warn(context.l10n.uploadFileUnreadable);
      return;
    }

    _accept(PickedDocument(name: picked.name, bytes: bytes, path: picked.path));
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
    final theme = Theme.of(context);
    final palette = context.palette;

    // O acento do painel é o teal do tema corrente; arrastando, o teal vivo.
    final accent = _dragging ? AppColors.teal : palette.tealText;
    final borderPainterColor = _dragging
        ? accent
        : accent.withValues(alpha: 0.5);

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
              duration: AppDurations.normal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xxxl,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.brLg,
                gradient: _dragging
                    ? LinearGradient(
                        colors: AppGradients.game.colors
                            .map((c) => c.withValues(alpha: 0.2))
                            .toList(),
                        begin: AppGradients.game.begin,
                        end: AppGradients.game.end,
                      )
                    : null,
                color: _dragging ? null : accent.withValues(alpha: 0.05),
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
                      color: accent,
                    ),
                    AppSpacing.gapMd,
                    Text(
                      _dragging ? widget.dragOverTitle : widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _dragging ? accent : palette.ink,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapXs,
                    Text(
                      widget.supportedFormatsText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.ink2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_dragging) ...[
                      AppSpacing.gapLg,
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(widget.selectFileButtonText),
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
          const Radius.circular(AppRadius.lg),
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
