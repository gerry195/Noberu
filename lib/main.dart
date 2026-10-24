import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/home_page.dart';
import 'app/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Palette.paper,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const TuturApp());
}

class TuturApp extends StatelessWidget {
  const TuturApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutur',
      debugShowCheckedModeBanner: false,
      theme: tuturTheme(),
      home: const HomePage(),
    );
  }
}
