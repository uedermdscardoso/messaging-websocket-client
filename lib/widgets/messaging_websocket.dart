import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MessagingWebSocket extends StatefulWidget {

  const MessagingWebSocket({Key? key}) : super(key: key);

  @override
  _MessagingWebSocketState createState() => _MessagingWebSocketState();
}

class _MessagingWebSocketState extends State<MessagingWebSocket> {

  static final socketUrl = 'https://messaging-websocket.herokuapp.com/gs-guide-websocket';

  final TextEditingController _controller = TextEditingController();
  final BehaviorSubject<List<String>> _messages = BehaviorSubject<List<String>>();
  late StompClient stompClient;

  void onConnect(StompFrame frame) {
    stompClient.subscribe(
      destination: '/topic/greetings',
      callback: (frame) async  {

        final Map<String, dynamic> result = json.decode(frame.body!);
        
        if(result.containsKey("content")) {

          final String message = result["content"] as String;

          if(_messages.hasValue) {
            final List<String> messages = _messages.stream.value;

            messages.add(message);
            _messages.add(messages);
          } else {
            _messages.add([ message ]);
          }
        }
      },
    );
  }


  @override
  void initState() {
    _init();
    super.initState();
  }

  @override
  void dispose() {
    stompClient.deactivate();
    super.dispose();
  }

  _init() {
    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: socketUrl,
        onConnect: onConnect,
        beforeConnect: () async {
          print('We\'re waiting to connect...');
          await Future.delayed(Duration(milliseconds: 200));
          print('We\'re connecting...');
        },
        onWebSocketError: (dynamic error) => print(error.toString()),
        //stompConnectHeaders: {'Authorization': 'Bearer yourToken'},
        //webSocketConnectHeaders: {'Authorization': 'Bearer yourToken'},
      ),
    );
    stompClient.activate();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Websocket!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'Type a message here'),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder(
                stream: _messages.stream,
                builder: (context, snapshot) {

                  if(snapshot.hasData) {

                    final List<String> messages = snapshot.data as List<String>;

                    return NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowIndicator();

                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {

                          final String message = messages.elementAt(index);

                          return Container(
                            padding: const EdgeInsets.only(top: 18, bottom: 18),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[400]!, width: 0.5),
                              ),
                            ),
                            child: Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                          );
                        },
                      ),
                    );
                  }

                  return Container();
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              onPressed: _clearMessages,
              tooltip: 'Delete',
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete),
            ),
            FloatingActionButton(
              onPressed: _sendMessage,
              tooltip: 'Send',
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );

  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
        final String message = _controller.text.trim();

        if(!stompClient. connected)
          stompClient.activate();

        if(stompClient.connected) {
          stompClient.send(
            destination: '/app/hello',
            body: jsonEncode({'name': message}),
          );
        }
    }
  }

  void _clearMessages() {
    if(_messages.hasValue) {
      setState(() => _messages.value.clear());
    }
  }

}
