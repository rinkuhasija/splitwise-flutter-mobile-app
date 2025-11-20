import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../theme/app_theme.dart';
import '../../friends/friend_details_screen.dart';

class FriendItem extends StatelessWidget {
  final User user;

  const FriendItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Hero(
        tag: 'friend_avatar_${user.id}',
        child: CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.surface,
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'owes you ₹0.00', // Dummy status
        style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
      ),
      trailing: Text(
        'settled',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendDetailsScreen(user: user),
          ),
        );
      },
    );
  }
}
