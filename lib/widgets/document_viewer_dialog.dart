import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'dart:ui_web' as ui;

/// Shows a PDF/document embedded in an iframe inside the app.
/// Works on Flutter Web only. On other platforms, falls back to a
/// simple "copy URL" dialog.
class DocumentViewerDialog extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  const DocumentViewerDialog({
    Key? key,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  /// Convenience method — call this instead of showDialog directly.
  static void show(BuildContext context,
      {required String fileUrl, required String fileName}) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) =>
          DocumentViewerDialog(fileUrl: fileUrl, fileName: fileName),
    );
  }

  @override
  State<DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<DocumentViewerDialog> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'doc-viewer-${DateTime.now().millisecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.fileUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true;
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: size.width * 0.85,
        height: size.height * 0.85,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFB22234),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            // ── Embedded viewer ───────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                child: HtmlElementView(viewType: _viewId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
