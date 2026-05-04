// VideoPlayerView — embeds YouTube, Loom, or direct video files.
// Uses srcdoc (not data: URL) for CSP compatibility on Firebase Hosting.
// YouTube error 153 = video restricted from embedding → shows "Watch on YouTube" button.
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _embedError = false;   // YouTube error 153 or similar

  JSFunction? _msgHandler;

  @override
  void initState() {
    super.initState();
    _viewId = 'video-frame-${++_counter}';
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

  void _listenMessages() {
    _msgHandler = (web.MessageEvent event) {
      try {
        final data = event.data.dartify();
        if (data is Map && data['type'] == 'video-error' && mounted) {
          setState(() => _embedError = true);
        }
      } catch (_) {}
    }.toJS;
    web.window.addEventListener('message', _msgHandler!);
  }

  /// Convert YouTube watch URLs to nocookie embed URLs.
  static String? _youtubeEmbedUrl(Uri uri) {
    if (!uri.host.contains('youtube') && !uri.host.contains('youtu.be')) {
      return null;
    }
    String? videoId;
    if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else {
      videoId = uri.queryParameters['v'];
    }
    if (videoId == null) return null;
    return 'https://www.youtube-nocookie.com/embed/$videoId'
        '?rel=0&modestbranding=1';
  }

  static String? _loomEmbedUrl(Uri uri) {
    if (!uri.host.contains('loom.com')) return null;
    final shareIdx = uri.pathSegments.indexOf('share');
    if (shareIdx < 0 || shareIdx + 1 >= uri.pathSegments.length) return null;
    return 'https://www.loom.com/embed/${uri.pathSegments[shareIdx + 1]}'
        '?hide_owner=true&hide_share=true';
  }

  static bool _isDirectVideo(String url) =>
      url.endsWith('.mp4') || url.endsWith('.webm') || url.endsWith('.ogg');

  void _registerView() {
    final uri = Uri.tryParse(widget.videoUrl.trim());
    if (uri == null) return;

    final embedUrl = _youtubeEmbedUrl(uri) ?? _loomEmbedUrl(uri);

    String html;
    if (embedUrl != null) {
      // iframe embed — with error detection for restricted videos (error 153)
      html = '''<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { background:#000; width:100%; height:100%; overflow:hidden; }
  iframe { width:100%; height:100%; border:none; display:block; }
</style></head><body>
<iframe id="vid" src="$embedUrl"
  allowfullscreen
  allow="autoplay; encrypted-media; picture-in-picture"
></iframe>
<script>
  // YouTube fires an onError event we can't directly intercept for embeds,
  // but we can detect the yt-player-error event via the iframe's postMessage.
  window.addEventListener('message', function(e) {
    try {
      var d = typeof e.data === 'string' ? JSON.parse(e.data) : e.data;
      // YouTube sends {event:"infoDelivery", info:{errorCode:150}} or 153
      if (d && d.event === 'infoDelivery' && d.info && d.info.errorCode) {
        window.parent.postMessage({ type: 'video-error', code: d.info.errorCode }, '*');
      }
    } catch(_) {}
  });
</script>
</body></html>''';
    } else if (_isDirectVideo(widget.videoUrl)) {
      html = '''<!DOCTYPE html><html><head><meta charset="UTF-8">
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { background:#000; width:100%; height:100%; overflow:hidden; }
  video { width:100%; height:100%; object-fit:contain; display:block; }
</style></head><body>
<video controls autoplay muted loop src="${widget.videoUrl}"></video>
</body></html>''';
    } else {
      // Unknown URL type — don't register, fall through to button
      return;
    }

    try {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.style.border = '0';
      iframe.style.background = '#000';
      // Use srcdoc — CSP safe (no data: URL)
      (iframe as dynamic).srcdoc = html;
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => iframe);
      setState(() => _registered = true);
    } catch (e) {
      debugPrint('VideoPlayerView error: $e');
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.tryParse(widget.videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Restricted/unembeddable video — show an "Open" button
    if (_embedError || !_registered) {
      return Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(color: AppTheme.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            onTap: _openExternal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline,
                    size: 20, color: AppTheme.primary),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch Demo Video',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.textPrimary)),
                    if (_embedError)
                      Text('(cannot embed — click to open)',
                          style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new, size: 14, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
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
