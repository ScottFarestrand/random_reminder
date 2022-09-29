import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._privateConstructor();

  static final NavigationService _instance =
  NavigationService._privateConstructor();

  static NavigationService get instance {
    print("Got Nav Instance");
    return _instance;
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> push(Widget widget) async {
    return navigatorKey.currentState!.push(
      // MaterialPageRoute(
      //   builder: (ctx) => widget,
      // ),
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => widget,
        // settings: RouteSettings(name: routeName),
        transitionsBuilder: (c, animation, a2, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void pop() {
    navigatorKey.currentState!.pop();
  }
}
