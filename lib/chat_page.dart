import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'image_preview_page.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const ChatPage({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isComposing = false;
  final ImagePicker _picker = ImagePicker();
  late Timer _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _updateOnlineStatus(true); // Set online status when the page is opened
    _listenToAuthChanges(); // Listen for login/logout and update the status
    _markMessagesAsRead(); // Mark messages as read

    // Start a timer to send heartbeat updates (status updates every 60 seconds)
    _statusUpdateTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _updateOnlineStatus(true); // Keep updating online status
    });
  }

  @override
  void dispose() {
    _statusUpdateTimer.cancel(); // Cancel the timer when the page is disposed
    _updateOnlineStatus(false); // Set offline status when the page is closed
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .update({'isOnline': isOnline});
        debugPrint(
            "User ${currentUser!.uid} is now ${isOnline ? 'online' : 'offline'}");
      }
    } catch (e) {
      debugPrint("Error updating online status: $e");
    }
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        // User logged in
        debugPrint("User logged in: ${user.uid}");
        await _updateOnlineStatus(true);
      } else {
        // User logged out
        debugPrint("User logged out");
        await _updateOnlineStatus(false);
      }
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
    if (difference.inDays == 1) {
      return 'Yesterday ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    }
    return '${messageTime.day.toString().padLeft(2, '0')}/${messageTime.month.toString().padLeft(2, '0')}/${messageTime.year} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
  try {
    if ((text == null || text.trim().isEmpty) && (imageUrl == null || imageUrl.isEmpty)) {
      return; // Don't send empty messages
    }

    final orgDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser?.uid)
        .get();
    final orgData = orgDoc.data();

    if (orgData != null) {
      await FirebaseFirestore.instance.collection('messages').add({
        'text': text ?? '', // Text content
        'imageUrl': imageUrl ?? '', // Image URL (if any)
        'sender': orgData['name'] ?? 'Unknown User',
        'senderId': currentUser?.uid, // Current user as sender
        'receiverId': widget.userId, // Receiver
        'timestamp': FieldValue.serverTimestamp(), // Timestamp
        'read': false, // Initially unread
      });

      _messageController.clear();
      setState(() {
        _isComposing = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sending message: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  Future<void> _sendImage({bool isCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery,
      );

      if (image == null) return;

      final File imageFile = File(image.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(DateTime.now().millisecondsSinceEpoch.toString());

      // Upload image to Firebase Storage
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the downloadable URL of the uploaded image
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Now send the message with the image URL
      _sendMessage(text: '', imageUrl: imageUrl); // Pass imageUrl but no text
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
  try {
    // Query all messages sent by the sender to the current user that are unread
    final querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: widget.userId) // Sender of the message
        .where('receiverId', isEqualTo: currentUser?.uid) // Current user is the receiver
        .where('read', isEqualTo: false) // Only unread messages
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'read': true}); // Mark the message as read
    }

    await batch.commit();
  } catch (e) {
    debugPrint('Error marking messages as read: $e');
  }
}


  Future<void> _deleteMessage(String messageId) async {
  try {
    // Delete the message from Firestore
    await FirebaseFirestore.instance.collection('messages').doc(messageId).delete();

    // Unfocus the TextField to dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Show success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Message deleted successfully!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    // Show error SnackBar
    FocusScope.of(context).unfocus(); // Ensure the keyboard stays dismissed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Failed to delete message: $e",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}


void _showDeleteConfirmationDialog(String messageId) {
  FocusScope.of(context).unfocus();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 48.0,
                ),
              ),
              const SizedBox(height: 20.0),

              // Title
              const Text(
                "Delete Message",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10.0),

              // Description
              const Text(
                "Are you sure you want to delete this message? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20.0),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close the dialog
                        await _deleteMessage(messageId); // Call the delete function
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        "Delete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userAvatar.isNotEmpty
                  ? NetworkImage(widget.userAvatar)
                  : null,
              radius: 20,
              child: widget.userAvatar.isEmpty
                  ? Text(
                      widget.userName[0].toUpperCase(),
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final userData =
                          snapshot.data?.data() as Map<String, dynamic>?;
                      final isOnline = userData?['isOnline'] ?? false;

                      return Text(
                        isOnline ? 'Active now' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline
                              ? Colors.green
                              : Colors.black.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allMessages = snapshot.data!.docs;
                final messages = allMessages.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['senderId'] == widget.userId &&
                          data['receiverId'] == currentUser?.uid) ||
                      (data['senderId'] == currentUser?.uid &&
                          data['receiverId'] == widget.userId);
                }).toList();

                if (messages.isEmpty) {
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
                          'No messages yet\nStart a conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
  reverse: true,
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index].data() as Map<String, dynamic>;
    final isSentByCurrentUser = message['senderId'] == currentUser?.uid;
    final imageUrl = message['imageUrl'];
    final text = message['text'];
    final timestamp = message['timestamp'] as Timestamp;
    final isRead = message['read'] ?? false; // Get the read status
    final messageId = messages[index].id; // Firestore document ID

    // Check if this is a new group (messages more than 10 minutes apart)
    final bool isNewGroup = index == messages.length - 1 ||
        timestamp.toDate().difference(
              (messages[index + 1].data() as Map<String, dynamic>)['timestamp']
                  .toDate(),
            ) >
            const Duration(minutes: 10);

    // Check if this is the last message in the group
    final bool isLastInGroup = index == 0 ||
        timestamp.toDate().difference(
              (messages[index - 1].data() as Map<String, dynamic>)['timestamp']
                  .toDate(),
            ) >
            const Duration(minutes: 10);

    return GestureDetector(
      onLongPress: () {
        if (isSentByCurrentUser) {
          _showDeleteConfirmationDialog(messageId); // Show delete confirmation
        }
      },
      child: Column(
        crossAxisAlignment:
            isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // If it's a new group, show the timestamp
          if (isNewGroup)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                _formatTimestamp(timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          // Message Container
          Container(
            margin: EdgeInsets.only(bottom: isLastInGroup ? 10 : 2),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isSentByCurrentUser ? Colors.blue[200] : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(isSentByCurrentUser ? 16 : 4),
                bottomRight: Radius.circular(isSentByCurrentUser ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the image if it exists
                if (imageUrl != null && imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePreviewPage(imageUrl: imageUrl),
                        ),
                      );
                    },
                    child: Image.network(
                      imageUrl,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),

                // Display the text message if it exists
                if (text != null && text.isNotEmpty)
                  Text(
                    text,
                    style: TextStyle(
                      color: isSentByCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Read Receipt and Timestamp (for sent messages only)
          if (isLastInGroup)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isSentByCurrentUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  // Timestamp
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSentByCurrentUser ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Read Receipt for sent messages
                  if (isSentByCurrentUser)
                    Text(
                      isRead ? "Seen" : "Delivered",
                      style: TextStyle(
                        fontSize: 12,
                        color: isRead ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  },
);


              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.orange),
                    onPressed: () =>
                        _sendImage(isCamera: true), // Capture image from camera
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.orange),
                    onPressed: () =>
                        _sendImage(isCamera: false), // Pick image from gallery
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.trim().isNotEmpty;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isComposing ? Colors.orange : Colors.grey,
                    ),
                    onPressed: _isComposing
                        ? () => _sendMessage(text: _messageController.text)
                        : null,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
