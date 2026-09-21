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
    const brandRed = Color.fromRGBO(204, 51, 51, 1);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D10),
        fontFamily: 'Teko',
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
          backgroundColor: Color(0xFF0B0D10),
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, height: 0.95),
          headlineMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, height: 1),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w300),
          bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandRed,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF13161A),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dividerColor: const Color(0xFF2A2F36),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF13161A),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFF343A43)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFF343A43)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: brandRed, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: Color(0xFF3A414B)),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        chipTheme: const ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          side: BorderSide(color: Color(0xFF343A43)),
        ),
      ),
      home: kIsWeb && isPasswordlessSignInLink(Uri.base.toString()) ? const Login() : Home(),
    );
  }
}
