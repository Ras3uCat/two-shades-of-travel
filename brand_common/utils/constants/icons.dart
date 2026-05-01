import 'package:raspucat/utils/constants/exports.dart';

class EIcons {
  EIcons._();

  /// ------------------------------------------------------------------ ///
  /// HELPER FUNCTIONS
  ///
  ///

  /// --- CHANGE DEFINED ICONS COLOR OR SIZE --- ///
  static Icon iconModify(Icon icon, {Color? color, double? size}) {
    return Icon(icon.icon, color: color ?? icon.color, size: size ?? icon.size);
  }

  /// ------------------------------------------------------------------ ///
  /// SOCIAL MEDIA ICONS
  ///
  ///

  /// --- FOLLOW --- ///
  static const Icon follow = Icon(FontAwesomeIcons.bell, color: EColors.accent);

  /// --- FACEBOOK --- ///
  static const Icon facebook = Icon(
    FontAwesomeIcons.facebook,
    color: EColors.accent,
  );

  /// --- GOOGLE --- ///
  static const Icon google = Icon(
    FontAwesomeIcons.google,
    color: EColors.accent,
  );

  /// --- TWITCH --- ///
  static const Icon twitch = Icon(FontAwesomeIcons.twitch);
  static const Icon twitchHover = Icon(
    FontAwesomeIcons.twitch,
    color: EColors.accent,
  );

  /// --- YOUTUBE --- ///
  static const Icon youtube = Icon(FontAwesomeIcons.youtube);
  static const Icon youtubeHover = Icon(
    FontAwesomeIcons.youtube,
    color: EColors.accent,
  );

  /// --- INSTAGRAM --- ///
  static const Icon instagram = Icon(FontAwesomeIcons.instagram);
  static const Icon instagramHover = Icon(
    FontAwesomeIcons.instagram,
    color: EColors.accent,
  );
  // FaIcon(FontAwesomeIcons.instagram, color: EColors.secondary);

  /// --- NEWSLETTER --- ///
  static const Icon newsletter = Icon(FontAwesomeIcons.envelope);
  static const Icon newsletterHover = Icon(
    FontAwesomeIcons.envelope,
    color: EColors.accent,
  );

  /// ------------------------------------------------------------------ ///
  /// GENERAL ICONS
  ///
  ///

  /// --- FORMS --- ///
  static const Icon user = Icon(
    FontAwesomeIcons.solidUser,
    color: EColors.secondary,
  );
  static const Icon email = Icon(FontAwesomeIcons.solidEnvelope);
  static const Icon reason = Icon(FontAwesomeIcons.question);

  /// --- MENU --- ///
  static const Icon enter = Icon(
    FontAwesomeIcons.arrowRight,
    color: EColors.secondary,
  );

  /// --- CLOSE --- ///
  static const Icon close = Icon(
    FontAwesomeIcons.xmark,
    color: EColors.secondary,
  );

  /// --- SERACH --- ///
  static const Icon search = Icon(
    FontAwesomeIcons.magnifyingGlass,
    color: EColors.accent,
  );

  /// --- CODE --- ///
  static const Icon code = Icon(FontAwesomeIcons.code, color: EColors.primary);

  /// --- LAUNCH --- ///
  static const Icon launch = Icon(
    FontAwesomeIcons.rocket,
    color: EColors.primary,
  );

  /// --- NOTIFICATION --- ///
  static const Icon notifications = Icon(
    FontAwesomeIcons.bell,
    color: EColors.accent,
  );

  /// --- DOWNLOAD --- ///
  static const Icon download = Icon(
    FontAwesomeIcons.download,
    color: EColors.accent,
  );

  /// --- MICROPHONE --- ///
  static const Icon microphone = Icon(
    FontAwesomeIcons.microphone,
    color: EColors.accent,
  );

  /// --- MUSIC NOTE --- ///
  static const Icon musicNote = Icon(
    FontAwesomeIcons.music,
    color: EColors.accent,
  );

  /// --- SOUNDWAVE--- ///
  static const Icon soundwave = Icon(Icons.graphic_eq, color: EColors.accent);

  /// --- SUCCESS --- ///
  static const Icon success = Icon(
    FontAwesomeIcons.check,
    color: EColors.accent,
  );

  /// --- ERROR --- ///
  static const Icon error = Icon(FontAwesomeIcons.xmark, color: EColors.accent);

  /// --- WARNING --- ///
  static const Icon warning = Icon(
    FontAwesomeIcons.triangleExclamation,
    color: EColors.accent,
  );
}
