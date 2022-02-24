import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  final String title = 'ProfilePage';
  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
              Icons.arrow_back
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
        title: Text(widget.title),
        actions: <Widget>[
          Builder(builder: (BuildContext context) {
            return IconButton(
              icon: Icon(
                Icons.exit_to_app,
                semanticLabel: 'logout',
              ),
              onPressed: () async {
                final User user = await FirebaseAuth.instance.currentUser;
                //var name, email, photoUrl, emailVerified;
                if (user == null) {
                  Scaffold.of(context).showSnackBar(const SnackBar(
                    content: Text('No one has signed in.'),
                  ));
                  return;
                }
                else{
                }
                _signOut();
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
            );
          })
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(60.0),
        child: Column (
          children: <Widget>[
            Container(
              height: 200.0,
              width: 200.0,
              child: user.photoURL == null
                  ? Image.network("https://handong.edu/site/handong/res/img/logo.png")
                  : Image.network(user.photoURL, fit: BoxFit.fill,),
            ),
            SizedBox(height: 60.0),
            Text(
              user.uid,
              style: TextStyle(fontSize: 15),
            ),
            Divider(
              thickness: 1,
              color: Colors.black38,
            ),
            Container(
                child: user.email == null
                    ? Text("Anonymous", style: TextStyle(fontSize: 15),)
                    : Text(user.email, style: TextStyle(fontSize: 15),)
            ),
          ],
        ),
      ),
    );
  }

  // Example code for sign out.
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}