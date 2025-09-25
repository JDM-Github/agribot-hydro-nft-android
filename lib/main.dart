import 'package:android/screens/loading.dart';
import 'package:android/store/data.dart';
import 'package:flutter/material.dart';
import 'package:android/screens/registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = UserDataStore();
  // store.reset();
  await store.loadData();
  runApp(MyApp(store: store));
}

class MyApp extends StatefulWidget {
  final UserDataStore store;
  const MyApp({super.key, required this.store});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGRIBOT Application',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: widget.store.isLoggedIn()
          ? LoadingScreen(store: widget.store)
          : AuthScreen(
              toggleTheme: _toggleTheme,
              user: widget.store.user.value,
              updateUser: (newUser) => setState(() => widget.store.user.value = newUser),
            ),
    );
  }
}
