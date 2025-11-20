import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USERS ====================

  // Create a new user
  Future<String> createUser({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return userId;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return User(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          avatarUrl: data['photoUrl'],
        );
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get all users (for friends list)
  Stream<List<User>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          avatarUrl: data['photoUrl'],
        );
      }).toList();
    });
  }

  // ==================== GROUPS ====================

  // Get groups for a user
  Stream<List<Group>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Group> groups = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Get members
            final memberIds = List<String>.from(data['memberIds'] ?? []);
            final members = await Future.wait(
              memberIds.map((id) => getUser(id)),
            );

            // Get expenses for this group
            final expensesSnapshot = await _firestore
                .collection('expenses')
                .where('groupId', isEqualTo: doc.id)
                .get();

            final expenses = expensesSnapshot.docs.map((expenseDoc) {
              final expenseData = expenseDoc.data();
              return Expense(
                id: expenseDoc.id,
                description: expenseData['description'] ?? '',
                amount: (expenseData['amount'] ?? 0).toDouble(),
                date: (expenseData['date'] as Timestamp).toDate(),
                payerId: expenseData['payerId'] ?? '',
                groupId: expenseData['groupId'] ?? '',
                splitDetails: Map<String, double>.from(
                  expenseData['splitDetails'] ?? {},
                ),
                participantIds: List<String>.from(
                  expenseData['participantIds'] ?? [],
                ),
              );
            }).toList();

            groups.add(
              Group(
                id: doc.id,
                name: data['name'] ?? '',
                type: data['type'] ?? '',
                coverUrl: data['coverUrl'],
                members: members.whereType<User>().toList(),
                expenses: expenses,
              ),
            );
          }

          return groups;
        });
  }

  // Create a new group
  Future<String> createGroup({
    required String name,
    required String type,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    try {
      final docRef = await _firestore.collection('groups').add({
        'name': name,
        'type': type,
        'memberIds': memberIds,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }

  // Add member to group
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  // ==================== EXPENSES ====================

  // Add expense
  Future<String> addExpense({
    required String description,
    required double amount,
    required String payerId,
    required String groupId,
    required Map<String, double> splitDetails,
  }) async {
    try {
      final docRef = await _firestore.collection('expenses').add({
        'description': description,
        'amount': amount,
        'date': Timestamp.now(),
        'payerId': payerId,
        'groupId': groupId,
        'splitDetails': splitDetails,
        'participantIds': [payerId, ...splitDetails.keys],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Get expenses for a group
  Stream<List<Expense>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) {
            final data = doc.data();
            return Expense(
              id: doc.id,
              description: data['description'] ?? '',
              amount: (data['amount'] ?? 0).toDouble(),
              date: (data['date'] as Timestamp).toDate(),
              payerId: data['payerId'] ?? '',
              groupId: data['groupId'] ?? '',
              splitDetails: Map<String, double>.from(
                data['splitDetails'] ?? {},
              ),
              participantIds: List<String>.from(data['participantIds'] ?? []),
            );
          }).toList();
          // Sort in memory instead of in the query
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  // ==================== FRIENDSHIPS ====================

  // Add friend (create friendship)
  Future<void> addFriend(String userId1, String userId2) async {
    try {
      await _firestore.collection('friendships').add({
        'userId1': userId1,
        'userId2': userId2,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }

  // Get friends for a user
  Stream<List<User>> getUserFriends(String userId) {
    return _firestore
        .collection('friendships')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final friendIds = snapshot.docs
              .map((doc) => doc.data()['userId2'] as String)
              .toList();

          final friends = await Future.wait(friendIds.map((id) => getUser(id)));

          return friends.whereType<User>().toList();
        });
  }

  // Get recent activity for a user
  Stream<List<Expense>> getUserActivity(String userId) {
    return _firestore
        .collection('expenses')
        .where('participantIds', arrayContains: userId)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) {
            final data = doc.data();
            return Expense(
              id: doc.id,
              description: data['description'] ?? '',
              amount: (data['amount'] ?? 0).toDouble(),
              date: (data['date'] as Timestamp).toDate(),
              payerId: data['payerId'] ?? '',
              groupId: data['groupId'] ?? '',
              splitDetails: Map<String, double>.from(
                data['splitDetails'] ?? {},
              ),
              participantIds: List<String>.from(data['participantIds'] ?? []),
            );
          }).toList();
          // Sort in memory instead of in the query
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }
}
