import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../utils/icon_util.dart';

class TechIcon extends StatefulWidget {
  final String techName;
  final double size;
  final String colorHex;
  final TextStyle? fallbackStyle;

  const TechIcon({
    super.key,
    required this.techName,
    this.size = 32.0,
    this.colorHex = 'ffffff',
    this.fallbackStyle,
  });

  @override
  State<TechIcon> createState() => _TechIconState();
}

class _TechIconState extends State<TechIcon> {
  static final Map<String, String?> _svgCache = {};
  bool _isLoading = true;
  String? _svgData;
  late String _slug;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(TechIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techName != widget.techName || oldWidget.colorHex != widget.colorHex) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    _slug = IconUtil.getSimpleIconSlug(widget.techName);
    final url = 'https://cdn.simpleicons.org/$_slug/${widget.colorHex}';
    
    if (_svgCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _svgData = _svgCache[url];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        _svgCache[url] = res.body;
        if (mounted) {
          setState(() {
            _svgData = res.body;
            _isLoading = false;
          });
        }
      } else {
        _svgCache[url] = null;
        if (mounted) {
          setState(() {
            _svgData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _svgCache[url] = null;
      if (mounted) {
        setState(() {
          _svgData = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_svgData != null) {
      return SvgPicture.string(
        _svgData!,
        width: widget.size,
        height: widget.size,
      );
    }

    // Fallback if SVG not available
    return Container(
      width: widget.size,
      height: widget.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            widget.techName,
            style: widget.fallbackStyle ?? GoogleFonts.firaCode(
              fontWeight: FontWeight.bold,
              fontSize: widget.size * 0.4,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
