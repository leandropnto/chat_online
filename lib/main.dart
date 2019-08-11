import 'dart:io';

import 'package:chat_online/components/chat_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(ChatApp());
}

final ThemeData kIOSTheme = ThemeData(
    primarySwatch: Colors.orange,
    primaryColor: Colors.grey[100],
    primaryColorBrightness: Brightness.light);

final ThemeData kDefault = ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null) {
    user = await googleSignIn.signInSilently();
  }

  if (user == null) {
    user = await googleSignIn.signIn();
  }

  if (await auth.currentUser() == null) {
    final credentials = await googleSignIn.currentUser.authentication;
    await auth.signInWithCredential(GoogleAuthProvider.getCredential(
        idToken: credentials.idToken, accessToken: credentials.accessToken));
  }
}

_handleSubmitted(String texto) async {
  await _ensureLoggedIn();
  _sendMessage(texto: texto);
}

_sendMessage({String texto, String imgUrl}) {
  Firestore.instance.collection("mensagens").add({
    "text": texto,
    "imgUrl": imgUrl,
    "senderName": googleSignIn.currentUser.displayName,
    "senderPhotoUrl": googleSignIn.currentUser.photoUrl
   });
}

_uploadImage(File file)  async {
  StorageUploadTask task = FirebaseStorage.instance.ref()
    .child(googleSignIn.currentUser.id.toString() +
    DateTime.now().millisecondsSinceEpoch.toString()).putFile(file);
StorageTaskSnapshot taskSnapshot = await task.onComplete;
String url = await taskSnapshot.ref.getDownloadURL();
_sendMessage(imgUrl: url);
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Online',
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefault,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat App'),
          centerTitle: true,
          elevation:
              Theme.of(context).platform == TargetPlatform.iOS ? 0.5 : 4.0,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ChatList()
            ),
            Divider(
              height: 1.0,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: TextComposer(),
            )
          ],
        ),
      ),
    );
  }
}

class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  bool _isComposing = false;
  final controller = TextEditingController();

  void _reset() {
    controller.text = "";
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200])))
            : null,
        child: Row(
          children: <Widget>[
            Container(
              child: IconButton(
                icon: Icon(Icons.camera),
                onPressed: () async{
                  await _ensureLoggedIn();
                  var file = await ImagePicker.pickImage(source: ImageSource.gallery);
                  if (file == null) return ;
                  await _uploadImage(file);
                },
              ),
            ),
            Expanded(
              child: TextField(
                decoration:
                    InputDecoration.collapsed(hintText: 'Enviar mensagem'),
                onChanged: (texto) {
                  setState(() => _isComposing = texto.length > 0);
                },
                controller: controller,
                onSubmitted: (texto) {
                  _handleSubmitted(texto);
                  _reset();
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoButton(
                      child: Text('Enviar'),
                      onPressed: _isComposing
                          ? () {
                              _handleSubmitted(controller.text);
                              _reset();
                            }
                          : null)
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _isComposing
                          ? () {
                              _handleSubmitted(controller.text);
                              _reset();
                            }
                          : null),
            ),
          ],
        ),
      ),
    );
  }
}
