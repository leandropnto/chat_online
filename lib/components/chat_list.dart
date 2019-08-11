import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'chat_message.dart';

class ChatList extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Firestore.instance.collection("mensagens").snapshots(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return CircularProgressIndicator();
          default:
            return ListView.builder(
              reverse: true,
              itemCount: snapshot.data.documents.length,
              itemBuilder: (context, index) {
                final lista = snapshot.data.documents.reversed.toList();
                return ChatMessage(lista[index].data);
              },
            );
        }
      },
    );
  }
}
