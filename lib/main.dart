import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/splash_page.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Palette.ground,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const NoberuApp());
}

class NoberuApp extends StatelessWidget {
  const NoberuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noberu',
      debugShowCheckedModeBanner: false,
      theme: noberuTheme(),
      home: const SplashPage(),
    );
  }
}
