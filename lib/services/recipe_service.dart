import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb

class RecipeService {
  final String cloudName =
      'djfp5dnqc'; // Replace with your Cloudinary cloud name
  final String uploadPreset = 'dishcovery'; // Replace with your upload preset

  // Upload image to Cloudinary

  Future<String?> uploadImage(
    File? imageFile, {
    Uint8List? webImageBytes,
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;

    try {
      if (kIsWeb) {
        // For web: Use bytes instead of file path
        if (webImageBytes == null) {
          throw Exception("No image bytes provided for web upload");
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImageBytes,
            filename: 'uploaded_image.jpg', // Provide a filename
          ),
        );
      } else {
        // For mobile: Use file path
        if (imageFile == null) {
          throw Exception("No image file provided for mobile upload");
        }
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url']; // Return the image URL
      } else {
        print('Failed to upload image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> saveRecipe({
    required String title,
    required String description,
    required String imageUrl,
    required double rating,
    required int duration,
    required List<String> ingredients,
    required List<String> steps,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Get user's username from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String username = 'Unknown User';
      if (userDoc.exists && userDoc.data() != null) {
        username = userDoc.data()!['username'] ?? 'Unknown User';
      }

      await FirebaseFirestore.instance.collection('recipes').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl, // Ensure this is passed correctly
        'rating': rating,
        'duration': duration,
        'ingredients': ingredients,
        'steps': steps,
        'userId': user.uid, // Ensure userId is added
        'username': username, // Add username for easy access
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Recipe saved successfully!');
    } catch (e) {
      print('Failed to save recipe: $e');
      throw Exception('Failed to save recipe: $e');
    }
  }

  Future<void> updateRecipe({
    required String recipeId,
    required Map<String, dynamic> data,
  }) async {
    await FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .update(data);
  }
}
