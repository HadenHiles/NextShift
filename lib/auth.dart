import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'models/SubscriptionResponse.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn.instance;
final Future<void> googleSignInInitialization = googleSignIn.initialize();

Future<UserCredential> signInWithGoogle() async {
  if (kIsWeb) {
    return auth.signInWithPopup(GoogleAuthProvider());
  }

  await googleSignInInitialization;
  final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // Create a new credential
  final OAuthCredential credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance
      .setPersistence(Persistence.SESSION)
      .then((_) {
    return auth.signInWithCredential(credential);
  });
}

Future<UserCredential> signInWithFacebook() {
  final provider = FacebookAuthProvider();
  if (kIsWeb) return auth.signInWithPopup(provider);
  return auth.signInWithProvider(provider);
}

Future<UserCredential> signInWithEmailPassword(
  String email,
  String password,
) {
  return auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}

Future<UserCredential> createEmailPasswordAccount(
  String email,
  String password,
) {
  return auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}

Future<void> sendPasswordlessSignInLink(String email) {
  return auth.sendSignInLinkToEmail(
    email: email.trim(),
    actionCodeSettings: ActionCodeSettings(
      url: 'https://nextshift.howtohockey.com',
      handleCodeInApp: true,
      linkDomain: 'nextshift.howtohockey.com',
      androidPackageName: 'com.example.nextshift',
      androidInstallApp: true,
      iOSBundleId: 'com.example.nextshift',
    ),
  );
}

bool isPasswordlessSignInLink(String link) {
  return auth.isSignInWithEmailLink(link);
}

Future<UserCredential> completePasswordlessSignIn(
  String email,
  String link,
) {
  return auth.signInWithEmailLink(email: email.trim(), emailLink: link);
}

Future<bool> hasMembership() async {
  // Map the data to send
  final user = auth.currentUser;
  if (user == null) return false;

  final data = <String, dynamic>{'email': user.email};

  final http.Response response = await http.post(
    Uri.parse(
        'https://thepond.howtohockey.com/wp-content/themes/meltingpot-child/active-membership.php'),
    body: data,
  );
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    SubscriptionResponse subResponse =
        SubscriptionResponse.fromJson(jsonDecode(response.body));
    return subResponse.subscriptions.length > 0;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load membership');
  }
}

Future<bool> isAdmin() async {
  final user = auth.currentUser;
  if (user == null) return false;

  final snapshot =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
  return snapshot.exists;
}

Future<void> signOut() async {
  await auth.signOut();
}
