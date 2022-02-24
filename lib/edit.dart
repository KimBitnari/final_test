import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'dart:io';

import 'home.dart';
import 'details.dart';

TextEditingController edit_name = TextEditingController();
TextEditingController edit_price = TextEditingController();
TextEditingController edit_description = TextEditingController();
String userId;

class EditPage extends StatelessWidget {
  final String name, img;
  EditPage(this.name, this.img);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _EditPage(name, img),
    );
  }
}

class _EditPage extends StatefulWidget {
  final String name, img;
  _EditPage(this.name, this.img);

  @override
  _EditPageState createState() {
    return _EditPageState(name, img);
  }
}

class _EditPageState extends State<_EditPage> {
  final String name, img;
  _EditPageState(this.name, this.img);

  File _image;
  DocumentReference sightingRef = FirebaseFirestore.instance.collection('product').doc();

  Future getImage() async {
    ImagePicker picker = ImagePicker();

    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> saveImages(File _image, DocumentReference ref) async {
    await saveImages(_image,sightingRef);
    String imageURL = await uploadFile(_image);
  }

  Future<String> uploadFile(File _image) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${Path.basename(_image.path)}');
    UploadTask uploadTask = storageReference.putFile(_image);

    print('File Uploaded');
    String returnURL = await (await uploadTask).ref.getDownloadURL().toString();

    return returnURL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Text(
                "Cancel",
                style: TextStyle(fontSize: 13.0)
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DetailsPage(name, img, userId)));
            },
          ),
          title: Text('Edit'),
          actions: <Widget>[
            IconButton(
              icon: Text("Save"),
              onPressed: () {
                //uploadFile(_image);
                print(edit_price.text);
                FirebaseFirestore.instance.collection("product")
                    .doc(name)
                    .update({
                  'name':edit_name.text,
                  'price':int.parse(edit_price.text),
                  'description':edit_description.text,
                  'likes':0,
                  'image':_image==null? "default":Path.basename(_image.path),
                  'updateTime':FieldValue.serverTimestamp()
                }).then((result){
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DetailPage(name, img, userId)));
                });
              },
            ),
          ],
        ),
        body: _buildBody(context)
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('product').where('name', isEqualTo: name).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.docs);
      },
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

    edit_name = TextEditingController(text: record.name);
    edit_price = TextEditingController(text: record.price.toString());
    edit_description = TextEditingController(text: record.description);
    userId = record.userId;

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
          IconButton(
            padding: const EdgeInsets.only(left: 300.0),
            onPressed: getImage,
            tooltip: 'Pick Image',
            icon: Icon(Icons.add_a_photo,color: Colors.black,),
          ),
          SizedBox(height: 20.0),
          TextField(
            controller: edit_name,
            style: TextStyle(color:Colors.lightBlue, fontWeight: FontWeight.bold,fontSize: 25),
          ),
          TextField(
            controller: edit_price,
            style: TextStyle(color:Colors.lightBlue),
          ),
          TextField(
            maxLines: null,
            controller: edit_description,
            style: TextStyle(color:Colors.lightBlue),
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
  final Timestamp createTime;
  final Timestamp updateTime;
  final String userId;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['price'] != null),
        assert(map['likes'] != null),
        assert(map['description'] != null),
        assert(map['image'] != null),
        assert(map['createTime'] != null),
  //assert(map['updateTime'] != null),
        assert(map['userId'] != null),
        price = map['price'],
        name = map['name'],
        likes = map['likes'],
        description = map['description'],
        image = map['image'],
        createTime = map['createTime'],
        updateTime = map['updateTime'],
        userId = map['userId'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$price:$likes:$description:$image:$createTime:$updateTime:$userId>";
}