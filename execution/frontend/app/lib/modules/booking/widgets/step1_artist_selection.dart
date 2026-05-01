import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/booking_controller.dart';
import '../models/artist_model.dart';
import 'artist_card.dart';

class Step1ArtistSelection extends GetView<BookingController> {
  const Step1ArtistSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < ESpacing.mobileBreak;
    final hPad = isMobile ? ESpacing.md : ESpacing.xxl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 01', style: ETextStyles.overline),
              const SizedBox(height: ESpacing.sm),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: ESpacing.md),
              Text('CHOOSE YOUR ARTIST', style: ETextStyles.h2),
              const SizedBox(height: ESpacing.sm),
              Text(
                'Select an artist or let us match you.',
                style: ETextStyles.bodyMuted,
              ),
            ],
          ),
        ),
        Obx(() {
          if (controller.isLoading.value) {
            return const Expanded(
                child: Center(child: CircularProgressIndicator()));
          }
          return Expanded(
            child: _ArtistGrid(
              artists: controller.artists,
              selectedArtistId: controller.selectedArtist.value?.id,
              isAnyArtist: controller.isAnyArtist.value,
              onSelectArtist: controller.selectArtist,
              onSelectAny: controller.selectAnyArtist,
              isMobile: isMobile,
              hPad: hPad,
            ),
          );
        }),
        Obx(() => _BottomBar(
              canContinue: controller.canProceedStep1,
              onContinue: controller.proceedFromStep1,
            )),
      ],
    );
  }
}

class _ArtistGrid extends StatelessWidget {
  const _ArtistGrid({
    required this.artists,
    required this.selectedArtistId,
    required this.isAnyArtist,
    required this.onSelectArtist,
    required this.onSelectAny,
    required this.isMobile,
    required this.hPad,
  });

  final List<ArtistModel> artists;
  final String? selectedArtistId;
  final bool isAnyArtist;
  final void Function(ArtistModel) onSelectArtist;
  final VoidCallback onSelectAny;
  final bool isMobile;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    final cards = [
      AnyArtistCard(isSelected: isAnyArtist, onTap: onSelectAny),
      ...artists.asMap().entries.map((e) => ArtistCard(
            artist: e.value,
            isSelected: selectedArtistId == e.value.id,
            onTap: () => onSelectArtist(e.value),
          )),
    ];

    if (isMobile) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: ESpacing.sm),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: ESpacing.md),
        itemBuilder: (_, i) => cards[i],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Wrap(
        spacing: ESpacing.md,
        runSpacing: ESpacing.md,
        children: cards,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.canContinue, required this.onContinue});
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.lg, vertical: ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border(
            top: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: canContinue ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 250),
            child: ElevatedButton(
              onPressed: canContinue ? onContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                foregroundColor: EColors.secondary,
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(
                    horizontal: ESpacing.xl, vertical: ESpacing.md),
              ),
              child: Text('CONTINUE', style: ETextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}
