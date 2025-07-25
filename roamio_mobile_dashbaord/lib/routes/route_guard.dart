// import 'package:go_router/go_router.dart';
import '../core/utils/storage_helper.dart';

class RouteGuard {
  static Future<String?> redirectIfNotAuth(_, __) async {
    final token = await StorageHelper.getToken();
    return token == null ? '/login' : null;
  }
}