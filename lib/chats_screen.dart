import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'onChat_field_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Future<void> _refreshChats() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
     
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser)
                  .collection('friends')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SizedBox.shrink();
                }

                final friends = snapshot.data!.docs;

                return Container(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index].data() as Map<String, dynamic>;
                      final friendId = friends[index].id;
                      final photoURL = friend['photoURL'] ?? 'assets/example/123.jpeg';
                      final name = friend['name'] ?? 'Unknown';

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => IndividualChatScreen(
                                peerUserId: friendId,
                                userName: name,
                                userImage: photoURL,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(photoURL),
                            ),
                            SizedBox(height: 5),
                            Text(
                              name,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(width: 10),
                  ),
                );
              },
            ),
            Divider(thickness: 2),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('users', arrayContains: currentUser)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Чаты отсутствуют'));
                  }

                  final chatDocs = chatSnapshot.data!.docs;

                  return ListView.builder(
                    itemCount: chatDocs.length,
                    itemBuilder: (ctx, index) {
                      var chatData = chatDocs[index].data() as Map<String, dynamic>;
                      var lastMessage = chatData['lastMessage'] ?? 'Нет сообщений';
                      var lastMessageTime = '';
                      if (chatData['lastMessageTime'] != null) {
                        DateTime messageTime = (chatData['lastMessageTime'] as Timestamp).toDate();
                        lastMessageTime = DateFormat('HH:mm').format(messageTime);
                      }

                      final friendId = chatData['users'].firstWhere((id) => id != currentUser);
                      final friendData = FirebaseFirestore.instance.collection('Users').doc(friendId).get();
                      final chatId = chatDocs[index].id;  // Получаем chatId

                      return FutureBuilder<DocumentSnapshot>(
                        future: friendData,
                        builder: (context, friendSnapshot) {
                          if (!friendSnapshot.hasData) {
                            return SizedBox.shrink();
                          }

                          var friendInfo = friendSnapshot.data!.data() as Map<String, dynamic>;
                          var friendName = friendInfo['name'] ?? 'Unknown';
                          var friendPhotoURL = friendInfo['photoURL'] ?? 'assets/example/123.jpeg';

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chats/$chatId/messages')
                                .where('isRead', isEqualTo: false)
                                .where('userId', isEqualTo: friendId)
                                .snapshots(),
                            builder: (context, unreadSnapshot) {
                              bool hasUnreadMessages = unreadSnapshot.hasData && unreadSnapshot.data!.docs.isNotEmpty;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(friendPhotoURL),
                                ),
                                title: Text(friendName),
                                subtitle: Text(lastMessage),
                                trailing: Column(
                                  children: [
                                    Text(lastMessageTime),
                                    if (hasUnreadMessages)
                                      const Icon(Icons.brightness_1, color: Colors.red, size: 10),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => IndividualChatScreen(
                                        peerUserId: friendId,
                                        userName: friendName,
                                        userImage: friendPhotoURL,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
