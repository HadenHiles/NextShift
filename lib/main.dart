import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'Home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: 'AIzaSyCKd1FJoWvoFBG-yquVcNTmpfF79DY9mcc',
            authDomain: 'next-shift.firebaseapp.com',
            databaseURL: 'https://next-shift.firebaseio.com',
            projectId: 'next-shift',
            storageBucket: 'next-shift.appspot.com',
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
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(204, 51, 51, 1),
          primary: const Color.fromRGBO(26, 26, 26, 1),
          surface: Colors.white,
        ),
      ),
      home: Home(),
    );
  }
}
