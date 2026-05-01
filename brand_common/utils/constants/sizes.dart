import 'package:raspucat/utils/constants/exports.dart';

class ESizes {
  ESizes._();

  /// ------------------------------------------------------------------ ///
  /// POSITIONS
  ///
  ///
  ///

  /// --- Global Positions ---///
  static const double headerCircleOneTop = -150;
  static const double headerCircleOneRight = -250;
  static const double headerCircleTwoTop = 100;
  static const double headerCircleTwoRight = -300;

  /// --- Responsive Sizes --- ///
  static const double mobile = 700;
  static const double tablet = 1185;
  // static const double desktop =

  /// --- Elevation Sizes ---///
  static const double elevationMd = 5;
  static const double elevationSm = 3;

  /// ------------------------------------------------------------------ ///
  /// SHIMMER EFFECTS
  ///
  ///
  ///

  /// --- Rounded Image Shimmer ---///
  static const double shimmerRoundImageHeight = 158;

  /// --- Profile Image Shimmer ---///
  static const double shimmerProfileImage = 80;

  /// --- Box Shimmer ---///
  static const double shimmerBoxHeight = 110;
  static const double shimmerBoxWidth = 150;

  /// --- Brand Shimmer ---///
  static const double shimmerBrandHeight = sectionMd;
  static const double shimmerBrandWidth = section4Xl;

  /// --- Category Shimmer ---///
  static const double shimmerCategoryHeight = 55;
  static const double shimmerCategoryWidth = 55;
  static const double shimmerCategoryRadius = 55;
  static const double shimmerCategoryTextHeight = 8;

  /// --- Horizontal Product Shimmer ---///
  static const double shimmerHorizontalProductHeight = sectionXl;
  static const double shimmerHorizontalProductWidth = sectionXl;
  static const double shimmerHorizontalProductTextHeight = 15;
  static const double shimmerHorizontalProductTextWidth1 = 160;
  static const double shimmerHorizontalProductTextWidth2 = 110;
  static const double shimmerHorizontalProductTextWidth3 = 80;

  /// --- Vertical Product Shimmer ---///
  static const double shimmerVerticalProductHeight = 180;
  static const double shimmerVerticalProductWidth = 180;
  static const double shimmerVerticalProductTextHeight = 15;
  static const double shimmerVerticalProductTextWidth1 = 160;
  static const double shimmerVerticalProductTextWidth2 = 110;
  static const double shimmerVerticalProductTextWidth3 = 80;

  /// --- List Card Shimmer ---///
  static const double shimmerListCardHeight = 50;
  static const double shimmerListCardWidth = 50;
  static const double shimmerListCardRadius = 50;
  static const double shimmerListCardTextWidth1 = 100;
  static const double shimmerListCardTextWidth2 = 80;
  static const double shimmerListCardTextHeight1 = 15;
  static const double shimmerListCardTextHeight2 = 12;

  /// ------------------------------------------------------------------ ///
  /// COMMON
  ///
  ///
  ///

  /// --- GENERAL SIZES --- ///
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  /// --- Default Spacing Between Selections --- ///
  static const double defaultSpace = 24.0;
  static const double spaceBtwItems = 16.0; // --- Using on About Page
  static const double spaceBtwSections = 32.0; // --- Using on Home Page

  /// --- Divider Sizes --- ///
  static const double dividerHeight = 1.0;

  /// --- Section Sizes --- ///
  static const double section2Xs = 35;
  static const double sectionXs = 50; // --- Using on Drawer
  static const double sectionSm = 56;
  static const double sectionMd = 80;
  static const double sectionLg = 100;
  static const double sectionXl = 120;
  static const double section2Xl = 172;
  static const double section3Xl = 190;
  static const double section4Xl = 300;
  static const double section5Xl = 400;

  /// --- Border Radius --- ///
  static const double borderRadiusSM = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 32;
  static const double borderRadiusXxl = 100;

  /// --- Border Width --- ///
  static const double borderWidthMd = 2;

  /// ------------------------------------------------------------------ ///
  /// ICONS
  ///
  ///
  /// --- Icon Sizes --- ///
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double navDotSize = 6;

  /// ------------------------------------------------------------------ ///
  /// SHADOWS
  ///
  ///
  /// --- Shadow Sizes --- ///
  static const double blurRadiusMd = 50;
  static const double spreadRadiusMd = 7;
  static const Offset offsetMd = Offset(0, 2);

  /// ------------------------------------------------------------------ ///
  /// FONTS
  ///
  ///
  /// --- Font Sizes --- ///
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeHeadline = 32;
  static const double fontSizeTitle = 30;
  static const double fontSizeBody = 20;
  static const double fontSizeLabel = 12;

  /// --- Text Widths --- ///
  static const double textUnderIconWidth = 56;

  /// ------------------------------------------------------------------ ///
  /// BUTTONS
  ///
  ///
  /// --- Button Sizes --- ///
  static const double buttonHeight = 18.0;
  static const double buttonRadius = 12.0;
  static const double buttonWidth = 120.0;
  static const double buttonElevation = 4.0;

  /// ------------------------------------------------------------------ ///
  /// CONTAINERS
  ///
  ///
  // --- Card Sizes --- ///
  static const double cardRadiusXs = 6.0;
  static const double cardRadiusSm = 10.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusLg = 16.0;
  static const double cardElevation = 2.0;
  static const double carouselWidth = 500;

  /// ------------------------------------------------------------------ ///
  /// APPBARS
  ///
  ///
  /// --- AppBar Sizes --- ///
  static const double appBarHeight = 56.0;
  static const double appBarPaddingLeft = 0;
  static const double appBarPaddingRight = 0;
  static const double appBarRadius = 16;

  /// --- Sliver AppBar Height --- ///
  static const double sliverAppBarHeight = 440;

  /// ------------------------------------------------------------------ ///
  /// PADDING
  ///
  ///
  /// --- Padding Sizes --- ///
  static const EdgeInsetsGeometry paddingWithAppBarHeight = EdgeInsets.only(
    top: ESizes.appBarHeight,
    left: ESizes.defaultSpace,
    bottom: ESizes.defaultSpace,
    right: ESizes.defaultSpace,
  );

  /// ------------------------------------------------------------------ ///
  /// --- IMAGE SIZZES --- ///
  ///
  ///
  ///

  /// --- IMAGE --- ///
  static const double imageThumbSize = 80.0;
  static const double imageSizeSm = 60;
  static const double imageSizeMd = 100.0;
  static const double imageSizeLg = 200.0;
  static const double imageSizeXl = 300;
  static const double imageSizeXxl = 500.0;

  /// --- Circle Image Sizes --- ///
  static const double circleImageSizeLg = 56;
  static const double circleImageSizeMd = 50;
  static const double circleImageSizeSm = 32;
  static const double circleImageSizeXs = 25;

  // Product Item Sizes
  static const double productImageWidth = 150.0;
  static const double productImageRadius = 16.0;
  static const double productImageHeight = 120.0;
  static const double productImageBrandCardHeight = 100;

  /// --- Upload Image Sizes --- ///
  static const int uploadImageQuality = 70;
  static const double uploadImageMaxHeight = 512;
  static const double uploadImageMaxWidth = 512;

  /// ------------------------------------------------------------------ ///
  /// FIELD FORMS
  ///
  ///
  /// Input Field Radius
  static const double inputFieldRadius = 12.0;

  /// Input Field Spacing
  static const double spaceBtwInputFields = 16.0;

  /// ------------------------------------------------------------------ ///
  /// CAROUSEL SIZES
  ///
  ///
  /// Carousel Height
  static const double carouselHeightMd = 400.0;

  /// ------------------------------------------------------------------ ///
  /// LOADING INDICATOR
  ///
  ///
  /// Loading Indicator Sizes
  static const double loadingIndiatorSize = 36.0;

  /// ------------------------------------------------------------------ ///
  /// GRID VIEW SIZES
  ///
  ///
  ///
  static const double gridViewSpacing = 16.0;
  static const double gridViewExtentLg = 210;
  static const double gridViewExtentSm = 80;
  static const int gridViewCrossAxisCount = 2;

  /// ------------------------------------------------------------------ ///
  /// FORM DIVIDER SIZES
  ///
  ///
  ///
  static const double formDividerThickness = 0.5;
  static const double formDividerIndentOne = 60;
  static const double formDividerIndentTwo = 5;
}
