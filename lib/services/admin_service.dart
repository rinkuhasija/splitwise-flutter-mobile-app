import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Deletes all mock data from Firestore while preserving the current user's data
  Future<void> deleteAllMockData() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('No user logged in');
        return;
      }

      print('Starting to delete mock data...');

      // Delete all expenses
      final expensesSnapshot = await _firestore.collection('expenses').get();
      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted expense: ${doc.id}');
      }

      // Delete all friendships
      final friendshipsSnapshot = await _firestore
          .collection('friendships')
          .get();
      for (var doc in friendshipsSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted friendship: ${doc.id}');
      }

      // Delete all groups
      final groupsSnapshot = await _firestore.collection('groups').get();
      for (var doc in groupsSnapshot.docs) {
        await doc.reference.delete();
        print('Deleted group: ${doc.id}');
      }

      // Delete all users EXCEPT the current user
      final usersSnapshot = await _firestore.collection('users').get();
      for (var doc in usersSnapshot.docs) {
        if (doc.id != currentUserId) {
          await doc.reference.delete();
          print('Deleted user: ${doc.id}');
        } else {
          print('Preserved current user: ${doc.id}');
        }
      }

      print('Mock data deletion completed!');
    } catch (e) {
      print('Error deleting mock data: $e');
      rethrow;
    }
  }

  /// Deletes EVERYTHING including current user (use with caution!)
  Future<void> deleteAllData() async {
    try {
      print('Starting to delete ALL data...');

      // Delete all collections
      final collections = ['expenses', 'friendships', 'groups', 'users'];

      for (var collectionName in collections) {
        final snapshot = await _firestore.collection(collectionName).get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
          print('Deleted $collectionName: ${doc.id}');
        }
      }

      print('All data deletion completed!');
    } catch (e) {
      print('Error deleting all data: $e');
      rethrow;
    }
  }
}
