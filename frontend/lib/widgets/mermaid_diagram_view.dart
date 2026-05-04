// Web-only widget — renders Mermaid diagrams inside an iframe (most reliable approach)
// The iframe loads mermaid.js independently, bypassing Flutter's dart:js_interop timing issues.
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

/// Renders a Mermaid.js architecture diagram inside an iframe platform view.
/// Uses an inline data-URL so no external server is needed.
class MermaidDiagramView extends StatefulWidget {
  final String diagram;
  const MermaidDiagramView({super.key, required this.diagram});

  @override
  State<MermaidDiagramView> createState() => _MermaidDiagramViewState();
}

class _MermaidDiagramViewState extends State<MermaidDiagramView> {
  static int _counter = 0;
  late final String _viewId;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'mermaid-frame-${++_counter}';
    _registerView();
  }

  void _registerView() {
    try {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = '0';
      iframe.style.background = '#0F0F0F';
      // Use data: URL so it works offline / in dev / in production
      final html = Uri.encodeComponent(_buildHtml(widget.diagram));
      iframe.src = 'data:text/html;charset=utf-8,$html';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (_) => iframe,
      );
      setState(() => _registered = true);
    } catch (e) {
      debugPrint('Mermaid iframe registration error: $e');
    }
  }

  /// Builds a self-contained HTML page that renders the Mermaid diagram.
  String _buildHtml(String diagram) {
    // Escape any backticks / script-closing tags in the diagram string
    final safe = diagram
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('</', '<\\/');
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0F0F0F;
      padding: 16px;
      font-family: Inter, sans-serif;
      overflow: auto;
    }
    .mermaid { max-width: 100%; }
    svg {
      max-width: 100% !important;
      height: auto !important;
      display: block;
      margin: 0 auto;
    }
    /* Dark Mermaid node overrides */
    .node rect, .node circle, .node ellipse, .node polygon {
      fill: #1A1A1A !important;
      stroke: #6C63FF !important;
    }
    .edgeLabel { background: #1A1A1A !important; }
    .cluster rect { fill: #252525 !important; stroke: #6C63FF !important; }
  </style>
</head>
<body>
  <pre class="mermaid">${diagram}</pre>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    mermaid.initialize({
      startOnLoad: true,
      theme: 'dark',
      fontFamily: 'Inter, sans-serif',
      flowchart: { curve: 'basis', useMaxWidth: true },
      themeVariables: {
        background: '#0F0F0F',
        mainBkg: '#1A1A1A',
        primaryColor: '#1A1A1A',
        primaryTextColor: '#F0F0F0',
        primaryBorderColor: '#6C63FF',
        lineColor: '#6C63FF',
        secondaryColor: '#252525',
        tertiaryColor: '#2A2A2A',
        edgeLabelBackground: '#1A1A1A',
        nodeBorder: '#6C63FF',
      }
    });
  </script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    if (!_registered) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text('Loading diagram…', style: AppTheme.bodySmall),
          ],
        ),
      );
    }

    if (widget.diagram.trim().isEmpty) {
      return _EmptyDiagram();
    }

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _EmptyDiagram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text('No architecture diagram available.', style: AppTheme.bodySmall),
    );
  }
}

/// Fallback shown if the project has a diagram string but rendering failed
class MermaidFallbackView extends StatelessWidget {
  final String diagram;
  const MermaidFallbackView({super.key, required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.account_tree_outlined, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text('Architecture (Mermaid source)',
                style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted)),
          ]),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              diagram,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
