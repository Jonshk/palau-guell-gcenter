import '/config.dart';

abstract class AppRoutes {
  static const splash = "/splash";
  static const languages = "/languages";
  static const home = "/home";
  static const menu = "/menu";
  static const tours = "/tours";
  static const tree = "/tree";
  static const survey = "/survey";
}

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.languages, page: () => const LanguagePage(), transition: Transition.rightToLeft),
    GetPage(name: AppRoutes.home, page: () => const HomePage(), transition: Transition.rightToLeft),
    GetPage(
      name: AppRoutes.menu,
      page: () => const MenuPage(),
      curve: Curves.easeInOut,
      transition: Transition.rightToLeft,
    ),
    GetPage(name: AppRoutes.tours, page: () => TourView(), transition: Transition.fadeIn),
    GetPage(name: AppRoutes.tree, page: () => TreeView()),
    GetPage(name: AppRoutes.survey, page: () => SurveyPage()),
  ];
}
