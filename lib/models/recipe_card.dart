import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/recipe.dart';
import 'package:flutter_application_1/screens/editrecipe_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in.');
      return; // Ensure the user is logged in
    }

    final recipeRef = FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipe.id);

    try {
      print('Recipe reference: ${recipeRef.path}');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(recipeRef);

        if (!snapshot.exists) {
          throw Exception('Recipe does not exist');
        }

        final data = snapshot.data()!;
        final likedBy = List<String>.from(data['likedBy'] ?? []);

        if (likedBy.contains(user.uid)) {
          print('User already liked this recipe. Removing like...');
          likedBy.remove(user.uid);
        } else {
          print('User has not liked this recipe. Adding like...');
          likedBy.add(user.uid);
        }

        print('Updating likedBy field: $likedBy');
        transaction.update(recipeRef, {'likedBy': likedBy});
      });
      print('Transaction completed successfully.');
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
    }
  }

  Future<void> _toggleArchive(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final archiveRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('archives')
        .doc(recipe.id);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(archiveRef);
        if (snap.exists) {
          tx.delete(archiveRef);
        } else {
          tx.set(archiveRef, {'timestamp': FieldValue.serverTimestamp()});
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Archive updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update archive: $e')));
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not logged in.');
      return; // Ensure the user is logged in
    }

    final favoritesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(recipe.id);

    try {
      print('Favorites reference: ${favoritesRef.path}');
      print('Starting Firestore transaction...');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(favoritesRef);

        if (snapshot.exists) {
          print('Recipe already in favorites. Removing...');
          transaction.delete(favoritesRef);
        } else {
          print('Recipe not in favorites. Adding...');
          transaction.set(favoritesRef, {
            'timestamp': FieldValue.serverTimestamp(), // Add a timestamp
          });
        }
      });
      print('Transaction completed successfully.');
    } catch (e, stackTrace) {
      print('Error toggling favorite: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update favorites: $e')));
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getRecipeLikesStream(
    String recipeId,
  ) {
    return FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Duration row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              recipe.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${recipe.duration} min',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Author and Heart row
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
                                      recipe.author;
                                    }
                                    return Text(
                                      authorName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                          ),
                          // Heart Icon for Likes
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('recipes')
                                .doc(recipe.id)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }

                              final data =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final likedBy = List<String>.from(
                                data['likedBy'] ?? [],
                              );
                              final isLiked = likedBy.contains(
                                FirebaseAuth.instance.currentUser?.uid,
                              );

                              return GestureDetector(
                                onTap: () => _toggleLike(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${likedBy.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Bookmark Icon
            Positioned(
              top: 8,
              right: 8,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('favorites')
                    .doc(recipe.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  final isFavorite = snapshot.hasData && snapshot.data!.exists;

                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: isFavorite ? Colors.orange : Colors.grey,
                      size: 30, // Set the size of the icon here
                    ),
                    onPressed: () => _toggleFavorite(context),
                  );
                },
              ),
            ),
            // More menu shown only for the owner's own post
            if (FirebaseAuth.instance.currentUser?.uid == recipe.userId)
              Positioned(
                top: 8,
                left: 8,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 30,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditRecipeScreen(recipe: recipe),
                        ),
                      );
                    } else if (value == 'archive') {
                      _toggleArchive(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 18, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: const [
                          Icon(Icons.archive, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
