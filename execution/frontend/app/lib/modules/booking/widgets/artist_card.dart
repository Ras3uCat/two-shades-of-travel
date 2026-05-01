import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/artist_model.dart';

class ArtistCard extends StatefulWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final ArtistModel artist;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _hovered = false;

  double get _width  => widget.compact ? 120.0 : 200.0;
  double get _height => widget.compact ? 160.0 : 260.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: EColors.surfaceVariant,
            border: Border.all(
              color: widget.isSelected
                  ? EColors.primary
                  : _hovered
                      ? EColors.onSurfaceMuted
                      : EColors.divider,
              width: widget.isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Stack(
            children: [
              if (widget.artist.photoUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.artist.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: EColors.surfaceVariant),
                    errorWidget: (_, _, _) =>
                        _PhotoPlaceholder(name: widget.artist.name),
                  ),
                )
              else
                Positioned.fill(
                  child: _PhotoPlaceholder(name: widget.artist.name),
                ),
              // Bottom overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding:
                      EdgeInsets.all(widget.compact ? ESpacing.sm : ESpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        EColors.secondary.withValues(alpha: 0.95),
                        EColors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.artist.name,
                        style: widget.compact
                            ? ETextStyles.labelSm
                            : ETextStyles.h4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!widget.compact && widget.artist.specialty.isNotEmpty) ...[
                        const SizedBox(height: ESpacing.xs),
                        Text(
                          widget.artist.specialty.toUpperCase(),
                          style: ETextStyles.labelSm.copyWith(
                              color: EColors.primaryMedium),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Corner accents when selected
              if (widget.isSelected)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CornerAccentPainter(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EColors.surfaceVariant,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: ETextStyles.displayMd.copyWith(
              color: EColors.onSurfaceMuted),
        ),
      ),
    );
  }
}

class _CornerAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const arm = 16.0;
    canvas.drawLine(Offset.zero, const Offset(arm, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, arm), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - arm, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - arm), paint);
  }

  @override
  bool shouldRepaint(_CornerAccentPainter old) => false;
}

/// Special "Any Artist" card shown at the top of Step 1.
class AnyArtistCard extends StatefulWidget {
  const AnyArtistCard({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<AnyArtistCard> createState() => _AnyArtistCardState();
}

class _AnyArtistCardState extends State<AnyArtistCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 200.0,
          height: 260.0,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? EColors.primary.withValues(alpha: 0.08)
                : _hovered
                    ? EColors.surfaceVariant
                    : EColors.secondary,
            border: Border.all(
              color: widget.isSelected ? EColors.primary : EColors.divider,
              width: widget.isSelected ? 1.0 : 0.5,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shuffle_rounded,
                  color: widget.isSelected
                      ? EColors.primary
                      : EColors.onSurfaceMuted,
                  size: ESpacing.xl,
                ),
                const SizedBox(height: ESpacing.md),
                Text(
                  'ANY ARTIST',
                  style: ETextStyles.h4.copyWith(
                    color: widget.isSelected
                        ? EColors.primary
                        : EColors.onSurface,
                  ),
                ),
                const SizedBox(height: ESpacing.xs),
                Text(
                  "Show me who's available",
                  style: ETextStyles.bodySm.copyWith(
                      color: EColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
