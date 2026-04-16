import 'package:app/screens/add_event_screen.dart';
import 'package:app/screens/farmer/farmer_dashboard_screen.dart';
import 'package:app/screens/forgot_password_screen.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/notifications_screen.dart';
import 'package:app/screens/qr_scanner_screen.dart';
import 'package:app/screens/register_screen.dart';
import 'package:app/screens/trace_timeline_screen.dart';
import 'package:app/screens/timeline_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const home = '/';
  static const timeline = '/timeline';
  static const trace = '/trace';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const farmer = '/farmer';
  static const scanner = '/scanner';
  static const addEvent = '/add-event';
  static const notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case home:
        return _page(const HomeScreen());

      case timeline:
        final batchId =
            uri.queryParameters['batchId'] ??
            uri.queryParameters['productId'] ??
            (settings.arguments as String?);
        return _page(TimelineScreen(initialBatchId: batchId));

      case trace:
        final productId =
            uri.queryParameters['productId'] ??
            uri.queryParameters['batchId'] ??
            (settings.arguments as String?);
        return _page(TraceTimelineScreen(productId: productId ?? ''));

      case login:
        return _page(const LoginScreen());

      case register:
        return _page(const RegisterScreen());

      case forgotPassword:
        return _page(const ForgotPasswordScreen());

      case farmer:
        return _page(const FarmerDashboardScreen());

      case scanner:
        return _page(const QrScannerScreen());

      case addEvent:
        final batchId =
            uri.queryParameters['batchId'] ??
            uri.queryParameters['productId'] ??
            (settings.arguments as String?);
        return _page(AddEventScreen(initialBatchId: batchId));

      case notifications:
        return _page(const NotificationsScreen());

      default:
        return _page(const HomeScreen());
    }
  }

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
