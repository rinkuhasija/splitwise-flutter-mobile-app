import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/user.dart' as app_user;

class DataProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<Group> _groups = [];
  List<app_user.User> _friends = [];
  app_user.User? _currentUser;
  bool _isLoading = true;

  List<Group> get groups => _groups;
  List<app_user.User> get friends => _friends;
  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  DataProvider() {
    _initializeData();
  }

  void _initializeData() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        _clearData();
      }
    });
  }

  Future<void> _loadUserData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user
      _currentUser = await _firestoreService.getUser(userId);

      // If user doesn't exist in Firestore, create it from Firebase Auth
      if (_currentUser == null) {
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          print('Creating user document for ${firebaseUser.uid}');
          await _firestoreService.createUser(
            userId: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Unknown',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
          );
          // Try to get the user again
          _currentUser = await _firestoreService.getUser(userId);
        }
      }

      print('DataProvider: currentUser loaded = $_currentUser');

      // REMOVED: Automatic mock data seeding
      // Uncomment the line below if you want to seed data for testing:
      // await _seedDataService.seedIfNeeded(userId);

      // Listen to groups
      _firestoreService.getUserGroups(userId).listen((groups) {
        _groups = groups;
        notifyListeners();
      });

      // Listen to friends
      _firestoreService.getUserFriends(userId).listen((friends) {
        _friends = friends;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearData() {
    _groups = [];
    _friends = [];
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  // Add a new group
  Future<void> addGroup(String name, String type) async {
    if (_currentUser == null) return;

    try {
      await _firestoreService.createGroup(
        name: name,
        type: type,
        memberIds: [_currentUser!.id],
        createdBy: _currentUser!.id,
      );
      // The stream will automatically update the UI
    } catch (e) {
      print('Error adding group: $e');
      rethrow;
    }
  }

  // Add a new friend
  Future<void> addFriend(String name, String email) async {
    if (_currentUser == null) return;

    try {
      // Create a new user document for the friend
      final friendId = const Uuid().v4();
      await _firestoreService.createUser(
        userId: friendId,
        name: name,
        email: email,
      );

      // Create friendship
      await _firestoreService.addFriend(_currentUser!.id, friendId);

      // The stream will automatically update the UI
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }

  // Add a new expense
  Future<void> addExpense(
    String groupId,
    String description,
    double amount,
    String payerId,
    Map<String, double> splitDetails,
  ) async {
    try {
      await _firestoreService.addExpense(
        description: description,
        amount: amount,
        payerId: payerId,
        groupId: groupId,
        splitDetails: splitDetails,
      );
      // The stream will automatically update the UI
    } catch (e) {
      print('Error adding expense: $e');
      rethrow;
    }
  }

  // Add member to group
  Future<void> addMemberToGroup(String groupId, app_user.User user) async {
    try {
      await _firestoreService.addMemberToGroup(groupId, user.id);
      // The stream will automatically update the UI
    } catch (e) {
      print('Error adding member to group: $e');
      rethrow;
    }
  }

  // Get expenses for a group
  Stream<List<Expense>> getGroupExpenses(String groupId) {
    return _firestoreService.getGroupExpenses(groupId);
  }

  Stream<List<Expense>> getUserActivity() {
    if (_currentUser == null) return Stream.value([]);
    return _firestoreService.getUserActivity(_currentUser!.id);
  }
}
