// Web-only widget — renders Mermaid diagrams inside an iframe.
// Uses srcdoc (not data: URL) for CSP compatibility in production (Firebase Hosting).
// The iframe renders the SVG scaled to fit width; container is scrollable vertically.
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

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
  bool _renderFailed = false;

  void Function(html.Event)? _msgHandler;

  @override
  void initState() {
    super.initState();
    _viewId = 'mermaid-frame-${++_counter}';
    _listenMessages();
    _registerView();
  }

  @override
  void dispose() {
    if (_msgHandler != null) {
      html.window.removeEventListener('message', _msgHandler);
    }
    super.dispose();
  }

  void _listenMessages() {
    _msgHandler = (html.Event event) {
      if (event is html.MessageEvent) {
        try {
          final data = event.data;
          if (data is Map) {
            final type = data['type'] as String?;
            if (type == 'mermaid-error' && mounted) {
              setState(() => _renderFailed = true);
            }
          }
        } catch (e) {
          debugPrint('Mermaid message parse error: $e');
        }
      }
    };
    html.window.addEventListener('message', _msgHandler);
  }

  void _registerView() {
    if (widget.diagram.trim().isEmpty) return;
    try {
      final iframe = html.IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = '0'
        ..style.background = '#0F0F0F'
        ..srcdoc = _buildHtml(widget.diagram);

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
      setState(() => _registered = true);
    } catch (e) {
      debugPrint('Mermaid iframe error: $e');
    }
  }

  /// Builds the inline HTML page.
  /// The SVG is rendered at full width with height:auto so the aspect ratio
  /// is preserved. The body has overflow:auto so the user can scroll vertically
  /// if the diagram is tall. A fixed 400px container in Flutter clips the view
  /// and lets the iframe's internal scroll handle the rest.
  String _buildHtml(String diagram) {
    // Escape for safe embedding inside a JS template literal
    final safe = diagram
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('</script', '<\\/script');

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html { background: #0F0F0F; height: 100%; }
    body {
      background: #0F0F0F;
      padding: 16px;
      font-family: Inter, sans-serif;
      overflow: hidden; /* Hide ugly scrollbars */
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #out {
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    #out svg {
      display: block !important;
      width: 100% !important;
      height: 100% !important;
      max-width: 100% !important;
      max-height: 100% !important;
    }
    .node rect, .node circle, .node ellipse,
    .node polygon, .node path {
      fill: #1A1A1A !important;
      stroke: #6C63FF !important;
    }
    .edgePath path { stroke: #6C63FF !important; }
    .edgeLabel { background: #1A1A1A !important; color: #F0F0F0; }
    .cluster rect { fill: #252525 !important; stroke: #6C63FF !important; }
    .label, .nodeLabel { color: #F0F0F0 !important; }
    #err {
      display: none; color: #8A8A8A;
      font: 11px/1.7 monospace;
      white-space: pre-wrap; word-break: break-word;
      padding: 8px;
    }
  </style>
</head>
<body>
  <div id="out"></div>
  <pre id="err"></pre>

  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    const DIAGRAM = \`$safe\`;

    mermaid.initialize({
      startOnLoad: false,
      theme: 'dark',
      fontFamily: 'Inter, sans-serif',
      suppressErrorRendering: true,
      flowchart: { curve: 'basis', useMaxWidth: true, htmlLabels: true },
      themeVariables: {
        background:           '#0F0F0F',
        mainBkg:              '#1A1A1A',
        primaryColor:         '#1A1A1A',
        primaryTextColor:     '#F0F0F0',
        primaryBorderColor:   '#6C63FF',
        lineColor:            '#6C63FF',
        secondaryColor:       '#252525',
        tertiaryColor:        '#2A2A2A',
        edgeLabelBackground:  '#1A1A1A',
        nodeBorder:           '#6C63FF',
      }
    });

    async function go() {
      try {
        const { svg } = await mermaid.render('mg', DIAGRAM);
        const out = document.getElementById('out');
        out.innerHTML = svg;

        // Strip fixed pixel dimensions — let CSS width:100%/height:auto handle scaling
        const svgEl = out.querySelector('svg');
        if (svgEl) {
          const nw = parseFloat(svgEl.getAttribute('width'))  || 800;
          const nh = parseFloat(svgEl.getAttribute('height')) || 400;
          if (!svgEl.getAttribute('viewBox')) {
            svgEl.setAttribute('viewBox', '0 0 ' + nw + ' ' + nh);
          }
          svgEl.removeAttribute('width');
          svgEl.removeAttribute('height');
          svgEl.setAttribute('preserveAspectRatio', 'xMidYMid meet');
        }

        window.parent.postMessage({ type: 'mermaid-ok' }, '*');
      } catch (err) {
        console.error('Mermaid error:', err);
        document.getElementById('err').style.display = 'block';
        document.getElementById('err').textContent = DIAGRAM;
        window.parent.postMessage({ type: 'mermaid-error', message: String(err) }, '*');
      }
    }

    go();
  </script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    if (_renderFailed) {
      return MermaidFallbackView(diagram: widget.diagram);
    }

    if (widget.diagram.trim().isEmpty) {
      return _emptyBox();
    }

    if (!_registered) {
      return _loadingBox();
    }

    // Fixed 400px container — iframe scrolls internally if the diagram is tall.
    // This ensures the diagram always fits in the page without overflowing Flutter layout.
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _loadingBox() => Container(
        height: 90,
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
                  strokeWidth: 1.5, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Text('Rendering diagram…', style: AppTheme.bodySmall),
          ],
        ),
      );

  Widget _emptyBox() => Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppTheme.border),
        ),
        child: Text('No architecture diagram available.', style: AppTheme.bodySmall),
      );
}

/// Shown when the iframe reports a Mermaid parse error.
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
            Text(
              'Architecture (source — render failed)',
              style: AppTheme.labelSmall.copyWith(color: AppTheme.textMuted),
            ),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              diagram,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppTheme.textSecondary.withValues(alpha: 0.85),
                height: 1.75,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
