/// --- GLOBAL EXPORTS --- ///
///
///

library;

/// ------------------------------------------------------------------ ///
/// RESPONSIVE
///
///
///
export 'package:raspucat/common/responsive/responsive_screen.dart';
export 'package:raspucat/common/responsive/responsive_layout.dart';
export 'package:raspucat/common/responsive/screens/desktop_layout.dart';
export 'package:raspucat/common/responsive/screens/mobile_layout.dart';
export 'package:raspucat/common/responsive/screens/tablet_layout.dart';

/// ------------------------------------------------------------------ ///
/// SCREENS
///
///
///
export 'package:raspucat/app/modules/screens/home_screen.dart';

/// ------------------------------------------------------------------ ///
/// CONTROLLERS
///
///
///
export 'package:raspucat/app/controllers/scroll_controller.dart';
export 'package:raspucat/app/controllers/gradient_controller.dart';
export 'package:raspucat/app/controllers/triangle_controller.dart';
export 'package:raspucat/app/controllers/scroll_animation_controller.dart';
export 'package:raspucat/app/controllers/carousel_controller.dart';

/// ------------------------------------------------------------------ ///
/// CONSTANTS
///
///
///
export 'package:raspucat/utils/constants/brand.dart';
export 'package:raspucat/utils/constants/colors.dart';
export 'package:raspucat/utils/constants/text.dart';
export 'package:raspucat/utils/constants/sizes.dart';
export 'package:raspucat/utils/constants/images.dart';
export 'package:raspucat/utils/constants/icons.dart';
export 'package:raspucat/utils/constants/durations.dart';
export 'package:raspucat/utils/device/device_utility.dart';

/// ------------------------------------------------------------------ ///
/// WIDGETS
///
///
///
export 'package:raspucat/common/navbar/navbar.dart';
export 'package:raspucat/common/widgets/containers/section_container.dart';
export 'package:raspucat/common/widgets/triangles/background_triangles.dart';
export 'package:raspucat/common/widgets/triangles/triangle_widget.dart';
export 'package:raspucat/app/modules/widgets/center_logo.dart';
export 'package:raspucat/common/widgets/text/neon_text.dart';
export 'package:raspucat/common/widgets/gradients/gradient_overlay.dart';
export 'package:raspucat/common/widgets/branding/m3ow_brand_mark.dart';
export 'package:raspucat/common/widgets/buttons/neon_button.dart';
export 'package:raspucat/common/widgets/animations/animation_on_view.dart';
export 'package:raspucat/common/widgets/cards/project_card.dart';
export 'package:raspucat/common/widgets/carousel/projects_carousel.dart';
export 'package:raspucat/app/modules/widgets/project_screen.dart';
export 'package:raspucat/common/widgets/dialogs/dialog.dart';

/// ------------------------------------------------------------------ ///
/// PAINTERS
///
///
///
export 'package:raspucat/common/painters/triangle_painter.dart';
export 'package:raspucat/common/painters/triangle_navigation_painter.dart';

/// ------------------------------------------------------------------ ///
/// APP THEMES
///
///
///
export 'package:raspucat/utils/theme/theme.dart';
export 'package:raspucat/utils/theme/custom_theme/text_theme.dart';

/// ------------------------------------------------------------------ ///
/// BINDINGS
///
///
///
export 'package:raspucat/bindings.dart/general_bindings.dart';

/// ------------------------------------------------------------------ ///
/// MODELS
///
///
///
export 'package:raspucat/app/data/models/project_model.dart';
export 'package:raspucat/app/data/models/triangle_model.dart';

/// ------------------------------------------------------------------ ///
/// DATA
///
///
///
export 'package:raspucat/app/data/projects/project_data.dart';

/// ------------------------------------------------------------------ ///
/// ROUTES
///
///
///
export 'package:raspucat/routes/app_routes.dart';
export 'package:raspucat/routes/routes.dart';

/// ------------------------------------------------------------------ ///
/// FLUTTER PACKAGES
///
///
///
export 'package:flutter/material.dart';
export 'dart:math';
export 'dart:io' hide HeaderValue;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:url_launcher/url_launcher_string.dart';

/// ------------------------------------------------------------------ ///
/// PUB PACKAGES
///
///
///
export 'package:get/get.dart';
export 'package:google_fonts/google_fonts.dart';
export 'package:flutter_svg/flutter_svg.dart';
export 'package:auto_size_text/auto_size_text.dart';
export 'package:visibility_detector/visibility_detector.dart';
export 'package:carousel_slider/carousel_slider.dart';
export 'package:smooth_page_indicator/smooth_page_indicator.dart';
export 'package:font_awesome_flutter/font_awesome_flutter.dart';
