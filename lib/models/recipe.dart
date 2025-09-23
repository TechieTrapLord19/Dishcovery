import 'package:flutter/material.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.recipe.comments);
  }

  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _comments.add(Comment(username: "You", text: text));
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image with back button
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
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    // Title
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Rating + duration
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            recipe.rating.floor(),
                            (index) => const Icon(
                              Icons.star,
                              color: Color(0xFFFFC107),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(recipe.rating.toStringAsFixed(1)),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text("${recipe.duration} min"),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down_alt_outlined),
                          onPressed: () {},
                        ),
                      ],
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
                    if (_comments.isEmpty)
                      const Text("No comments yet. Be the first!"),
                    ..._comments.map(
                      (c) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFD580),
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text(
                          c.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(c.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  final String title;
  final String imageUrl;
  final String description;
  final double rating;
  final int duration;
  final List<String> ingredients;
  final List<String> steps;
  final List<Comment> comments;

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.rating,
    required this.duration,
    required this.ingredients,
    required this.steps,
    required this.comments,
  });

  factory Recipe.fromFirestore(Map<String, dynamic> data) {
    return Recipe(
      title: data['title'] ?? 'No Title',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? 'No Description',
      rating: (data['rating'] ?? 0.0).toDouble(),
      duration: (data['duration'] ?? 0) as int,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: List<String>.from(data['steps'] ?? []),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((c) => Comment.fromMap(c))
          .toList(),
    );
  }
}

class Comment {
  final String username;
  final String text;

  Comment({required this.username, required this.text});

  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      username: data['username'] ?? 'Anonymous',
      text: data['text'] ?? '',
    );
  }
}
