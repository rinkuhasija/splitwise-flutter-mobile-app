import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../models/group.dart';
import '../../../theme/app_theme.dart';
import '../../groups/group_details_screen.dart';
import '../../../providers/data_provider.dart';

class GroupCard extends StatelessWidget {
  final Group group;

  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(group: group),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'group_icon_${group.id}',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getGroupIcon(group.type),
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.type,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FutureBuilder<double>(
                future: Provider.of<DataProvider>(
                  context,
                  listen: true,
                ).getGroupBalance(group.id),
                builder: (context, snapshot) {
                  final balance = snapshot.data ?? 0.0;
                  final isOwed = balance > 0;
                  final absBalance = balance.abs();

                  if (balance == 0) {
                    return Text(
                      'settled up',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOwed ? 'you are owed' : 'you owe',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isOwed ? AppTheme.success : AppTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${absBalance.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isOwed
                                  ? AppTheme.success
                                  : AppTheme.accent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGroupIcon(String type) {
    switch (type.toLowerCase()) {
      case 'trip':
        return FontAwesomeIcons.plane;
      case 'home':
        return FontAwesomeIcons.house;
      case 'couple':
        return FontAwesomeIcons.heart;
      default:
        return FontAwesomeIcons.users;
    }
  }
}
