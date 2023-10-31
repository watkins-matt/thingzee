import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/pages/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';
import 'package:thingzee/pages/settings/state/settings_state.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final navigatorKeyProvider = Provider((_) => navigatorKey);

class App extends ConsumerWidget {
  static Repository? offlineDb;
  static ItemThumbnailCache? thumbnailCache;

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load all thumbnails in the background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (thumbnailCache != null) {
        await thumbnailCache!.loadAllImages();
      }
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: true,
      ),
    );

    final isDarkMode = ref.watch(isDarkModeProvider(context));

    final lightThemeData = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue).copyWith(
        background: Colors.white,
        surfaceTint: Colors.white,
        surfaceVariant: Colors.white,
      ),
      cardColor: Colors.white,
      scaffoldBackgroundColor: const Color.fromARGB(255, 225, 226, 236),
    );

    final darkThemeData = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark().copyWith(
        surfaceTint: Colors.white,
        surfaceVariant: Colors.white,
        primary: Colors.lightBlueAccent,
        secondary: Colors.blueAccent,
        surface: const Color(0xFF202125),
        background: const Color(0xFF2E2F33),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: Colors.grey[400],
        onSurface: Colors.grey[300],
      ),
      cardColor: Colors.grey[900],
      scaffoldBackgroundColor: const Color(0xFF202125),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Thingzee',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const BottomNavBar(),
    );
  }
}
