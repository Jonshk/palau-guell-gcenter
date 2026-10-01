import 'package:flutter/material.dart';

class AppTheme {

  /* // Brand colors
  static const Color primary    = Color(0xFFBCBFA7);
  static const Color secondary  = Color(0xFF9B977C);
  static const Color tertiary   = Color(0xFFF6BD41);
  static const Color quaternary = Color(0xFFA9A9A9); // neutral
  static const Color brown      = Color(0xFF9B877C); // accent / brand support

  // Dark (texts / icons)
  static const Color dark  = Color(0xFF1C1C1C); // texto principal
  static const Color dark1 = Color(0xFF333333); // texto secundario
  static const Color dark2 = Color(0xFF5A5A5A); // disabled / hint

  // Light (backgrounds / surfaces)
  static const Color light  = Color(0xFFFDFCFA); // background
  static const Color light1 = Color(0xFFF5F5F2); // surface
  static const Color light2 = Color(0xFFE6E6E1); // surface variant
  static const Color light3 = Color(0xFFD6D6D0); // borders / dividersv */
  
  static const Color primary900 = Color(0xff252621);

  static const Color primary800 = Color(0xff4b4c42);

  static const Color primary700 = Color(0xff707264);

  static const Color primary600 = Color(0xff969885);

  static const Color primary500 = Color(0xffbcbfa7);

  static const Color primary400 = Color(0xffc9cbb8);

  static const Color primary300 = Color(0xffd6d8ca);

  static const Color primary200 = Color(0xffe4e5db);

  static const Color primary100 = Color(0xfff1f2ed);

  static const Color secondary900 = Color(0xff1e1e18);

  static const Color secondary800 = Color(0xff3d3c31);

  static const Color secondary700 = Color(0xff5d5a4a);

  static const Color secondary600 = Color(0xff7c7863);

  static const Color secondary500 = Color(0xff9b977c);

  static const Color secondary400 = Color(0xffafab96);

  static const Color secondary300 = Color(0xffc3c0b0);

  static const Color secondary200 = Color(0xffd7d5ca);

  static const Color secondary100 = Color(0xffebeae4);

  static const Color terciary900 = Color(0xff31250c);

  static const Color terciary800 = Color(0xff624b19);

  static const Color terciary700 = Color(0xff937127);

  static const Color terciary600 = Color(0xffc49734);

  static const Color terciary500 = Color(0xfff6bd41);

  static const Color terciary400 = Color(0xfff7ca67);

  static const Color terciary300 = Color(0xfff9d78d);

  static const Color terciary200 = Color(0xfffbe4b3);

  static const Color terciary100 = Color(0xfffdf1d9);

  static const Color neutral900 = Color(0xff212121);

  static const Color neutral800 = Color(0xff434343);

  static const Color neutral700 = Color(0xff656565);

  static const Color neutral600 = Color(0xff878787);

  static const Color neutral500 = Color(0xffa9a9a9);

  static const Color neutral400 = Color(0xffbababa);

  static const Color neutral300 = Color(0xffcbcbcb);

  static const Color neutral200 = Color(0xffdcdcdc);

  static const Color neutral100 = Color(0xffececec);

  static const Color marron900 = Color(0xff1e1a18);

  static const Color marron800 = Color(0xff3d3531);

  static const Color marron700 = Color(0xff5d514a);

  static const Color marron600 = Color(0xff7c6c63);

  static const Color marron500 = Color(0xff9b877c);

  static const Color light = Color(0xffffffff);

  static const Color dark = Color(0xFF000000);

  static const Color marron400 = Color(0xffaf9f96);

  static const Color marron300 = Color(0xffc3b7b0);

  static const Color marron200 = Color(0xffd7cfca);

  static const Color marron100 = Color(0xffebe7e4);

  static const String fontPrimary = "geist";

  static const String fontSecondary = "archivo";

  /// Respaldo para los caracteres que geist y archivo no cubren (kana y kanji).
  /// Solo entra en juego para esos glifos: el latin y los numeros siguen en la
  /// fuente principal, asi que no altera la tipografia del resto de idiomas.
  static const List<String> fontFallback = ["NotoSansJP"];

  static final ThemeData theme = ThemeData(
    //scaffoldBackgroundColor: light,
    brightness: Brightness.light,
    fontFamily: fontPrimary,
    fontFamilyFallback: fontFallback,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
  );
}
