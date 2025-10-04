import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/recipe.dart';
import 'package:flutter_application_1/models/recipe_card.dart';
import 'package:flutter_application_1/screens/addrecipe_screen.dart';
import 'package:flutter_application_1/screens/archive_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/services/recipe_service.dart';
import 'package:flutter_application_1/auth/auth_service.dart';
import 'package:flutter_application_1/auth/login_screen.dart';
import 'package:flutter_application_1/screens/editprofile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Variables to store user data
  String fullName = "Loading...";
  String username = "Loading...";
  String bio = "Loading...";
  String profilePictureURL = "";
  List<Map<String, dynamic>> userPosts = []; // List to store user's posts
  List<Map<String, dynamic>> favoriteRecipes = []; // List to store favorites
  List<Map<String, dynamic>> likedRecipes = []; // List to store liked recipes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData(); // Fetch user data on initialization
    _fetchUserPosts(); // Fetch user's posts on initialization
    _fetchFavorites(); // Fetch user's favorites
    _fetchLikedRecipes(); // Fetch user's liked recipes
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          fullName = data['fullName'] ?? 'No Name';
          username = data['username'] ?? 'No Username';
          bio = data['bio'] ?? 'No Bio';
          profilePictureURL =
              data['profilePictureURL'] ?? ''; // Default to empty string
        });
      }
    }
  }

  // Fetch user's posts from Firestore
  Future<void> _fetchUserPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load archived ids to exclude
      final archived = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .get();
      final archivedIds = archived.docs.map((d) => d.id).toSet();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: user.uid) // Filter by logged-in user's ID
          .get();

      setState(() {
        userPosts = querySnapshot.docs
            .where((doc) => !archivedIds.contains(doc.id))
            .map(
              (doc) => {
                ...doc.data(),
                'id': doc.id, // Add the document ID
              },
            )
            .toList();
      });
    }
  }

  // Fetch user's favorite recipes
  Future<void> _fetchFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();

    final archivedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('archives')
        .get();
    final archivedIds = archivedSnapshot.docs.map((d) => d.id).toSet();

    final List<Map<String, dynamic>> fetchedFavorites = [];
    for (final doc in favoritesSnapshot.docs) {
      final recipeId = doc.id;
      final recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();

      if (recipeSnapshot.exists && !archivedIds.contains(recipeId)) {
        fetchedFavorites.add({
          ...recipeSnapshot.data()!,
          'id': recipeId, // Add the document ID
        });
      }
    }

    setState(() {
      favoriteRecipes = fetchedFavorites;
    });
  }

  // Fetch recipes liked by the user
  Future<void> _fetchLikedRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likedSnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('likedBy', arrayContains: user.uid)
        .get();

    final archivedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('archives')
        .get();
    final archivedIds = archivedSnapshot.docs.map((d) => d.id).toSet();

    setState(() {
      likedRecipes = likedSnapshot.docs
          .where((doc) => !archivedIds.contains(doc.id))
          .map(
            (doc) => {
              ...doc.data(),
              'id': doc.id, // Add the document ID
            },
          )
          .toList();
    });
  }

  // Pick and upload a new profile picture
  Future<void> _updateProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Uint8List? imageBytes = await pickedFile
            .readAsBytes(); // Read image as bytes

        // Show confirmation modal with the selected image
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Upload'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display the selected image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Do you want to upload this image as your profile picture?',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // Cancel
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Confirm
                child: const Text('Upload'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Upload the image to Cloudinary
          final imageUrl = await RecipeService().uploadImage(
            null, // Pass null for mobile file
            webImageBytes: imageBytes, // Use bytes for web
          );

          if (imageUrl != null) {
            // Update the profilePictureURL field in Firestore
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'profilePictureURL': imageUrl});

              setState(() {
                profilePictureURL = imageUrl; // Update the UI
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated!')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image.')),
            );
          }
        }
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Show the settings modal
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Settings Options
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Edit Profile Option
                    InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        // Navigate to Edit Profile Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.orange.shade600,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // Archive Option
                    // Inside the _showSettingsModal method, replace the Archive Option's onTap:
                    InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        // Navigate to ArchiveScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArchiveScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.archive_outlined,
                                color: Colors.orange.shade600,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Archive',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Divider
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),

                    // Logout Option
                    InkWell(
                      onTap: () {
                        Navigator.pop(context); // Close the modal
                        _showLogoutConfirmation(
                          context,
                        ); // Show logout confirmation
                      },
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.logout_outlined,
                                color: Colors.orange.shade600,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Logout',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close the dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Call the logOut method from AuthService
              await AuthService().logOut();

              // Navigate to the LoginScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false, // Remove all previous routes
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () =>
                  _showSettingsModal(context), // Show settings modal
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFFD580),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile picture and bio aligned left
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey,
                      backgroundImage: profilePictureURL.isNotEmpty
                          ? NetworkImage(profilePictureURL)
                          : null,
                      child: profilePictureURL.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _updateProfilePicture,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD580),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "@$username",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _editBio,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bio.isNotEmpty ? bio : '+ Add Bio',
                              style: TextStyle(
                                fontSize: 14,
                                color: bio.isNotEmpty
                                    ? Colors.black
                                    : Colors.grey,
                                fontStyle: bio.isNotEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            indicatorColor: Colors.orange,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on), text: "Posts"),
              Tab(icon: Icon(Icons.bookmark), text: "Favorites"),
              Tab(icon: Icon(Icons.favorite), text: "Liked"),
            ],
          ),

          // Tab contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserPostsGridView(), // Posts
                _buildFavoritesGridView(), // Favorites
                _buildLikedGridView(), // Liked Recipes
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipeScreen()),
          );
        },
        backgroundColor: const Color(0xFFFFD580),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Future<void> _editBio() async {
    final TextEditingController bioController = TextEditingController(
      text: bio,
    );

    final newBio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bio'),
        content: TextField(
          controller: bioController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter your bio',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, bioController.text.trim()), // Save
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBio != null && newBio.isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update the bio in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'bio': newBio});

          setState(() {
            bio = newBio; // Update the UI
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bio updated successfully!')),
          );
        }
      } catch (e) {
        print('Error updating bio: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update bio: $e')));
      }
    }
  }

  void _navigateToRecipeDetail(Map<String, dynamic> recipeData) {
    final recipe = Recipe.fromFirestore(recipeData['id'], recipeData);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }

  // Build the grid view for user's posts
  Widget _buildUserPostsGridView() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No user logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .snapshots(),
      builder: (context, archiveSnap) {
        if (archiveSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final archivedIds = <String>{
          if (archiveSnap.hasData) ...archiveSnap.data!.docs.map((d) => d.id),
        };

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipes')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No posts yet."));
            }

            final userPosts = snapshot.data!.docs
                .where((doc) => !archivedIds.contains(doc.id))
                .map((doc) {
                  return {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id, // Add the document ID
                  };
                })
                .toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                final postData = userPosts[index];
                final recipe = Recipe.fromFirestore(
                  postData['id'] ?? '',
                  postData,
                );
                return RecipeCard(recipe: recipe);
              },
            );
          },
        );
      },
    );
  }

  // Build the grid view for favorites
  Widget _buildFavoritesGridView() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No user logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .snapshots(),
      builder: (context, archiveSnap) {
        if (archiveSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get all archived recipe IDs
        final archivedIds = <String>{
          if (archiveSnap.hasData) ...archiveSnap.data!.docs.map((d) => d.id),
        };

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .snapshots(),
          builder: (context, favoritesSnap) {
            if (favoritesSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!favoritesSnap.hasData || favoritesSnap.data!.docs.isEmpty) {
              return const Center(child: Text("No favorites yet."));
            }

            // Get all favorite recipe IDs
            final favoriteIds = favoritesSnap.data!.docs
                .map((doc) => doc.id)
                .where(
                  (id) => !archivedIds.contains(id),
                ) // Exclude archived IDs
                .toList();

            if (favoriteIds.isEmpty) {
              return const Center(child: Text("No favorites yet."));
            }

            // Fetch actual recipes from recipes collection
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .where(FieldPath.documentId, whereIn: favoriteIds)
                  .snapshots(),
              builder: (context, recipesSnap) {
                if (recipesSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!recipesSnap.hasData || recipesSnap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No favorite recipes found."),
                  );
                }

                final favoriteRecipes = recipesSnap.data!.docs.map((doc) {
                  return Recipe.fromFirestore(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favoriteRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = favoriteRecipes[index];
                    return RecipeCard(recipe: recipe);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // Build the grid view for liked recipes
  Widget _buildLikedGridView() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("No user logged in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('archives')
          .snapshots(),
      builder: (context, archiveSnap) {
        if (archiveSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final archivedIds = <String>{
          if (archiveSnap.hasData) ...archiveSnap.data!.docs.map((d) => d.id),
        };

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('recipes')
              .where('likedBy', arrayContains: user.uid)
              .snapshots(),
          builder: (context, likedSnap) {
            if (likedSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!likedSnap.hasData || likedSnap.data!.docs.isEmpty) {
              return const Center(child: Text("No liked recipes yet."));
            }

            final likedRecipes = likedSnap.data!.docs
                .where((doc) => !archivedIds.contains(doc.id))
                .map((doc) {
                  return {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id, // Add the document ID
                  };
                })
                .toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: likedRecipes.length,
              itemBuilder: (context, index) {
                final recipeData = likedRecipes[index];
                final recipe = Recipe.fromFirestore(
                  recipeData['id'] ?? '',
                  recipeData,
                );
                return RecipeCard(recipe: recipe);
              },
            );
          },
        );
      },
    );
  }
}
