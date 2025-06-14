import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class ChatsOrganizationPage extends StatefulWidget {
  const ChatsOrganizationPage({super.key});

  @override
  _ChatsOrganizationPageState createState() => _ChatsOrganizationPageState();
}

class _ChatsOrganizationPageState extends State<ChatsOrganizationPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String? _searchQuery;
  final Color primaryColor = const Color(0xFFFF9800);
  final Color secondaryColor = const Color(0xFFFFF3E0);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _deleteChat(String userId) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    QuerySnapshot messages = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', whereIn: [currentUser?.uid, userId])
        .where('receiverId', whereIn: [currentUser?.uid, userId])
        .get();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  void _showDeleteConfirmationDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: Text('Are you sure you want to delete chat with $userName?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(child: CircularProgressIndicator());
                    },
                  );

                  await _deleteChat(userId);

                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat deleted successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  setState(() {});
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting chat: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: TextField(
              onChanged: (query) => setState(() => _searchQuery = query),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 8),
            child: _buildHorizontalUsersList(),
          ),
          Expanded(
            child: _buildRecentChatsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Individual')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final filteredUsers = _searchQuery == null || _searchQuery!.isEmpty
            ? users
            : users.where((user) {
                final userData = user.data() as Map<String, dynamic>;
                final userName = userData['name'] ?? '';
                return userName.toLowerCase().contains(_searchQuery!.toLowerCase());
              }).toList();

        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        filteredUsers.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aOnline = aData['isOnline'] ?? false;
          final bOnline = bData['isOnline'] ?? false;
          if (aOnline && !bOnline) return -1;
          if (!aOnline && bOnline) return 1;
          return 0;
        });

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userData = filteredUsers[index].data() as Map<String, dynamic>;
            final userName = userData['name'] ?? 'Unknown User';
            final userDisplayName = userName.length > 12
                ? '${userName.substring(0, 12)}...' 
                : userName;
            final avatarUrl = userData['avatarUrl'] ?? '';
            final isOnline = userData['isOnline'] ?? false;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: filteredUsers[index].id,
                      userName: userName,
                      userAvatar: avatarUrl,
                    ),
                  ),
                );
              },
              child: Container(
                width: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOnline ? Colors.green : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: secondaryColor,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? Text(
                                    userName[0],
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey[400],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentChatsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, messagesSnapshot) {
        if (!messagesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, Map<String, dynamic>> userLastMessages = {};
        Map<String, int> unreadCount = {};

        for (var doc in messagesSnapshot.data!.docs) {
          final message = doc.data() as Map<String, dynamic>;
          final senderId = message['senderId'];
          final receiverId = message['receiverId'];
          final isRead = message['read'] ?? false;

          if (senderId == currentUser?.uid || receiverId == currentUser?.uid) {
            final otherUserId = senderId == currentUser?.uid ? receiverId : senderId;

            if (!userLastMessages.containsKey(otherUserId)) {
              userLastMessages[otherUserId] = message;
            }

            if (receiverId == currentUser?.uid && !isRead) {
              unreadCount[otherUserId] = (unreadCount[otherUserId] ?? 0) + 1;
            }
          }
        }

        if (userLastMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userLastMessages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userId = userLastMessages.keys.elementAt(index);
              final lastMessage = userLastMessages[userId]!;
              final unreadMessages = unreadCount[userId] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown';
                  final avatarUrl = userData['avatarUrl'] ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: secondaryColor,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              userName[0],
                              style: TextStyle(
                                fontSize: 24,
                                color: primaryColor,
                              ),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(lastMessage['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage['text'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          if (unreadMessages > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadMessages.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () async {
                      WriteBatch batch = FirebaseFirestore.instance.batch();
                      QuerySnapshot unreadMessages = await FirebaseFirestore.instance
                          .collection('messages')
                          .where('senderId', isEqualTo: userId)
                          .where('receiverId', isEqualTo: currentUser?.uid)
                          .where('read', isEqualTo: false)
                          .get();

                      for (var doc in unreadMessages.docs) {
                        batch.update(doc.reference, {'read': true});
                      }

                      await batch.commit();

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userId: userId,
                            userName: userName,
                            userAvatar: avatarUrl,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showDeleteConfirmationDialog(userId, userName),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
