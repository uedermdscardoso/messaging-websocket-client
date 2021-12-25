
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messaging_websocket/widgets/messaging_websocket.dart';

void main() => runApp(App());

class App extends StatelessWidget {

  const App({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: "Messaging Websocket",
      home: MessagingWebSocket(),
    );

  }
}
