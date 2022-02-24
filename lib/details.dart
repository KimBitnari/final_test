import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'home.dart';
import 'edit.dart';

String user = FirebaseAuth.instance.currentUser.uid;

class DetailsPage extends StatelessWidget {
  final String name, img, creator;
  DetailsPage(this.name, this.img, this.creator);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DetailPage(name, img, creator),
    );
  }
}

class DetailPage extends StatefulWidget {
  final String name, img, creator;
  DetailPage(this.name, this.img, this.creator);

  @override
  _DetailPageState createState() {
    return _DetailPageState(name, img, creator);
  }
}

class _DetailPageState extends State<DetailPage> {
  final String name, img, creator;
  _DetailPageState(this.name, this.img, this.creator);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: creator == user
          ? _creatorAppBar()
          : _userAppBar(),
      body: _buildBody(context),

    );
  }
  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('product').where('name', isEqualTo: name).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return _buildList(context, snapshot.data.docs);
        else if(snapshot.hasError) const Text('No data avaible right now');

        return LinearProgressIndicator();
      },
    );
  }

  Widget _creatorAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
            Icons.arrow_back
        ),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => HomePage()));
        },
      ),
      title: Text('Detail'),
      actions: <Widget>[
        IconButton(
          icon: Icon(
              Icons.mode_edit
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => EditPage(name, img)));
          },
        ),
        IconButton(
          icon: Icon(
              Icons.restore_from_trash
          ),
          onPressed: () {
            FirebaseStorage.instance.ref().child(img).delete();
            FirebaseFirestore.instance.collection("product").doc(name).delete();
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
      ],
    );
  }

  Widget _userAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(
            Icons.arrow_back
        ),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => HomePage()));
        },
      ),
      title: Text('Detail'),
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Center(
      child: Column(
        children: snapshot.map((data) => _buildListItem(context, data)).toList(),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User user = _auth.currentUser;

    Future<String> _getImage(String filePath) async {
      var _urlImage;

      if(filePath == "default") _urlImage = "https://handong.edu/site/handong/res/img/logo.png";
      else _urlImage = await FirebaseStorage.instance
          .ref()
          .child(filePath)
          .getDownloadURL();

      return _urlImage;
    }
    return Container(
      margin: const EdgeInsets.all(50.0),
      child: Column (
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 300.0,
            width: 500.0,
            child:FutureBuilder<String>(
                future: _getImage(record.image),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.hasData) {
                    return Image(image:NetworkImage(snapshot.data), fit:BoxFit.fill);
                  } else if (!snapshot.hasData) {
                    return Container(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(record.name, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,)),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed:(){
                          FirebaseFirestore.instance.collection("like").doc(record.name + user.uid)
                              .snapshots()
                              .listen((snapshot) {
                            if (snapshot.data() != null) {
                              if (snapshot.data()['like']) {
                                Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "You can only do it once !!"),));
                              }
                            } else {
                              FirebaseFirestore.instance.collection("like").doc(
                                  record.name + user.uid).set(
                                  {'like': true});
                              record.reference.update(
                                  {'likes': FieldValue.increment(1)});
                              Scaffold.of(context).showSnackBar(
                                  SnackBar(content: Text("I LIKE IT !"),));
                            }
                          });
                        },
                        icon: Icon(Icons.thumb_up), color: Colors.red, iconSize: 27),
                    Text(record.likes.toString(), style: TextStyle(fontSize: 20,color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          Text("\$ "+record.price.toString(), style: TextStyle(fontSize: 20)),
          Divider(thickness: 1, color: Colors.black38,),
          SizedBox(height: 20.0,),
          Text(record.description),
          SizedBox(height: 180.0,),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Creator: "+record.userId, style: TextStyle(color: Colors.black38, fontSize: 12),),
                Text("Created: "+record.createTime.toString(), style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold),),
                Text("Modified: "+record.updateTime.toString(), style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold),),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Record {
  final String name;
  final int price;
  final int likes;
  final String description;
  final String image;
  final DateTime createTime;
  final DateTime updateTime;
  final String userId;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['price'] != null),
        assert(map['likes'] != null),
        assert(map['description'] != null),
        assert(map['image'] != null),
        assert(map['createTime'].toDate() != null),
        assert(map['updateTime'].toDate() != null),
        assert(map['userId'] != null),
        price = map['price'],
        name = map['name'],
        likes = map['likes'],
        description = map['description'],
        image = map['image'],
        createTime = map['createTime'].toDate(),
        updateTime = map['updateTime'].toDate(),
        userId = map['userId'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$price:$likes:$description:$image:$createTime:$updateTime:$userId>";
}
