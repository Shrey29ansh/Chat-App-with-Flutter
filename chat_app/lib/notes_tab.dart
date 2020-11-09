import 'dart:async';
import 'dart:convert';
import 'package:chat_app/locker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
// ignore: unused_import
import 'package:local_auth/local_auth.dart';
import 'database_helper.dart';

class NotesHome extends StatefulWidget {
  @override
  _NotesHomeState createState() => _NotesHomeState();
}

StreamController _streamController;
Stream _stream;

Stream getList() async* {
  try {
    final dbHelper = CreateNotes.instance;
    final allRows = await dbHelper.queryAllRows();
    _streamController.add(allRows);
  } catch (e) {
    print(e);
  }
}

bool createnote = false;

class _NotesHomeState extends State<NotesHome>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  int colorindex = 0;
  final dbHelper = CreateNotes.instance;
  var pasedjson;
  bool showquote = false;
  List colors = [
    Color.fromRGBO(25, 46, 91, 1),
    Color.fromRGBO(29, 101, 166, 1),
    Color.fromRGBO(114, 162, 192, 1),
    Color.fromRGBO(0, 116, 63, 1),
    Color.fromRGBO(242, 161, 4, 1),
  ];

  @override
  void initState() {
    getList().listen((event) {
      print(event);
    });
    _streamController = StreamController();
    _stream = _streamController.stream;
    _controller = AnimationController(
      vsync: this, // the SingleTickerProviderStateMixin
      duration:
          Duration(seconds: 1), // how long should the animation take to finish
    );
    super.initState();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: StreamBuilder(
        stream: _stream,
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data.length == 0) {
            _controller.repeat(period: Duration(seconds: 1));
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_very_dissatisfied,
                    color: Colors.blue[900],
                    size: MediaQuery.of(context).size.width * 0.5,
                  ),
                  Text(
                    "Empty Locker",
                    style: GoogleFonts.roboto(
                        color: Colors.grey[900], fontSize: 17),
                  ),
                  Text(
                    "Create Your first Locker",
                    style: GoogleFonts.roboto(
                        color: Colors.grey[900], fontSize: 17),
                  )
                ],
              ),
            );
          } else {
            _controller.reset();
            return Container(
              height: MediaQuery.of(context).size.height,
              color: Colors.black,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(20),
                        itemCount: snapshot.data.length,
                        gridDelegate:
                            new SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2),
                        itemBuilder: (BuildContext context, int index) {
                          bool checkval = true;
                          if (index > 4) {
                            colorindex = index % 5;
                            checkval = false;
                          }
                          return Container(
                            child: Stack(
                              children: [
                                Align(
                                    alignment: Alignment.topCenter,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 30,
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.lock,
                                            size: 25,
                                            color: checkval
                                                ? colors[index]
                                                : colors[colorindex],
                                          ),
                                        ],
                                      ),
                                    )),
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: InkWell(
                                    splashColor: Colors.blue,
                                    onTap: () async {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Locker(
                                              lockername: snapshot.data[index]
                                                  ['lockername'],
                                              username: snapshot.data[index]
                                                  ['username'],
                                              password: snapshot.data[index]
                                                  ['password'],
                                              comments: snapshot.data[index]
                                                  ['comments'],
                                              color: checkval
                                                  ? colors[index]
                                                  : colors[colorindex],
                                            ),
                                          ));
                                    },
                                    child: Card(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        elevation: 2,
                                        shadowColor: checkval
                                            ? colors[index]
                                            : colors[colorindex],
                                        color: checkval
                                            ? colors[index]
                                            : colors[colorindex],
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: -10,
                                              right: 20,
                                              child: Icon(
                                                Icons.vpn_key,
                                                size: 150,
                                                color: Colors.black
                                                    .withOpacity(0.8),
                                              ),
                                            ),
                                            Center(
                                              child: Text(
                                                '${snapshot.data[index]['lockername']}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    shadows: <Shadow>[
                                                      Shadow(
                                                        offset: Offset(5.0, 7),
                                                        blurRadius: 7,
                                                        color: Colors.black,
                                                      ),
                                                    ],
                                                    color: Colors.white,
                                                    fontSize: 25,
                                                    fontWeight:
                                                        FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                                softWrap: true,
                                                maxLines: 3,
                                              ),
                                            ),
                                          ],
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class AlertBox extends StatefulWidget {
  @override
  _AlertBoxState createState() => _AlertBoxState();
}

class _AlertBoxState extends State<AlertBox> {
  final _formKey = GlobalKey<FormState>();
  bool namerror = false,
      usererror = false,
      passerror = false,
      mandatory = false; // for locker name validation
  var warning, mandatwarning;
  final nametext = TextEditingController(),
      username = TextEditingController(),
      password = TextEditingController(),
      comments = TextEditingController();
  FocusNode _myfocus = FocusNode(),
      namefocus = FocusNode(),
      passfocus = FocusNode(),
      comfocus = FocusNode();
  bool visibility = false;
  bool touched = false;

  void changefocus() async {
    if (!_myfocus.hasFocus) {
      var check = await checklocker(nametext.text);
      if (check == null) {
        setState(() {
          namerror = false;
        });
      } else {
        if (!check.isEmpty) {
          setState(() {
            namerror = true;
            warning = "This Lockername already exist";
          });
        } else {
          setState(() {
            namerror = false;
          });
        }
      }
    }
  }

  Future checklocker(String lockername) async {
    //final ffr = await dbHelper.delete('gmail');
    try {
      final dbHelper = CreateNotes.instance;
      final result = await dbHelper.checkName(lockername);
      return result;
    } catch (e) {
      print(e);
    }
  }

  Future insertNotes(String namefield, String usernamefield,
      String passwordfield, String commentsfield) async {
    final dbHelper = CreateNotes.instance;

    Map<String, dynamic> row = {
      CreateNotes.columnName: namefield,
      CreateNotes.columnUsername: usernamefield,
      CreateNotes.password: passwordfield,
      CreateNotes.comments: commentsfield
    };
    final id = await dbHelper.insert(row);
    print('inserted row id: $id');
  }

  void _requestFocus(FocusNode name) {
    setState(() {
      touched = true;
      FocusScope.of(context).requestFocus(name);
    });
  }

  @override
  void initState() {
    super.initState();
    _myfocus.addListener(changefocus);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black.withOpacity(0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.red,
                      ),
                      new Text(
                        "Create new locker",
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 17,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                AlertDialog(
                  buttonPadding: EdgeInsets.all(10),
                  contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  actions: [
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      elevation: 5,
                      child: Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      color: Colors.grey[900],
                      onPressed: () async {
                        if (_myfocus.hasFocus) {
                          var check = await checklocker(nametext.text);

                          if (check == null) {
                            setState(() {
                              namerror = false;
                            });
                          } else {
                            if (!check.isEmpty) {
                              setState(() {
                                namerror = true;
                                warning = "This Lockername already exist";
                              });
                            } else {
                              setState(() {
                                namerror = false;
                              });
                            }
                          }
                        }
                        if (_formKey.currentState.validate()) {
                          if (!namerror) {
                            //logic for db entry
                            try {
                              await insertNotes(nametext.text, username.text,
                                  password.text, comments.text);
                              final dbHelper = CreateNotes.instance;
                              final allRows = await dbHelper.queryAllRows();
                              _streamController.add(allRows);
                            } catch (e) {
                              print(e);
                            }

                            Navigator.of(context).pop();
                          }
                        } else {
                          print("false");
                        }
                      },
                    ),
                    RaisedButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      elevation: 5,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      color: Colors.grey[900],
                      onPressed: () {
                        /* print(nametext.text);
                        print(password.text);
                        print(comments.text);
                        print(username.text); */

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  content: new Container(
                    padding: EdgeInsets.all(15),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextFormField(
                              // ignore: missing_return
                              validator: (value) {
                                print(value);
                                if (value.isEmpty) {
                                  return 'required';
                                }
                              },
                              style: TextStyle(color: Colors.black),
                              cursorHeight: 20,
                              onTap: () {
                                _requestFocus(_myfocus);
                              },
                              cursorColor: Colors.black,
                              controller: nametext,
                              focusNode: _myfocus,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                  labelText: "Name of locker*",
                                  errorText: namerror ? warning : null,
                                  labelStyle: TextStyle(
                                      color: touched
                                          ? Colors.black
                                          : Colors.grey[500]),
                                  enabledBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[500]),
                                  ),
                                  focusedBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  focusColor: Colors.white,
                                  errorStyle: TextStyle(),
                                  hintText: "eg.Main Account",
                                  hintStyle: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            TextFormField(
                              // ignore: missing_return
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'required*';
                                }
                              },
                              enableSuggestions: true,
                              style: TextStyle(color: Colors.black),
                              cursorHeight: 20,
                              onTap: () {
                                _requestFocus(namefocus);
                              },
                              cursorColor: Colors.black,
                              controller: username,
                              focusNode: namefocus,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                  labelText: "Username/Email*",
                                  labelStyle: TextStyle(
                                      color: touched
                                          ? Colors.black
                                          : Colors.grey[500]),
                                  enabledBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[500]),
                                  ),
                                  focusedBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  focusColor: Colors.white,
                                  errorStyle: TextStyle(),
                                  hintText: "eg.a@xmail.com",
                                  hintStyle: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            TextFormField(
                              // ignore: missing_return
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'required*';
                                }
                              },
                              obscureText: !visibility,
                              style: TextStyle(color: Colors.black),
                              cursorHeight: 20,
                              onTap: () {
                                _requestFocus(passfocus);
                              },
                              cursorColor: Colors.black,
                              controller: password,
                              focusNode: passfocus,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                  labelText: "Password*",
                                  errorText: passerror ? warning : null,
                                  suffixIcon: visibility
                                      ? InkWell(
                                          child: Icon(
                                            Icons.visibility_off,
                                            color: Colors.grey[500],
                                          ),
                                          onTap: () => setState(() {
                                                visibility = !visibility;
                                              }))
                                      : InkWell(
                                          child: Icon(Icons.visibility),
                                          onTap: () => setState(() {
                                                visibility = !visibility;
                                              })),
                                  enabledBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[500]),
                                  ),
                                  focusedBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  focusColor: Colors.white,
                                  errorStyle: TextStyle(),
                                  hintStyle: TextStyle(color: Colors.white)),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            TextField(
                              style: TextStyle(color: Colors.black),
                              cursorHeight: 20,
                              onTap: () {
                                _requestFocus(comfocus);
                              },
                              cursorColor: Colors.black,
                              controller: comments,
                              focusNode: comfocus,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                  labelText: "Extra Info",
                                  labelStyle: TextStyle(
                                      color: touched
                                          ? Colors.black
                                          : Colors.grey[500]),
                                  enabledBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide:
                                        BorderSide(color: Colors.grey[500]),
                                  ),
                                  focusedBorder: new OutlineInputBorder(
                                    borderRadius:
                                        new BorderRadius.circular(10.0),
                                    borderSide: BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                  focusColor: Colors.white,
                                  errorStyle: TextStyle(),
                                  hintText: "eg.Main Account",
                                  hintStyle: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeleteAlert extends StatefulWidget {
  final lockername;
  DeleteAlert({this.lockername});
  @override
  _DeleteAlertState createState() => _DeleteAlertState(lockername: lockername);
}

class _DeleteAlertState extends State<DeleteAlert> {
  final lockername;
  _DeleteAlertState({this.lockername});
  double _showalert = 0;
  startTImer() {
    var duration = Duration(microseconds: 100);
    return new Timer(duration, () {
      setState(() {
        _showalert = 30;
      });
    });
  }

  Future deleteLocker() async {
    try {
      final dbHelper = CreateNotes.instance;
      final result = await dbHelper.delete(lockername);
      final allRows = await dbHelper.queryAllRows();
      _streamController.add(allRows);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      return result;
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    startTImer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedPositioned(
        bottom: _showalert,
        curve: Curves.ease,
        duration: Duration(milliseconds: 500),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              title: Text("Are you sure you want to delete this locker?"),
              content: Text(
                "There is no backup!",
                style: TextStyle(color: Colors.grey[600]),
              ),
              actionsPadding: EdgeInsets.all(10),
              actions: [
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 5,
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  color: Colors.grey[900],
                  onPressed: () async {
                    await deleteLocker();
                  },
                ),
                RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 5,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  color: Colors.grey[900],
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
