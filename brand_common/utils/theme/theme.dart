import 'package:raspucat/utils/constants/exports.dart';

class EAppTheme {
  EAppTheme._();

  /// --- LIGHT THEME --- ///
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    textTheme: ETextTheme.lightTextTheme,
    // chipTheme: EChipTheme.lightChipTheme,
    scaffoldBackgroundColor: EColors.backgroundLight,
    // appBarTheme: EAppBarTheme.lightAppBarTheme,
    // drawerTheme: EDrawerTheme.lightDrawerTheme,
    // checkboxTheme: ECheckboxTheme.lightCheckBoxTheme,
    // bottomSheetTheme: EBottomSheetTheme.lightBottomSheetTheme,
    // elevatedButtonTheme: EElevatedButtonTheme.lightElevatedButtonTheme,
    // outlinedButtonTheme: EOutlinedButtonTheme.lightOutlinedButtonTheme,
    // inputDecorationTheme: ETextFormFieldTheme.lightInputDecorationTheme,
    // textButtonTheme: ETextButtonTheme.lightTextButtonTheme,
    // sliderTheme: ESliderTheme.lightSliderTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: EColors.secondary,
      onPrimary: EColors.containerLight,
      secondary: EColors.tertiary,
      onSecondary: EColors.containerLight,
      error: EColors.error,
      onError: EColors.secondary,
      surface: EColors.backgroundDark,
      onSurface: EColors.containerLight,
    ),
  );

  /// --- DARK THEME --- ///
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    textTheme: ETextTheme.darkTextTheme,
    // chipTheme: EChipTheme.darkChipTheme,
    scaffoldBackgroundColor: EColors.backgroundDark,
    // appBarTheme: EAppBarTheme.darkAppBarTheme,
    // checkboxTheme: ECheckboxTheme.darkCheckBoxTheme,
    // bottomSheetTheme: EBottomSheetTheme.darkBottomSheetTheme,
    // elevatedButtonTheme: EElevatedButtonTheme.darkElevatedButtonTheme,
    // outlinedButtonTheme: EOutlinedButtonTheme.darkOutlinedButtonTheme,
    // inputDecorationTheme: ETextFormFieldTheme.lightInputDecorationTheme,
    // textButtonTheme: ETextButtonTheme.darkTextButtonTheme,
    // sliderTheme: ESliderTheme.darkSliderTheme,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: EColors.primary,
      onPrimary: EColors.containerDark,
      secondary: EColors.tertiary,
      onSecondary: EColors.containerDark,
      error: EColors.error,
      onError: EColors.primary,
      surface: EColors.backgroundDark,
      onSurface: EColors.containerDark,
    ),
  );
}
