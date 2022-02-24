import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'dart:io';

import 'home.dart';

final FirebaseStorage storage = FirebaseStorage.instance;
final Reference storageRef = storage.ref();

class AddPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AddProduct(),
    );
  }
}

class AddProduct extends StatefulWidget {
  @override
  _AddProductState createState() {
    return _AddProductState();
  }
}

class _AddProductState extends State<AddProduct> {
  final name = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();

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

  // Future<void> saveImages(File _image, DocumentReference ref) async {
  //   await saveImages(_image, sightingRef);
  //   String imageURL = await uploadFile(_image);
  // }

  Future<String> uploadFile(File _image) async {
    // if (_image == null) {
    //   _image = File(Uri.parse("https://handong.edu/site/handong/res/img/logo.png").toFilePath());
    // }

    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${Path.basename(_image.path)}');
    UploadTask uploadTask = storageReference.putFile(_image);
    //await uploadTask.onComplete;
    print('File Uploaded');
    String returnURL = await (await uploadTask).ref.getDownloadURL().toString();
    // await storageReference.getDownloadURL().then((fileURL) {
    //   returnURL =  fileURL;
    // });
    return returnURL;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Text("Cancel"),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
        titleSpacing: 0,
        title: Text('Add'),
        actions: <Widget>[
          IconButton(
            icon: Text("Save"),
            onPressed: () {
              uploadFile(_image);
              FirebaseFirestore.instance.collection("product")
                  .doc(name.text)
                  .set({
                'name':name.text,
                'price':int.parse(price.text),
                'description':description.text,
                'likes':0,
                'image':_image==null? "default":Path.basename(_image.path),
                'createTime':FieldValue.serverTimestamp(),
                'updateTime':FieldValue.serverTimestamp(),
                'userId':FirebaseAuth.instance.currentUser.uid
              }).then((result){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage()));
              });
            },
          ),
        ],
      ),
      body:Container(
        margin: const EdgeInsets.all(50.0),
        child: Column (
          children: <Widget>[
            Container(
              height: 300.0,
              width: 300.0,
              child: _image == null
                  ? Image.network("https://handong.edu/site/handong/res/img/logo.png")
                  : Image.file(_image, fit: BoxFit.fill,),
              //child: Image.file(_image, fit: BoxFit.fill,),
            ),
            IconButton(
              padding: const EdgeInsets.only(left: 300.0),
              onPressed: getImage,
              tooltip: 'Pick Image',
              icon: Icon(Icons.add_a_photo,color: Colors.black,),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: name,
              decoration: new InputDecoration( hintText: "Product Name", hintStyle: TextStyle(color: Colors.lightBlue)),
            ),
            TextField(
              controller: price,
              decoration: new InputDecoration( hintText: "Price", hintStyle: TextStyle(color: Colors.lightBlue)),
            ),
            TextField(
              maxLines: null,
              controller: description,
              decoration: new InputDecoration( hintText: "Description", hintStyle: TextStyle(color: Colors.lightBlue)),
            ),
          ],
        ),
      ),
    );
  }
}