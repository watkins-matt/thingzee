import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:repository/repository.dart';
import 'package:thingzee/pages/home/home_page.dart';

class App extends StatelessWidget {
  static late Repository repo;
  static Logger log = Logger(
    printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: false,
        printTime: true),
  );

  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thingzee',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}
