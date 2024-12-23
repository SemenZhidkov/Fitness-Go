import 'package:fitnessgo/train_detail_check.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:theme_provider/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'TrainDetailsnew.dart'; // Импорт экрана деталей тренировки

// Функция для создания уникального идентификатора чата
String getChatId(String userId, String peerId) {
  return userId.hashCode <= peerId.hashCode ? '$userId-$peerId' : '$peerId-$userId';
}

class FullScreenImage extends StatelessWidget {
  final String url;

  FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ThemeConsumer(
      child: Scaffold(
        body: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Image.network(url),
          ),
        ),
      ),
    );
  }
}

class IndividualChatScreen extends StatefulWidget {
  final String peerUserId;
  final String userName;
  final String userImage;

  IndividualChatScreen({required this.peerUserId, required this.userName, required this.userImage});

  @override
  _IndividualChatScreenState createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final String text = _messageController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (text.isNotEmpty && currentUser != null) {
      final chatId = getChatId(currentUser.uid, widget.peerUserId);
      final message = {
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
        'isRead': false,
      };

      FirebaseFirestore.instance.collection('chats/$chatId/messages').add(message);

      FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'users': [currentUser.uid, widget.peerUserId],
      }, SetOptions(merge: true));

      _messageController.clear();
    }
  }

  void _markMessagesAsRead() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatId = getChatId(currentUser.uid, widget.peerUserId);
      final messagesRef = FirebaseFirestore.instance.collection('chats/$chatId/messages');

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final querySnapshot = await messagesRef
            .where('userId', isEqualTo: widget.peerUserId)
            .where('isRead', isEqualTo: false)
            .get();

        for (var doc in querySnapshot.docs) {
          transaction.update(doc.reference, {'isRead': true});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    String chatId = getChatId(currentUser!.uid, widget.peerUserId);
    return ThemeConsumer(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.userImage),
              ),
              SizedBox(width: 10),
              Text(widget.userName),
            ],
          ),
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chats/$chatId/messages')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Что-то пошло не так'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      bool myMessage = messageData['userId'] == currentUser.uid;
                      Widget content;
                      if (messageData['icon'] == 'whistle' && messageData['iconColor'] == 'green') {
                        content = Row(
                          children: [
                            Icon(
                              Icons.sports_gymnastics,
                              color: Colors.green,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                messageData['text'],
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ],
                        );
                      } else if (messageData['hasAttachment'] == true && messageData['icon'] != null) {
                        content = Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFF78A75A),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                messageData['text'],
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ],
                        );
                      } else {
                        content = Text(
                          messageData['text'],
                          style: TextStyle(color: textColor),
                        );
                      }

                      return Align(
                        alignment: myMessage ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: myMessage ? backgroundColor : Colors.lightGreen,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              content,
                              if (messageData.containsKey('trainingId') && !myMessage && messageData['title'] != 'Индивидуальная тренировка')
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrainDetailCheck(trainingId: messageData['trainingId']),
                                      ),
                                    );
                                  },
                                  child: Text('Посмотреть тренировку'),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = FirebaseStorage.instance.ref().child('chat_uploads/$fileName');
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        _sendMessageWithAttachment(downloadUrl);
      } catch (e) {
        print('Ошибка загрузки файла: $e');
      }
    }
  }

  void _sendMessageWithAttachment(String fileUrl) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final chatId = getChatId(currentUser.uid, widget.peerUserId);
      FirebaseFirestore.instance.collection('chats/$chatId/messages').add({
        'text': '📎 Attachment',
        'attachment': fileUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
        'hasAttachment': true,
        'attachmentUrl': fileUrl,
      });
    }
  }

  Widget _buildMessageInputField() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            IconButton(
              onPressed: _pickAndUploadFile,
              icon: Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                child: Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
