import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final seen = await Storage.seenWelcome();
  runApp(CardLinkApp(showWelcome: !seen));
}
