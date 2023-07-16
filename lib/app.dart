import 'package:flutter/material.dart';
import 'package:thingzee/pages/home/home_page.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thingzee',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        cardColor: Colors.white,
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
