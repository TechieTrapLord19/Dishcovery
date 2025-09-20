import 'package:flutter/material.dart';

class Recipe {
  final String title;
  final String imageUrl;
  final double rating;
  final int duration;
  final List<String> ingredients;
  final List<String> steps;
  final List<Comment> comments;

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.duration,
    required this.ingredients,
    required this.steps,
    this.comments = const [],
  });
}

class Comment {
  final String username;
  final String text;

  Comment({required this.username, required this.text});
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dishcovery',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              // Implement menu functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Dishes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: dummyRecipes.length,
              itemBuilder: (context, index) {
                final recipe = dummyRecipes[index];
                return RecipeCard(recipe: recipe);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new recipe functionality
        },
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700], size: 16),
                      Text(' ${recipe.rating}'),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 16),
                      Text(' ${recipe.duration} mins'),
                    ],
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

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              recipe.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.yellow[700]),
                      Text(' ${recipe.rating}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time),
                      Text(' ${recipe.duration} mins'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                    (ingredient) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $ingredient'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Preparation Steps',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    recipe.steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${index + 1}'),
                          ),
                          Expanded(child: Text(recipe.steps[index])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...recipe.comments.map(
                    (comment) => CommentWidget(comment: comment),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {},
                      ),
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

class CommentWidget extends StatelessWidget {
  final Comment comment;

  const CommentWidget({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(child: Text(comment.username[0])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Dummy recipes for testing
final List<Recipe> dummyRecipes = [
  Recipe(
    title: 'Creamy Pasta Carbonara',
    imageUrl: 'assets/carbonara.jpeg',
    rating: 4.8,
    duration: 25,
    ingredients: [
      '400g spaghetti pasta',
      '200g pancetta, diced',
      '4 large eggs',
      '100g Parmesan cheese, grated',
      'Black pepper to taste',
      '2 tbsp olive oil',
    ],
    steps: [
      'Bring a large pot of salted water to boil. Cook spaghetti according to package instructions until al dente.',
      'While pasta cooks, heat olive oil in a large skillet over medium heat. Add pancetta and cook until crispy, about 5-7 minutes.',
      'In a bowl, whisk together eggs, Parmesan cheese, and plenty of black pepper.',
      'Drain pasta, reserving some pasta water. Add pasta to the skillet with pancetta.',
      'Remove from heat and quickly stir in the egg mixture, tossing well to coat.',
    ],
    comments: [
      Comment(
        username: 'Kaye Mizal',
        text:
            'This recipe looks absolutely delicious! Can\'t wait to try it tonight! 🍝',
      ),
    ],
  ),
];
