import 'package:raspucat/utils/constants/exports.dart';

final AutoSizeGroup headline = AutoSizeGroup();
final AutoSizeGroup defaultGroup = AutoSizeGroup();

/// --- REUSABLE NEON TEXT WIDGET --- ///
class NeonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Color neonColor;
  final bool isHeadline;

  const NeonText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.neonColor = EColors.primary,
    this.isHeadline = true,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isIOS = EDeviceUtils.isIOS();
    return isIOS
        ? FittedBox(
            child: Text(
              text,
              style: (style ?? const TextStyle()).copyWith(
                shadows: [
                  for (double i = 1; i < 4; i++)
                    Shadow(
                      color: neonColor.withOpacity(1 - (i * 0.2)),
                      blurRadius: 3 * i,
                    ),
                ],
              ),
              textAlign: textAlign ?? TextAlign.center,

              softWrap: true,
              maxLines: 2,

              strutStyle: StrutStyle(
                forceStrutHeight: true,
                height: 0.7,
                leading: 0,
                fontSize: style?.fontSize,
                fontFamily: style?.fontFamily,
                fontWeight: style?.fontWeight,
              ),
            ),
          )
        : AutoSizeText(
            group: isHeadline ? headline : defaultGroup,
            text,
            style: (style ?? const TextStyle()).copyWith(
              shadows: [
                for (double i = 1; i < 4; i++)
                  Shadow(
                    color: neonColor.withOpacity(1 - (i * 0.2)),
                    blurRadius: 3 * i,
                  ),
              ],
            ),
            textAlign: textAlign ?? TextAlign.center,
            stepGranularity: 1,
            wrapWords: false,
            softWrap: true,
            maxLines: 2,

            strutStyle: StrutStyle(
              forceStrutHeight: true,
              height: 0.7,
              leading: 0,
              fontSize: style?.fontSize,
              fontFamily: style?.fontFamily,
              fontWeight: style?.fontWeight,
            ),
          );
  }
}
// if (EDeviceUtils.isIOS())