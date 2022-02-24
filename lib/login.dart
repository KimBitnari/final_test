// Copyright 2018-present the Flutter authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                children: <Widget>[
                  SizedBox(height: 80.0),
                  Column(
                    children: <Widget>[
                      Image.asset('assets/diamond.png'),
                      SizedBox(height: 16.0),
                      Text('SHRINE'),
                    ],
                  ),
                  SizedBox(height: 120.0),
                  _GoogleLogin(),
                  _AnonymouslyLogin(),
                ]
            )
        )
    );
  }
}

class _GoogleLogin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GoogleLoginState();
}

class _GoogleLoginState extends State<_GoogleLogin> {
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('Google Login'),
      color: Colors.white,
      onPressed: () {
        _signInWithGoogle();
      },
    );
  }

  void _signInWithGoogle() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => HomePage())
      );
    } catch (e) {
      print(e);

      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in with Google: ${e}"),
      ));
    }
  }
}

class _AnonymouslyLogin extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AnonymouslyLoginState();
}

class _AnonymouslyLoginState extends State<_AnonymouslyLogin> {
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('Guest Login'),
      color: Colors.white,
      onPressed: () {
        _signInAnonymously();
      },
    );
  }

  void _signInAnonymously() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    try {
      final User user = (await FirebaseAuth.instance.signInAnonymously()).user;

      Navigator.push(context,
          MaterialPageRoute(builder: (context) => HomePage()));
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Failed to sign in Anonymously: ${e}"),
      ));
    }
  }
}

