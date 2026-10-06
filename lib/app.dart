import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/contact_data.dart';
import 'screens/contact_editor.dart';
import 'screens/crop_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_card_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shell.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';

GoRouter _buildRouter(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Shell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/card', builder: (_, __) => const MyCardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
            ]),
          ],
        ),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(
          path: '/review',
          builder: (_, state) => ContactEditor(
            initial: state.extra as ContactData,
            mode: EditorMode.review,
          ),
        ),
        GoRoute(
          path: '/edit-card',
          builder: (_, state) => ContactEditor(
            initial: state.extra as ContactData,
            mode: EditorMode.profile,
          ),
        ),
        GoRoute(path: '/qr', builder: (_, __) => const QrScreen()),
        GoRoute(
          path: '/crop',
          builder: (_, state) => CropScreen(imageBytes: state.extra as Uint8List),
        ),
      ],
    );

class CardLinkApp extends StatefulWidget {
  const CardLinkApp({super.key, required this.showWelcome});
  final bool showWelcome;

  @override
  State<CardLinkApp> createState() => _CardLinkAppState();
}

class _CardLinkAppState extends State<CardLinkApp> {
  late final GoRouter _router = _buildRouter(widget.showWelcome ? '/welcome' : '/home');

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'CardLink',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      );
}
