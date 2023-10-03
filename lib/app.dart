import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/pages/bottom_nav_bar/bottom_nav_bar.dart';
import 'package:thingzee/pages/inventory/state/item_thumbnail_cache.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final navigatorKeyProvider = Provider((_) => navigatorKey);

class App extends StatelessWidget {
  static Repository? offlineDb;
  static ItemThumbnailCache? thumbnailCache;

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Load all thumbnails in the background
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (thumbnailCache != null) {
        await thumbnailCache!.loadAllImages();
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Thingzee',
      theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          cardColor: Colors.white,
          scaffoldBackgroundColor: Theme.of(context).colorScheme.surfaceVariant),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Theme.of(context).colorScheme.surfaceVariant),
      themeMode: ThemeMode.light,
      home: const BottomNavBar(),
    );
  }
}
