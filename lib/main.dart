import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'Home.dart';
import 'Login.dart';
import 'auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: 'AIzaSyCKd1FJoWvoFBG-yquVcNTmpfF79DY9mcc',
            authDomain: 'next-shift.firebaseapp.com',
            databaseURL: 'https://next-shift.firebaseio.com',
            projectId: 'next-shift',
            storageBucket: 'next-shift.firebasestorage.app',
            messagingSenderId: '345660822246',
            appId: '1:345660822246:web:a8eb7f90ee601e215de127',
            measurementId: 'G-8ZCMPK4GWB',
          )
        : null,
  );
  runApp(const NextShift());
}

class NextShift extends StatelessWidget {
  const NextShift({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const charcoal = Color.fromRGBO(26, 26, 26, 1);
    const brandRed = Color.fromRGBO(204, 51, 51, 1);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D10),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: brandRed,
          primary: brandRed,
          onPrimary: Colors.white,
          secondary: brandRed,
          onSecondary: Colors.white,
          surface: const Color(0xFF15181D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: charcoal,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF15181D),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerColor: const Color(0xFF2A2F36),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF15181D),
          border: OutlineInputBorder(),
        ),
      ),
      home: kIsWeb && isPasswordlessSignInLink(Uri.base.toString()) ? const Login() : Home(),
    );
  }
}
