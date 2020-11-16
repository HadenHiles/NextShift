import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'widgets/Heading.dart';
import 'Home.dart';
import 'auth.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Static variables
  final FirebaseAuth auth = FirebaseAuth.instance;
  final User user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  bool signedIn = FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null)
        setState(() {
          signedIn = true;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    //If user is signed in
    if (signedIn) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return Home();
            },
          ),
        );
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromRGBO(240, 240, 240, 1),
      appBar: AppBar(
        leading: InkWell(
          child: Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(120, 120, 120, 1),
          ),
          onTap: () async {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: 40,
                      bottom: 60,
                    ),
                    width: 460,
                    child: Heading(
                      text: "Sign in",
                      size: 40,
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    width: 360,
                    child: SignInButton(
                      Buttons.Google,
                      onPressed: () {
                        socialSignIn(context, 'google', (error) {
                          _scaffoldKey.currentState.hideCurrentSnackBar();
                          _scaffoldKey.currentState.showSnackBar(
                            SnackBar(
                              content: Text(error),
                              duration: Duration(seconds: 10),
                              action: SnackBarAction(
                                label: "Dismiss",
                                onPressed: () {
                                  _scaffoldKey.currentState.hideCurrentSnackBar();
                                },
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  socialSignIn(BuildContext context, String provider, Function error) async {
    if (provider == 'google') {
      signInWithGoogle().then((credential) {
        setState(() {
          signedIn = true;
        });
      }).catchError((e) async {
        var message = "There was an error signing in with Google";
        if (e.code == "user-disabled") {
          message = "Your account has been disabled by the administrator";
        } else if (e.code == "account-exists-with-different-credential") {
          message = "An account already exists with the same email address but different sign-in credentials. Please try signing in a different way";
        }

        print(e);
        await error(message);
      });
    }
  }
}
