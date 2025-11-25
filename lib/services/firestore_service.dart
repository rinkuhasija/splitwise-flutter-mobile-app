import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/settlement.dart';

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

  // Update user profile
  Future<void> updateUser(
    String userId, {
    String? name,
    String? photoUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      print('Error updating user: $e');
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
                isSettlement: expenseData['isSettlement'] ?? false,
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
    bool isSettlement = false,
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
        'isSettlement': isSettlement,
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
              isSettlement: data['isSettlement'] ?? false,
            );
          }).toList();
          // Sort in memory instead of in the query
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  // ==================== FRIENDS ====================

  // Add friend
  Future<void> addFriend(String userId1, String userId2) async {
    try {
      // Check if friendship already exists
      final query = await _firestore
          .collection('friendships')
          .where('userId1', isEqualTo: userId1)
          .where('userId2', isEqualTo: userId2)
          .get();

      if (query.docs.isEmpty) {
        // Create bidirectional friendship
        await _firestore.collection('friendships').add({
          'userId1': userId1,
          'userId2': userId2,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('friendships').add({
          'userId1': userId2,
          'userId2': userId1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }

  // Get user friends
  Stream<List<User>> getUserFriends(String userId) {
    return _firestore
        .collection('friendships')
        .where('userId1', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final friendIds = snapshot.docs
              .map((doc) => doc.data()['userId2'] as String)
              .toList();

          if (friendIds.isEmpty) return [];

          final friends = await Future.wait(friendIds.map((id) => getUser(id)));

          return friends.whereType<User>().toList();
        });
  }

  // ==================== ACTIVITY ====================

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
              isSettlement: data['isSettlement'] ?? false,
            );
          }).toList();
          // Sort in memory instead of in the query
          expenses.sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  // ==================== DEEP LINKING SUPPORT ====================

  // Add member to group
  Future<void> addMemberToGroup(String groupId, User user) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final List<dynamic> currentMembers = groupDoc.data()?['memberIds'] ?? [];

      if (!currentMembers.contains(user.id)) {
        await _firestore.collection('groups').doc(groupId).update({
          'memberIds': FieldValue.arrayUnion([user.id]),
        });
      }
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  // Get single group details
  Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _firestore.collection('groups').doc(groupId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;

      // Get members
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final members = await Future.wait(memberIds.map((id) => getUser(id)));

      // Get expenses
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
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
          isSettlement: expenseData['isSettlement'] ?? false,
        );
      }).toList();

      return Group(
        id: doc.id,
        name: data['name'] ?? '',
        type: data['type'] ?? '',
        coverUrl: data['coverUrl'],
        members: members.whereType<User>().toList(),
        expenses: expenses,
      );
    } catch (e) {
      print('Error getting group: $e');
      return null;
    }
  }

  // ==================== SETTLEMENTS ====================

  // Record a settlement between two users
  Future<String> recordSettlement({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String groupId,
    String? note,
  }) async {
    try {
      // Create settlement record
      final settlementRef = await _firestore.collection('settlements').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'date': Timestamp.now(),
        'groupId': groupId,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also create as an expense for balance calculation
      // Settlement is recorded as: fromUser pays toUser
      // The split details should show: fromUser paid 0, toUser received amount
      // This way the balance calculation will properly offset previous debts
      await addExpense(
        description: note ?? 'Settlement payment',
        amount: amount,
        payerId: fromUserId,
        groupId: groupId,
        splitDetails: {
          fromUserId: 0, // Payer's share is 0 (they paid but owe nothing)
          toUserId: amount, // Receiver gets the full amount
        },
        isSettlement: true,
      );

      return settlementRef.id;
    } catch (e) {
      print('Error recording settlement: $e');
      rethrow;
    }
  }

  // Get settlements for a user
  Stream<List<Settlement>> getUserSettlements(String userId) {
    return _firestore
        .collection('settlements')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final settlements = snapshot.docs.map((doc) {
            return Settlement.fromMap(doc.id, doc.data());
          }).toList();
          // Sort by date (newest first)
          settlements.sort((a, b) => b.date.compareTo(a.date));
          return settlements;
        });
  }

  // Get settlements between two specific users
  Stream<List<Settlement>> getSettlementsBetweenUsers(
    String userId1,
    String userId2,
  ) {
    return _firestore.collection('settlements').snapshots().map((snapshot) {
      final settlements = snapshot.docs
          .map((doc) => Settlement.fromMap(doc.id, doc.data()))
          .where((settlement) {
            return (settlement.fromUserId == userId1 &&
                    settlement.toUserId == userId2) ||
                (settlement.fromUserId == userId2 &&
                    settlement.toUserId == userId1);
          })
          .toList();
      // Sort by date (newest first)
      settlements.sort((a, b) => b.date.compareTo(a.date));
      return settlements;
    });
  }

  // Get settlements for a specific group
  Stream<List<Settlement>> getGroupSettlements(String groupId) {
    return _firestore
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final settlements = snapshot.docs.map((doc) {
            return Settlement.fromMap(doc.id, doc.data());
          }).toList();
          // Sort by date (newest first)
          settlements.sort((a, b) => b.date.compareTo(a.date));
          return settlements;
        });
  }
}
