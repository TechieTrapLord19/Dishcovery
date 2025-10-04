import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe.dart';
import 'package:flutter_application_1/models/recipe_card.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  Future<List<Recipe>> _loadArchivedRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final archivedSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('archives')
        .orderBy('timestamp', descending: true)
        .get();

    final List<Recipe> recipes = [];
    for (final doc in archivedSnap.docs) {
      final recipeId = doc.id;
      final recipeDoc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (recipeDoc.exists && recipeDoc.data() != null) {
        final data = recipeDoc.data()!;
        // Ensure id is passed correctly
        recipes.add(Recipe.fromFirestore(recipeDoc.id, data));
      }
    }
    return recipes;
  }

  Future<void> _deleteArchivedRecipe(
    BuildContext context,
    String recipeId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .doc(recipeId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe removed from archives.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove recipe.')));
    }
  }

  Future<void> _unarchiveRecipe(BuildContext context, String recipeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final id = recipeId.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid recipe id.')));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe unarchived.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to unarchive.')));
    }
  }

  Future<void> _deleteRecipeCompletely(
    BuildContext context,
    String recipeId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Remove from user's archives
      final archiveRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .doc(recipeId);
      batch.delete(archiveRef);

      // Delete the recipe document
      final recipeRef = FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId);
      batch.delete(recipeRef);

      await batch.commit();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Archived',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser == null
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('archives')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
        builder: (context, archiveSnap) {
          if (archiveSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!archiveSnap.hasData || archiveSnap.data!.docs.isEmpty) {
            return const Center(child: Text('No archived recipes.'));
          }

          // Use a FutureBuilder to fetch full recipe documents
          return FutureBuilder<List<Recipe>>(
            future: _loadArchivedRecipes(),
            builder: (context, recipesSnap) {
              if (recipesSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final recipes = recipesSnap.data ?? [];
              if (recipes.isEmpty) {
                return const Center(child: Text('No archived recipes.'));
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];

                  return Stack(
                    children: [
                      RecipeCard(recipe: recipe), // The recipe card itself
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton(
                              heroTag: 'unarchive_$index',
                              mini: true,
                              backgroundColor: Colors.green,
                              child: const Icon(Icons.unarchive),
                              onPressed: () async {
                                await _unarchiveRecipe(context, recipe.id);
                              },
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton(
                              heroTag: 'delete_$index',
                              mini: true,
                              backgroundColor: Colors.red,
                              child: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Recipe'),
                                    content: const Text(
                                      'This will permanently delete the recipe. Continue?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await _deleteRecipeCompletely(
                                    context,
                                    recipe.id,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
