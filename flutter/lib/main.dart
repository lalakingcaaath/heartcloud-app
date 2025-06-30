import 'package:flutter/material.dart';
import 'package:heartcloud/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:heartcloud/utils/auth_provider.dart';
import 'package:heartcloud/utils/wrapper.dart';
import 'package:provider/provider.dart';

void main() async {
  // These two lines are required for Firebase to work.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  // Converted to a StatelessWidget for simplicity as state is now managed by Provider.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap our entire app in a ChangeNotifierProvider.
    // This makes one instance of AuthProvider available to all screens below it.
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HeartCloud',

        // The home of our app is now the Wrapper. It will handle showing
        // the login page or homepage based on the auth state, effectively
        // replacing your SplashScreen's navigation logic.
        home: const Wrapper(),
        theme: ThemeData.light(),
        themeMode: ThemeMode.light,

        // The old routes are no longer needed here as the Wrapper handles this logic.
      ),
    );
  }
}
