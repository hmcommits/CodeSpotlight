// VideoPlayerView — renders YouTube/Loom/direct video links in an iframe.
// For YouTube: converts watch URLs to embed URLs and uses nocookie domain.
// For Loom:    uses Loom's embed endpoint.
// For direct:  wraps in an HTML5 <video> element.
// Falls back to an "Open Video" button if format is unrecognised.
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../theme/app_theme.dart';

class VideoPlayerView extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerView({super.key, required this.videoUrl});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  static int _counter = 0;
  late final String _viewId;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-frame-${++_counter}';
    _registerView();
  }

  /// Detects URL type and builds the appropriate embed HTML.
  static String? _embedUrl(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;

    // ── YouTube ──────────────────────────────────────────────────────────
    if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
      String? videoId;
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else {
        videoId = uri.queryParameters['v'];
      }
      if (videoId != null) {
        return 'https://www.youtube-nocookie.com/embed/$videoId'
            '?rel=0&modestbranding=1&color=white';
      }
    }

    // ── Loom ─────────────────────────────────────────────────────────────
    if (uri.host.contains('loom.com')) {
      final parts = uri.pathSegments;
      final shareIdx = parts.indexOf('share');
      if (shareIdx >= 0 && shareIdx + 1 < parts.length) {
        final id = parts[shareIdx + 1];
        return 'https://www.loom.com/embed/$id?hide_owner=true&hide_share=true';
      }
    }

    return null; // not a recognised embed-able URL
  }

  static bool _isDirectVideo(String url) =>
      url.endsWith('.mp4') ||
      url.endsWith('.webm') ||
      url.endsWith('.ogg');

  String _buildHtml() {
    final embed = _embedUrl(widget.videoUrl);

    if (embed != null) {
      // Iframe embed (YouTube / Loom)
      return '''<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { background:#000; width:100%; height:100%; }
  iframe { width:100%; height:100%; border:none; display:block; }
</style></head><body>
<iframe src="${embed}" allowfullscreen allow="autoplay; encrypted-media; picture-in-picture"></iframe>
</body></html>''';
    }

    if (_isDirectVideo(widget.videoUrl)) {
      return '''<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { background:#000; width:100%; height:100%; }
  video { width:100%; height:100%; object-fit:contain; display:block; }
</style></head><body>
<video controls autoplay muted loop src="${widget.videoUrl}"></video>
</body></html>''';
    }

    // Unrecognised — empty HTML (we fall back to button in Flutter)
    return '';
  }

  void _registerView() {
    final html = _buildHtml();
    if (html.isEmpty) {
      setState(() => _registered = false);
      return;
    }
    try {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = '0';
      iframe.style.background = '#000';
      iframe.src = 'data:text/html;charset=utf-8,${Uri.encodeComponent(html)}';
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
      setState(() => _registered = true);
    } catch (e) {
      debugPrint('VideoPlayerView error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If URL is not embeddable, show an "Open Video" button
    if (!_registered) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppTheme.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_outline,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Watch Demo Video',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.primary)),
            ],
          ),
        ),
      );
    }

    return Container(
      // 16:9 aspect ratio container
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
