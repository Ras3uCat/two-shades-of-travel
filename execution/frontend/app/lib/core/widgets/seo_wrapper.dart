import 'package:flutter/material.dart';
import '../config/app_env.dart';
import 'seo_wrapper_stub.dart'
    if (dart.library.js_interop) 'seo_wrapper_web.dart';

/// SeoWrapper — injects per-route meta tags into the browser document head.
/// Wrap the top-level widget of each route's page with this.
class SeoWrapper extends StatefulWidget {
  const SeoWrapper({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.ogImage,
    this.canonical,
    this.jsonLd,
    this.jsonLdId,
  });

  final Widget child;
  final String title;
  final String? description;
  final String? ogImage;
  final String? canonical;
  final String? jsonLd;
  final String? jsonLdId;

  @override
  State<SeoWrapper> createState() => _SeoWrapperState();
}

class _SeoWrapperState extends State<SeoWrapper> {
  @override
  void initState() {
    super.initState();
    _updateMeta();
  }

  @override
  void didUpdateWidget(SeoWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.description != widget.description ||
        oldWidget.canonical != widget.canonical ||
        oldWidget.jsonLd != widget.jsonLd) {
      _updateMeta();
    }
  }

  @override
  void dispose() {
    if (widget.jsonLdId != null) {
      try {
        removeJsonLd(widget.jsonLdId!);
      } catch (_) {}
    }
    super.dispose();
  }

  void _updateMeta() {
    try {
      setDocumentTitle('${widget.title} | ${AppEnv.clientName}');

      if (widget.description != null) {
        setMetaContent('description', widget.description!);
        setMetaContent('og:description', widget.description!);
      }

      setMetaContent('og:title', widget.title);

      if (widget.ogImage != null) {
        setMetaContent('og:image', widget.ogImage!);
      }

      if (widget.canonical != null) {
        setCanonical(widget.canonical!);
        setMetaContent('og:url', widget.canonical!);
      }

      if (widget.jsonLd != null && widget.jsonLdId != null) {
        injectJsonLd(widget.jsonLdId!, widget.jsonLd!);
      }
    } catch (_) {
      // Not on web or error — no-op
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
