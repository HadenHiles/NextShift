import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'models/SubscriptionResponse.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // Create a new credential
  final GoogleAuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.setPersistence(Persistence.SESSION).then((_) {
    return auth.signInWithCredential(credential);
  });
}

Future<UserCredential> signInWithFacebook() async {
  // Trigger the sign-in flow
  final LoginResult result = await FacebookAuth.instance.login();

  // Create a credential from the access token
  final FacebookAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(result.accessToken.token);

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.setPersistence(Persistence.SESSION).then((_) {
    return auth.signInWithCredential(facebookAuthCredential);
  });
}

Future<bool> hasMembership() async {
  // Map the data to send
  var data = new Map<String, dynamic>();
  data['email'] = auth.currentUser.email;

  final http.Response response = await http.post(
    'https://thepond.howtohockey.com/wp-content/themes/meltingpot-child/active-membership.php',
    body: data,
  );
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    SubscriptionResponse subResponse = SubscriptionResponse.fromJson(jsonDecode(response.body));
    return subResponse.subscriptions.length > 0;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load membership');
  }
}

Future<bool> isAdmin() async {
  return FirebaseFirestore.instance.collection('admins').doc(FirebaseAuth.instance.currentUser?.uid).get().then((value) => value != null);
}

Future<void> signOut() async {
  await auth.signOut();
}
