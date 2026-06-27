import 'package:app/screens/camera_management_screen.dart';
import 'package:app/screens/add_event_screen.dart';
import 'package:app/screens/farmer/farmer_dashboard_screen.dart';
import 'package:app/screens/forgot_password_screen.dart';
import 'package:app/screens/edit_product_screen.dart';
import 'package:app/screens/disease_detection_screen.dart';
import 'package:app/screens/management_hub_screen.dart';
import 'package:app/screens/product_trash_screen.dart';
import 'package:app/models/batch.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/notifications_screen.dart';
import 'package:app/screens/qr_scanner_screen.dart';
import 'package:app/screens/register_screen.dart';
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
  static const cameras = '/cameras';
  static const management = '/management';
  static const editProduct = '/edit-product';
  static const diseaseDetection = '/disease-detection';
  static const productTrash = '/product-trash';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case home:
        return _page(const HomeScreen());

      case timeline:
      case trace:
        final batchId =
            uri.queryParameters['batchId'] ??
            uri.queryParameters['productId'] ??
            (settings.arguments as String?);
        return _page(TimelineScreen(initialBatchId: batchId));

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

      case cameras:
        final batchId =
            uri.queryParameters['batchId'] ??
            uri.queryParameters['productId'] ??
            (settings.arguments as String?);
        if (batchId == null || batchId.isEmpty) {
          return _page(const FarmerDashboardScreen());
        }
        return _page(CameraManagementScreen(batchId: batchId));

      case management:
        final tab = int.tryParse(uri.queryParameters['tab'] ?? '') ?? 0;
        return _page(ManagementHubScreen(initialTab: tab));

      case editProduct:
        final batch = settings.arguments as Batch?;
        if (batch == null) return _page(const FarmerDashboardScreen());
        return _page(EditProductScreen(batch: batch));

      case diseaseDetection:
        return _page(const DiseaseDetectionScreen());

      case productTrash:
        return _page(const ProductTrashScreen());

      default:
        return _page(const HomeScreen());
    }
  }

  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }
}
