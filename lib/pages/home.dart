import 'dart:io';
import 'package:faceter/pages/add_face.dart';
import 'package:faceter/pages/login/login_page.dart';
import 'package:faceter/pages/result.dart';
import 'package:faceter/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  SharedPreferences sharedPreferences;
  FirebaseUser _user;
  String _userId;
  File _imgFile;
  final ImagePicker _picker = ImagePicker();

  _getUser() async {
    sharedPreferences = await SharedPreferences.getInstance();
    FirebaseUser user = await auth.getUser();
    setState(() {
      _user = user;
      _userId = (sharedPreferences.getString("userId") ?? '');
    });
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  editFace() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose'),
        content: Container(
          height: 100.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FlatButton.icon(
                onPressed: () async {
                  Get.to(AddFace());

                  // final pickedFile = await _picker.getImage(
                  //   source: ImageSource.camera,
                  //   imageQuality: 85,
                  // );
                  // setState(() {
                  //   _imgFile = File(pickedFile.path);
                  // });
                  // Get.to(Result(imagePath: pickedFile.path));
                },
                icon: Icon(FontAwesomeIcons.camera),
                label: Text('Camera'),
              ),
              FlatButton.icon(
                onPressed: () async {
                  final pickedFile = await _picker.getImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  setState(() {
                    _imgFile = File(pickedFile.path);
                  });
                  Get.to(Result(imagePath: pickedFile.path));
                },
                icon: Icon(FontAwesomeIcons.images),
                label: Text('Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(FontAwesomeIcons.signOutAlt),
            onPressed: () async {
              await auth.signOut();
              Get.off(LoginPage());
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        child: RaisedButton(
          padding: EdgeInsets.all(17.0),
          onPressed: () {},
          child: Text(
            'ABSEN',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: _userId == null
          ? CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage: NetworkImage(
                              'https://api.adorable.io/avatars/285/${_user.displayName}.png'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 14.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _user.displayName,
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Text(
                              _user.email,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                            FlatButton.icon(
                              label: Text('Edit Face'),
                              icon: Icon(
                                FontAwesomeIcons.edit,
                                size: 19.0,
                              ),
                              onPressed: () {
                                editFace();
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
