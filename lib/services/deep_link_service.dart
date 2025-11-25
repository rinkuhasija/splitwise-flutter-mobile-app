import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../screens/groups/group_details_screen.dart';
import 'firestore_service.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription? _linkSubscription;

  void initDeepLinks(BuildContext context) {
    _checkInitialLink(context);
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(context, uri);
    });
  }

  Future<void> _checkInitialLink(BuildContext context) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(context, uri);
      }
    } catch (e) {
      debugPrint('Error checking initial link: $e');
    }
  }

  void _handleDeepLink(BuildContext context, Uri uri) async {
    if (uri.scheme == 'splitwiseclone' && uri.host == 'join') {
      final groupId = uri.queryParameters['groupId'];
      if (groupId != null) {
        await _joinGroup(context, groupId);
      }
    }
  }

  Future<void> _joinGroup(BuildContext context, String groupId) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final currentUser = dataProvider.currentUser;

    if (currentUser == null) {
      // If user is not logged in, we might want to store the groupId and handle it after login
      // For now, we'll just show a message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to join the group')),
        );
      }
      return;
    }

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Add user to group
      await _firestoreService.addMemberToGroup(groupId, currentUser);

      // Refresh data
      // Note: DataProvider listens to streams, so it should update automatically,
      // but we might want to ensure the group is in the local list

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading

        // Find the group object to navigate to details
        // We might need to fetch it if it's not in the list yet
        final group = await _firestoreService.getGroup(groupId);

        if (context.mounted) {
          if (group != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailsScreen(group: group),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Joined group successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Group not found')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error joining group: $e')));
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
