import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/service/database_service.dart';
import 'otherprofilescreen.dart'; // Import OtherProfileScreen

class ChatPage extends StatefulWidget {
  final String recipientId;
  final String? recipientName;

  const ChatPage({
    Key? key,
    required this.recipientId,
    this.recipientName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String currentUserId;
  late Stream<QuerySnapshot> chats = Stream.empty();
  TextEditingController messageController = TextEditingController();
  final DatabaseService databaseService = DatabaseService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
        getChats();
      });
    } else {
      // Handle the case where the user is not signed in
      // Redirect to sign-in or handle appropriately
    }
  }

  void getChats() {
    setState(() {
      String chatId = getChatId(currentUserId, widget.recipientId);
      chats = databaseService.getChats(currentUserId, widget.recipientId);
    });
  }

  void sendMessage() {
    if (messageController.text.trim().isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageController.text,
        "senderId": currentUserId,
        "time": DateTime.now().millisecondsSinceEpoch,
      };

      String chatId = getChatId(currentUserId, widget.recipientId);

      databaseService.sendMessage(chatId, chatMessageMap, widget.recipientId);

      setState(() {
        messageController.clear();
      });
    }
  }


  String getChatId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to OtherProfileScreen when profile picture clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherProfileScreen(
                      uid: widget.recipientId,
                    ),
                  ),
                );
              },
              child:StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.recipientId)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar();
                  } else if (userSnapshot.hasError) {
                    return CircleAvatar();
                  } else {
                    var userData = userSnapshot.data?.data() as Map<String, dynamic>;
                    String? profileImageUrl = userData['profileImageUrl'];

                    // Check if the user is an admin
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('admins')
                          .doc(widget.recipientId)
                          .snapshots(),
                      builder: (context, adminSnapshot) {
                        if (adminSnapshot.connectionState == ConnectionState.waiting) {
                          return CircleAvatar();
                        } else if (adminSnapshot.hasError) {
                          return CircleAvatar();
                        } else {
                          bool isAdmin = adminSnapshot.hasData && adminSnapshot.data!.exists;

                          return CircleAvatar(
                            backgroundImage: isAdmin
                                ? null // If user is admin, don't show profile image
                                : profileImageUrl != null
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/images/superhero.jpg') as ImageProvider<Object>,
                            child: isAdmin
                                ? Text(
                              '${userData['firstName']} ${userData['lastName']}',
                              style: TextStyle(color: Colors.white),
                            )
                                : null, // Don't show text if user is not an admin
                          );
                        }
                      },
                    );
                  }
                },
              ),

            ),
            SizedBox(width: 10),
            Text(widget.recipientName ?? 'Chat with User'),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: chatMessages(),
          ),
          Container(
            margin: EdgeInsets.only(left: 10),
            constraints: BoxConstraints(maxHeight: 150),
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: SizedBox(
              width: 390,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.grey[200],
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: TextFormField(
                            controller: messageController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 8.0),
                              hintText: 'Enter your message...',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: sendMessage,
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget chatMessages() {
    DateTime? lastDate;

    return StreamBuilder<QuerySnapshot>(
      stream: chats,
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (chatSnapshot.hasError) {
          return Center(
            child: Text('Error: ${chatSnapshot.error}'),
          );
        }
        final chatDocs = chatSnapshot.data?.docs ?? [];
        if (chatDocs.isEmpty) {
          return Center(
            child: Text('Say hello for the first time to this user!'),
          );
        }

        String chatId = getChatId(currentUserId, widget.recipientId);
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .collection("messages")
              .orderBy("time", descending: true)
              .snapshots(),
          builder: (context, messageSnapshot) {
            if (messageSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (messageSnapshot.hasError) {
              return Center(
                child: Text('Error: ${messageSnapshot.error}'),
              );
            }
            final messageDocs = messageSnapshot.data?.docs ?? [];
            return ListView.builder(
              reverse: true,
              itemCount: messageDocs.length,
              itemBuilder: (context, index) {
                var message = messageDocs[index];
                bool isCurrentUser = message['senderId'] == currentUserId;

                DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(
                    message['time'] ?? 0);

                bool isNewDate = lastDate == null ||
                    lastDate!.day != messageTime.day;

                if (isNewDate) {
                  lastDate = messageTime;
                }

                bool displayDate =
                    isNewDate || (index == messageDocs.length - 1);

                return Column(
                  children: [
                    if (displayDate)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          DateFormat('MMMM dd, yyyy HH:mm').format(messageTime),
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        constraints: BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.yellow[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'] ?? '',
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(messageTime),
                              style: TextStyle(
                                color: isCurrentUser
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

}
