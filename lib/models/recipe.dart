import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/editrecipe_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments = [];
  bool _isLoadingComments = true;
  String _errorMessage = '';
  bool _isLiked = false;
  bool _isFavorite = false;
  int _totalHearts = 0;
  // Toggle archive (add/remove from users/{uid}/archives/{recipe.id})
  Future<void> _toggleArchive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final archiveRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('archives')
        .doc(widget.recipe.id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(archiveRef);
        if (snap.exists) {
          tx.delete(archiveRef);
        } else {
          tx.set(archiveRef, {'timestamp': FieldValue.serverTimestamp()});
        }
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update archive: $e')));
    }
  }

  @override
  void _fetchComments() {
    FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
          try {
            final List<Comment> fetchedComments = [];

            for (final doc in snapshot.docs) {
              final data = doc.data();
              final userID = data['userID'] ?? '';

              String username = '';
              String profilePictureURL = '';

              if (userID.isNotEmpty) {
                try {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userID)
                      .get();

                  if (userDoc.exists && userDoc.data() != null) {
                    final userData = userDoc.data()!;
                    username = userData['username'] ?? '';
                    profilePictureURL = userData['profilePictureURL'] ?? '';
                  }
                } catch (e) {
                  print('Error fetching user data for userID $userID: $e');
                }
              }

              if (username.isEmpty) {
                continue; // Skip this comment if username is invalid
              }

              fetchedComments.add(
                Comment(
                  id: doc.id,
                  userID: userID,
                  username: username,
                  text: data['text'] ?? '',
                  profilePictureURL: profilePictureURL,
                  timestamp: data['timestamp'] ?? Timestamp.now(),
                ),
              );
            }

            // Update state with fetched comments
            setState(() {
              _comments = fetchedComments;
              _isLoadingComments =
                  false; // Stop loading once comments are fetched
              _errorMessage = '';
            });
          } catch (e) {
            print('Error fetching comments: $e');
            setState(() {
              _isLoadingComments =
                  false; // Stop loading even if there's an error
              _errorMessage =
                  'Failed to load comments. Please try again later.';
            });
          }
        });
  }

  // Fetch like status and total hearts
  void _fetchLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipeDoc = await FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .get();

    if (recipeDoc.exists) {
      final data = recipeDoc.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      setState(() {
        _isLiked = likedBy.contains(user.uid);
        _totalHearts = likedBy.length;
      });
    }
  }

  // Toggle like status
  void _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(recipeRef);

      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);

      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
        setState(() {
          _isLiked = false;
          _totalHearts = likedBy.length;
        });
      } else {
        likedBy.add(user.uid);
        setState(() {
          _isLiked = true;
          _totalHearts = likedBy.length;
        });
      }

      transaction.update(recipeRef, {'likedBy': likedBy});
    });
  }

  // Fetch favorite status
  void _fetchFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favoriteDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipe.id)
        .get();

    setState(() {
      _isFavorite = favoriteDoc.exists;
    });
  }

  // Toggle favorite status
  void _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.recipe.id);

    if (_isFavorite) {
      await favoriteRef.delete();
      setState(() {
        _isFavorite = false;
      });
    } else {
      await favoriteRef.set({'timestamp': FieldValue.serverTimestamp()});
      setState(() {
        _isFavorite = true;
      });
    }
  }

  // Add a comment to Firestore
  void _addComment(String text) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final commentRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipe.id)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userID': user.uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
  }

  Widget _buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No comments yet. Be the first!"));
        }

        final comments = snapshot.data!.docs;

        return FutureBuilder<List<Comment>>(
          future: _processComments(comments),
          builder: (context, commentSnapshot) {
            if (commentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (commentSnapshot.hasError) {
              return Center(child: Text('Error loading comments'));
            }

            final processedComments = commentSnapshot.data ?? [];

            return Column(
              children: processedComments.map((comment) {
                final currentUser = FirebaseAuth.instance.currentUser;
                final isCurrentUser =
                    currentUser != null && comment.userID == currentUser.uid;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFD580),
                    backgroundImage: comment.profilePictureURL.isNotEmpty
                        ? NetworkImage(comment.profilePictureURL)
                        : null,
                    child: comment.profilePictureURL.isEmpty
                        ? const Icon(Icons.person, color: Colors.black)
                        : null,
                  ),
                  title: Text(
                    comment.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.text),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(comment.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: isCurrentUser
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Edit') {
                              _editComment(comment);
                            } else if (value == 'Delete') {
                              _deleteComment(comment);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'Delete',
                              child: Text('Delete'),
                            ),
                          ],
                        )
                      : null,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final commentTime = timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  void _editComment(Comment comment) {
    final TextEditingController editController = TextEditingController(
      text: comment.text,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(hintText: 'Edit your comment'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedText = editController.text.trim();
                if (updatedText.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('recipes')
                        .doc(widget.recipe.id)
                        .collection('comments')
                        .doc(comment.id)
                        .update({'text': updatedText});
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error updating comment: $e');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteComment(Comment comment) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipe.id)
          .collection('comments')
          .doc(comment.id)
          .delete();
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  Future<List<Comment>> _processComments(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<Comment> processedComments = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userID = data['userID'] ?? '';

      String username = 'Anonymous';
      String profilePictureURL = '';

      if (userID.isNotEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userData = userDoc.data()!;
            username = userData['username'] ?? 'Anonymous';
            profilePictureURL = userData['profilePictureURL'] ?? '';
          }
        } catch (e) {
          print('Error fetching user data for userID $userID: $e');
        }
      }

      processedComments.add(
        Comment(
          id: doc.id,
          userID: userID,
          username: username,
          text: data['text'] ?? '',
          profilePictureURL: profilePictureURL,
          timestamp: data['timestamp'] ?? Timestamp.now(),
        ),
      );
    }

    return processedComments;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120), // Adjusted padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image with favorite button
                  Stack(
                    children: [
                      Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child:
                            StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: FirebaseAuth.instance.currentUser == null
                                  ? null
                                  : FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .collection('favorites')
                                        .doc(recipe.id)
                                        .snapshots(),
                              builder: (context, favSnap) {
                                final isFav =
                                    favSnap.hasData && favSnap.data!.exists;
                                return IconButton(
                                  icon: Icon(
                                    isFav
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: Colors.orange,
                                  ),
                                  onPressed: _toggleFavorite,
                                );
                              },
                            ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                recipe.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.duration} min',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Author and Hearts (live)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child:
                                  StreamBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >(
                                    stream: recipe.userId.isNotEmpty
                                        ? FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(recipe.userId)
                                              .snapshots()
                                        : null,
                                    builder: (context, userSnap) {
                                      String authorName = recipe.author;
                                      if (userSnap.hasData &&
                                          userSnap.data?.data() != null) {
                                        authorName =
                                            'by ${userSnap.data!.data()!['username'] ?? recipe.author}';
                                      }
                                      return Text(
                                        authorName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                            ),
                            StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>
                            >(
                              stream: FirebaseFirestore.instance
                                  .collection('recipes')
                                  .doc(recipe.id)
                                  .snapshots(),
                              builder: (context, likeSnap) {
                                int hearts = 0;
                                if (likeSnap.hasData &&
                                    likeSnap.data!.data() != null) {
                                  final data = likeSnap.data!.data()!;
                                  final likedBy = List<String>.from(
                                    data['likedBy'] ?? [],
                                  );
                                  hearts = likedBy.length;
                                }
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$hearts',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),

                        const Divider(thickness: 1, height: 30),

                        // Description
                        Text(
                          recipe.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),

                        const Divider(thickness: 1, height: 30),

                        // Ingredients
                        const Text(
                          "Ingredients",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map(
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text("• $i"),
                          ),
                        ),

                        const Divider(thickness: 1, height: 30),

                        // Steps
                        const Text(
                          "Preparation Steps",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          recipe.steps.length,
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFFFD580),
                                  child: Text(
                                    "${i + 1}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    recipe.steps[i],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(thickness: 1, height: 30),

                        // Comments
                        const Text(
                          "Comments",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildComments(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Floating like button
            Positioned(
              bottom: 80, // Adjusted position to avoid overlap with input box
              right: 16,
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('recipes')
                    .doc(recipe.id)
                    .snapshots(),
                builder: (context, likeSnap) {
                  bool isLiked = false;
                  if (likeSnap.hasData && likeSnap.data!.data() != null) {
                    final data = likeSnap.data!.data()!;
                    final likedBy = List<String>.from(data['likedBy'] ?? []);
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      isLiked = likedBy.contains(uid);
                    }
                  }
                  return FloatingActionButton(
                    backgroundColor: isLiked ? Colors.red : Colors.grey,
                    onPressed: _toggleLike,
                    child: const Icon(Icons.favorite, color: Colors.white),
                  );
                },
              ),
            ),
            if (FirebaseAuth.instance.currentUser?.uid == recipe.userId)
              Positioned(
                bottom: 140,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'archive_btn',
                  backgroundColor: Colors.orange,
                  onPressed: _toggleArchive,
                  child: const Icon(Icons.archive, color: Colors.white),
                ),
              ),
            if (FirebaseAuth.instance.currentUser?.uid == recipe.userId)
              Positioned(
                bottom: 200,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'edit_btn',
                  backgroundColor: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditRecipeScreen(recipe: widget.recipe),
                      ),
                    );
                  },
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              ),
          ],
        ),
      ),

      // Comment input box fixed at bottom
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: "Add a comment...",
                  filled: true,
                  fillColor: const Color(0xFFFFFBF5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.orange),
              onPressed: () => _addComment(_commentController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final double rating;
  final int duration;
  final List<String> ingredients;
  final List<String> steps;
  final String author;
  final String userId;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.duration,
    required this.ingredients,
    required this.steps,
    required this.author,
    required this.userId,
  });

  factory Recipe.fromFirestore(String id, Map<String, dynamic> data) {
    return Recipe(
      id: id,
      title: data['title'] ?? 'No Title',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? 'No Description',
      rating: (data['rating'] ?? 0.0).toDouble(),
      duration: (data['duration'] ?? 0) as int,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      author:
          data['username'] ??
          'Unknown Author', // Use username field if available
      userId: (data['userId'] ?? '') as String,
    );
  }
}

class Comment {
  final String id;
  final String userID;
  final String username;
  final String text;
  final String profilePictureURL;
  final Timestamp timestamp;

  Comment({
    required this.id,
    required this.userID,
    required this.username,
    required this.text,
    required this.profilePictureURL,
    required this.timestamp,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> data) {
    return Comment(
      id: id,
      userID: data['userID'] ?? '',
      username: data['username'] ?? 'Anonymous',
      text: data['text'] ?? '',
      profilePictureURL: data['profilePictureURL'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}
