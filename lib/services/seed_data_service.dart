import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/mock_data.dart';

class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seed the database with mock data
  Future<void> seedDatabase(String currentUserId) async {
    try {
      print('Starting database seeding...');

      // Get mock data
      final mockGroups = MockDataService.getGroups();
      final mockFriends = MockDataService.friends;

      // Create users (friends) in Firestore
      for (var friend in mockFriends) {
        await _firestore.collection('users').doc(friend.id).set({
          'name': friend.name,
          'email':
              friend.email ??
              '${friend.name.toLowerCase().replaceAll(' ', '')}@example.com',
          'photoUrl': friend.avatarUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Create friendships
      for (var friend in mockFriends) {
        await _firestore.collection('friendships').add({
          'userId1': currentUserId,
          'userId2': friend.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Create groups
      for (var group in mockGroups) {
        // Add current user to members if not already present
        final memberIds = group.members.map((m) => m.id).toList();
        if (!memberIds.contains(currentUserId)) {
          memberIds.add(currentUserId);
        }

        final groupRef = await _firestore.collection('groups').add({
          'name': group.name,
          'type': group.type,
          'coverUrl': group.coverUrl,
          'memberIds': memberIds,
          'createdBy': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create expenses for this group
        for (var expense in group.expenses) {
          await _firestore.collection('expenses').add({
            'description': expense.description,
            'amount': expense.amount,
            'date': Timestamp.fromDate(expense.date),
            'payerId': expense.payerId,
            'groupId': groupRef.id,
            'splitDetails': expense.splitDetails,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      print('Database seeding completed successfully!');
    } catch (e) {
      print('Error seeding database: $e');
      rethrow;
    }
  }

  // Check if database has been seeded
  Future<bool> isDatabaseSeeded(String currentUserId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: currentUserId)
          .limit(1)
          .get();

      return groupsSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if database is seeded: $e');
      return false;
    }
  }

  // Seed database if not already seeded
  Future<void> seedIfNeeded(String currentUserId) async {
    final isSeeded = await isDatabaseSeeded(currentUserId);
    if (!isSeeded) {
      await seedDatabase(currentUserId);
    } else {
      print('Database already seeded, skipping...');
    }
  }
}
