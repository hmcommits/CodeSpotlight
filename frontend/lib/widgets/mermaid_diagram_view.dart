// Web-only widget — uses dart:js_interop for Mermaid SVG rendering
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

// External JS function declared in web/index.html
@JS('renderMermaidSafe')
external JSPromise<JSString> _jsMermaidRender(JSString id, JSString graph);

/// Renders a Mermaid.js architecture diagram.
/// Calls `renderMermaidSafe(id, graphDef)` from web/index.html via dart:js_interop
/// and displays the resulting SVG. Falls back to styled raw text on any error.
class MermaidDiagramView extends StatefulWidget {
  final String diagram;

  const MermaidDiagramView({super.key, required this.diagram});

  @override
  State<MermaidDiagramView> createState() => _MermaidDiagramViewState();
}

class _MermaidDiagramViewState extends State<MermaidDiagramView> {
  String? _svg;
  bool _loading = true;
  bool _failed = false;
  static int _counter = 0;
  late final String _id;

  @override
  void initState() {
    super.initState();
    _id = 'cs-mermaid-${++_counter}';
    _render();
  }

  @override
  void didUpdateWidget(covariant MermaidDiagramView old) {
    super.didUpdateWidget(old);
    if (old.diagram != widget.diagram) _render();
  }

  Future<void> _render() async {
    if (widget.diagram.trim().isEmpty) {
      if (mounted) setState(() { _loading = false; _failed = true; });
      return;
    }
    if (mounted) setState(() { _loading = true; _failed = false; });

    try {
      final jsResult = await _jsMermaidRender(_id.toJS, widget.diagram.toJS).toDart;
      final svg = jsResult.toDart;
      if (!mounted) return;
      if (svg.isNotEmpty) {
        _injectSvgIntoDom(_id, svg);
        setState(() { _svg = svg; _loading = false; });
      } else {
        setState(() { _loading = false; _failed = true; });
      }
    } catch (e) {
      debugPrint('Mermaid render error: $e');
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  static void _injectSvgIntoDom(String id, String svg) {
    try {
      var el = web.document.getElementById(id);
      if (el == null) {
        el = web.document.createElement('div');
        el.id = id;
        web.document.body?.appendChild(el);
      }
      el.innerHTML = svg.toJS;
      final svgEl = el.querySelector('svg');
      if (svgEl != null) {
        final s = (svgEl as web.HTMLElement).style;
        s.maxWidth = '100%';
        s.height = 'auto';
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Text('Rendering architecture diagram…', style: AppTheme.bodySmall),
          ],
        ),
      );
    }

    if (_failed || _svg == null) {
      return _DiagramFallback(diagram: widget.diagram);
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 360, minHeight: 120),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _id),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _DiagramFallback extends StatelessWidget {
  final String diagram;
  const _DiagramFallback({required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: diagram.isEmpty
          ? Center(child: Text('No architecture diagram generated.', style: AppTheme.bodySmall))
          : Column(
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
