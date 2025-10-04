import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Banned', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD580),
        title: const Text(
          'Manage Users',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          // Filter dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: Container(),
              items: _filterOptions.map((String filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final users = snapshot.data!.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList();

          // Filter users based on selected filter
          List<Map<String, dynamic>> filteredUsers = users.where((user) {
            switch (_selectedFilter) {
              case 'Active':
                return !(user['isBanned'] ?? false) && user['role'] != 'admin';
              case 'Banned':
                return user['isBanned'] ?? false;
              case 'Admin':
                return user['role'] == 'admin';
              default:
                return true; // All
            }
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isBanned = user['isBanned'] ?? false;
    final role = user['role'] ?? 'user';
    final profilePictureURL = user['profilePictureURL'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile picture and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profilePictureURL.isNotEmpty
                      ? NetworkImage(profilePictureURL)
                      : null,
                  child: profilePictureURL.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user['fullName'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status badges
                          if (isBanned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Banned',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          if (role == 'admin')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user['username'] ?? 'No Username'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? 'No Email',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // User stats with real-time data
                      Row(
                        children: [
                          _buildUserStatItem(
                            Icons.post_add,
                            'Posts',
                            user['id'],
                            'posts',
                          ),
                          const SizedBox(width: 16),
                          _buildUserStatItem(
                            Icons.favorite,
                            'Likes',
                            user['id'],
                            'likes',
                          ),
                          const SizedBox(width: 16),
                          _buildUserStatItem(
                            Icons.bookmark,
                            'Favorites',
                            user['id'],
                            'favorites',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bio
            if (user['bio'] != null && user['bio'].isNotEmpty)
              Text(
                user['bio'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.person,
                  label: 'Profile',
                  color: Colors.blue,
                  onTap: () => _viewUserProfile(user),
                ),
                _buildActionButton(
                  icon: isBanned ? Icons.check_circle : Icons.block,
                  label: isBanned ? 'Unban' : 'Ban',
                  color: isBanned ? Colors.green : Colors.red,
                  onTap: () => _toggleBan(user),
                ),
                _buildActionButton(
                  icon: Icons.admin_panel_settings,
                  label: role == 'admin' ? 'Remove Admin' : 'Make Admin',
                  color: role == 'admin' ? Colors.orange : Colors.purple,
                  onTap: () => _toggleRole(user),
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onTap: () => _deleteUser(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatItem(
    IconData icon,
    String label,
    String userId,
    String statType,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStatStream(userId, statType),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }

        return Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getStatStream(String userId, String statType) {
    switch (statType) {
      case 'posts':
        return FirebaseFirestore.instance
            .collection('recipes')
            .where('userId', isEqualTo: userId)
            .snapshots();
      case 'likes':
        return FirebaseFirestore.instance
            .collection('recipes')
            .where('likedBy', arrayContains: userId)
            .snapshots();
      case 'favorites':
        return FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .snapshots();
      default:
        return FirebaseFirestore.instance.collection('users').snapshots();
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: user['id']),
      ),
    );
  }

  void _toggleBan(Map<String, dynamic> user) async {
    final isBanned = user['isBanned'] ?? false;
    final action = isBanned ? 'unban' : 'ban';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isBanned ? 'Unban' : 'Ban'} User'),
        content: Text(
          'Are you sure you want to ${action} ${user['fullName']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmToggleBan(user);
            },
            child: Text(
              isBanned ? 'Unban' : 'Ban',
              style: TextStyle(color: isBanned ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggleBan(Map<String, dynamic> user) async {
    try {
      final isBanned = user['isBanned'] ?? false;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .update({'isBanned': !isBanned});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBanned
                  ? 'User unbanned successfully'
                  : 'User banned successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleRole(Map<String, dynamic> user) async {
    final currentRole = user['role'] ?? 'user';
    final newRole = currentRole == 'admin' ? 'user' : 'admin';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newRole == 'admin' ? 'Make' : 'Remove'} Admin'),
        content: Text(
          'Are you sure you want to ${newRole == 'admin' ? 'make' : 'remove'} ${user['fullName']} ${newRole == 'admin' ? 'an' : 'from'} admin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmToggleRole(user, newRole);
            },
            child: Text(
              newRole == 'admin' ? 'Make Admin' : 'Remove Admin',
              style: TextStyle(
                color: newRole == 'admin' ? Colors.purple : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggleRole(
    Map<String, dynamic> user,
    String newRole,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .update({'role': newRole});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRole == 'admin'
                  ? 'User promoted to admin'
                  : 'User role changed to user',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _deleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user['fullName']}? This action cannot be undone and will delete all their posts and data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmDeleteUser(user);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    try {
      // Delete user's posts first
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('userId', isEqualTo: user['id'])
          .get();

      final batch = FirebaseFirestore.instance.batch();

      // Delete all user's posts
      for (final doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      batch.delete(
        FirebaseFirestore.instance.collection('users').doc(user['id']),
      );

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }
}
