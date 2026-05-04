// Web-only widget — renders Mermaid diagrams inside an iframe (most reliable approach)
import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

/// Renders a Mermaid.js architecture diagram inside an iframe platform view.
/// The iframe posts `{type:"mermaid-ok"}` or `{type:"mermaid-error"}` back
/// to the parent so Flutter can switch to the text fallback on syntax errors.
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

  JSFunction? _messageHandler;

  @override
  void initState() {
    super.initState();
    _viewId = 'mermaid-frame-${++_counter}';
    _registerView();
    _listenForIframeMessages();
  }

  @override
  void dispose() {
    // Remove the message event listener
    if (_messageHandler != null) {
      web.window.removeEventListener('message', _messageHandler!);
    }
    super.dispose();
  }

  /// Listens for postMessage from the iframe:
  ///   { type: "mermaid-ok" }    → diagram rendered fine
  ///   { type: "mermaid-error" } → syntax error, show fallback
  void _listenForIframeMessages() {
    _messageHandler = (web.MessageEvent event) {
      try {
        final data = event.data.dartify();
        if (data is Map) {
          final type = data['type'] as String?;
          if (type == 'mermaid-error' && mounted) {
            setState(() => _renderFailed = true);
          }
        }
      } catch (_) {}
    }.toJS;
    web.window.addEventListener('message', _messageHandler!);
  }

  void _registerView() {
    try {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = '0';
      iframe.style.background = '#0F0F0F';
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

  /// Builds a self-contained HTML page that:
  /// 1. Renders the Mermaid diagram
  /// 2. Posts {type:"mermaid-error"} to parent if Mermaid throws
  String _buildHtml(String diagram) {
    // Escape diagram for safe embedding inside a JS template literal
    final safe = diagram
        .replaceAll('\\', '\\\\')
        .replaceAll('`', '\\`')
        .replaceAll('</script', '<\\/script');

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
      min-height: 100vh;
    }
    .mermaid { max-width: 100%; }
    svg {
      max-width: 100% !important;
      height: auto !important;
      display: block;
      margin: 0 auto;
    }
    .node rect, .node circle, .node ellipse, .node polygon {
      fill: #1A1A1A !important;
      stroke: #6C63FF !important;
    }
    .edgeLabel { background: #1A1A1A !important; }
    .cluster rect { fill: #252525 !important; stroke: #6C63FF !important; }
    #error-msg {
      display: none;
      color: #8A8A8A;
      font-size: 11px;
      padding: 12px;
      font-family: monospace;
      white-space: pre-wrap;
      word-break: break-word;
    }
  </style>
</head>
<body>
  <pre class="mermaid" id="diagram"></pre>
  <div id="error-msg"></div>
  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
  <script>
    const diagram = `$safe`;

    mermaid.initialize({
      startOnLoad: false,
      theme: 'dark',
      fontFamily: 'Inter, sans-serif',
      suppressErrorRendering: true,
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

    async function render() {
      try {
        const { svg } = await mermaid.render('mermaid-svg', diagram);
        const el = document.getElementById('diagram');
        if (el) el.innerHTML = svg;
        window.parent.postMessage({ type: 'mermaid-ok' }, '*');
      } catch (err) {
        console.error('Mermaid parse error:', err);
        // Show raw diagram text as fallback inside iframe
        const errEl = document.getElementById('error-msg');
        if (errEl) {
          errEl.style.display = 'block';
          errEl.textContent = diagram;
        }
        // Tell Flutter to switch to Flutter-side fallback
        window.parent.postMessage({ type: 'mermaid-error', message: err.message }, '*');
      }
    }

    render();
  </script>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    // If iframe reported a parse error, show Flutter fallback immediately
    if (_renderFailed) {
      return MermaidFallbackView(diagram: widget.diagram);
    }

    if (!_registered) {
      return _loadingBox('Preparing diagram…');
    }

    if (widget.diagram.trim().isEmpty) {
      return _emptyBox();
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

  Widget _loadingBox(String msg) {
    return Container(
      height: 100,
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
            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Text(msg, style: AppTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _emptyBox() {
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

/// Flutter-side fallback: shows the raw Mermaid source in a styled monospace box.
/// Displayed when the iframe reports a parse error via postMessage.
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
              'Architecture (Mermaid source — render failed)',
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
