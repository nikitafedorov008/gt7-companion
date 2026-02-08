import 'package:flutter/widgets.dart';
import 'package:gt7_companion/utils/platform_utils.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PlatformUtils.configurePlatformWindowUtils();
  runApp(const App());
}