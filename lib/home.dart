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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'model/products_repository.dart';
import 'model/product.dart';

import 'profile.dart';
import 'add.dart';
import 'details.dart';

bool desc = false;

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  @override
  _MainViewState createState() {
    return _MainViewState();
  }
}

class _MainViewState extends State<MainView> {
  String dropdownValue = 'ASC';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.person_rounded,
            semanticLabel: 'profile',
          ),
          onPressed: () {
            print('Profile button');
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfilePage()));
          },
        ),
        title: Text('Main'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              semanticLabel: 'add',
            ),
            onPressed: () {
              print('Add button');
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddPage()));
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          _sort(),
          _buildBody(context, desc),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _sort() {
    //String dropdownValue = 'ASC';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(height: 40.0),
        DropdownButton<String>(
          value: dropdownValue,
          icon: const Icon(Icons.arrow_downward),
          iconSize: 24,
          elevation: 16,
          //style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.black12,
          ),
          onChanged: (String newValue) {
            setState(() {
              dropdownValue = newValue;
              desc = !desc;
            });
          },
          items: <String>['ASC', 'DESC']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        SizedBox(height: 40.0),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool desc) {
    return StreamBuilder<QuerySnapshot>(
      // initialData: Firebase.initializeApp(),
      stream: FirebaseFirestore.instance.collection('product').orderBy('price',descending: desc).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.docs);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Center(
      child: GridView.count(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.0),
        childAspectRatio: 8.0 / 9.0,
        children: snapshot.map((data) => _buildListItem(context, data)).toList(),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    //get Image from storage
    Future<String> _getImage(String filePath) async {
      var _urlImage;

      if(filePath == "default") _urlImage = "https://handong.edu/site/handong/res/img/logo.png";
      else _urlImage = await FirebaseStorage.instance
          .ref()
          .child(filePath)
          .getDownloadURL();

      return _urlImage;
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 18 / 11,
            child: FutureBuilder<String>(
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    record.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    "\$ "+record.price.toString(),
                  ),
                  ButtonTheme(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minWidth: 0,
                    height: 30,
                    padding: const EdgeInsets.only(left: 120.0),
                    child: FlatButton(
                      child: Text(
                        'more',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DetailPage(record.name, record.image, record.userId)),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
  final String image;
  final String userId;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['price'] != null),
        assert(map['image'] != null),
        assert(map['userId'] != null),
        price = map['price'],
        name = map['name'],
        image = map['image'],
        userId = map['userId'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$price:$image:$userId>";
}
