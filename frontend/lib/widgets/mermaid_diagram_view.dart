// Web-only widget — renders Mermaid diagrams inside an iframe.
// The iframe strips fixed SVG dimensions and reports its natural height
// back to Flutter via postMessage so the container auto-sizes with no scroll.
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web/web.dart' as web;
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
  // Height reported by the iframe after SVG render; default 280 until known
  double _iframeHeight = 280;

  JSFunction? _msgHandler;

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
      web.window.removeEventListener('message', _msgHandler!);
    }
    super.dispose();
  }

  // Listen for { type: 'mermaid-ok', height: N } or { type: 'mermaid-error' }
  void _listenMessages() {
    _msgHandler = (web.MessageEvent event) {
      try {
        final data = event.data.dartify();
        if (data is! Map) return;
        final type = data['type'] as String?;
        if (type == 'mermaid-ok' && mounted) {
          final h = data['height'];
          final reportedH = h is num ? h.toDouble() : _iframeHeight;
          // Clamp: min 150, max 520
          final clamped = reportedH.clamp(150.0, 520.0);
          setState(() => _iframeHeight = clamped);
        } else if (type == 'mermaid-error' && mounted) {
          setState(() => _renderFailed = true);
        }
      } catch (_) {}
    }.toJS;
    web.window.addEventListener('message', _msgHandler!);
  }

  void _registerView() {
    try {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = '0';
      iframe.style.background = '#0F0F0F';
      // data: URL — works without a server, offline, in dev & prod
      final html = Uri.encodeComponent(_buildHtml(widget.diagram));
      iframe.src = 'data:text/html;charset=utf-8,$html';

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
      setState(() => _registered = true);
    } catch (e) {
      debugPrint('Mermaid iframe error: $e');
    }
  }

  /// Self-contained HTML that:
  /// 1. Renders Mermaid via mermaid.render() (no startOnLoad glitches)
  /// 2. Strips fixed SVG width/height → scales to 100% width, auto height
  /// 3. Posts natural content height back to Flutter via postMessage
  /// 4. Posts mermaid-error on parse failure
  String _buildHtml(String diagram) {
    final safe = diagram
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('</script', '<\\/script');

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { background: #0F0F0F; overflow: hidden; }
    body { padding: 16px; font-family: Inter, sans-serif; }

    /* Make SVG fill its container and scale proportionally */
    #out svg {
      display: block !important;
      width: 100% !important;
      height: auto !important;
      max-width: 100% !important;
    }
    /* Dark theme node overrides */
    .node rect, .node circle, .node ellipse,
    .node polygon, .node path {
      fill: #1A1A1A !important;
      stroke: #6C63FF !important;
    }
    .edgePath path { stroke: #6C63FF !important; }
    .edgeLabel  { background: #1A1A1A !important; color: #F0F0F0; }
    .cluster rect { fill: #252525 !important; stroke: #6C63FF !important; }
    .label { color: #F0F0F0 !important; }

    /* Error / fallback pre */
    #err {
      display: none; color: #8A8A8A;
      font: 11px/1.7 monospace;
      white-space: pre-wrap; word-break: break-word;
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

        // ── Strip fixed pixel dimensions so CSS can control scaling ──
        const svgEl = out.querySelector('svg');
        if (svgEl) {
          // Preserve intrinsic ratio via viewBox
          const nw = parseFloat(svgEl.getAttribute('width'))  || 800;
          const nh = parseFloat(svgEl.getAttribute('height')) || 400;
          if (!svgEl.getAttribute('viewBox')) {
            svgEl.setAttribute('viewBox', '0 0 ' + nw + ' ' + nh);
          }
          svgEl.removeAttribute('width');
          svgEl.removeAttribute('height');
          svgEl.setAttribute('preserveAspectRatio', 'xMidYMid meet');
        }

        // Measure total rendered height after layout
        requestAnimationFrame(() => {
          const h = document.body.scrollHeight;
          window.parent.postMessage({ type: 'mermaid-ok', height: h }, '*');
        });
      } catch (err) {
        console.error('Mermaid error:', err.message || err);
        const errEl = document.getElementById('err');
        errEl.style.display = 'block';
        errEl.textContent = DIAGRAM;
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

    // AnimatedContainer smoothly grows from 280 to the reported natural height
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      height: _iframeHeight,
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

/// Fallback: shown when the iframe reports a Mermaid parse error.
/// Shows the raw diagram source in readable monospace.
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
