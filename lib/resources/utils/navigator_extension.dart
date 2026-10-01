part of '../config/utils.dart';

extension NavigatorExtension on NavigatorState {
  static int counter = 0;

  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    counter++;
    return push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    ).then((result) {
      counter--;
      return result;
    });
  }

  static Future<T?> show<T>(BuildContext context, Widget modal, {bool barrierDismissible = true}) {
    return showGeneralDialog(
      context: context,
      barrierLabel: 'Dismiss',
      barrierDismissible: barrierDismissible,
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ).drive(Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, _) => modal,
    );
  }
}
