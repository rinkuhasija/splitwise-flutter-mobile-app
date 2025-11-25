import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
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
      subtitle: FutureBuilder<double>(
        future: Provider.of<DataProvider>(
          context,
          listen: true,
        ).getFriendBalance(user.id),
        builder: (context, snapshot) {
          final balance = snapshot.data ?? 0.0;
          if (balance == 0) {
            return Text(
              'settled up',
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
            );
          }
          final isOwed = balance > 0;
          return Text(
            '${isOwed ? 'owes you' : 'you owe'} ₹${balance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isOwed ? AppTheme.success : AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          );
        },
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
