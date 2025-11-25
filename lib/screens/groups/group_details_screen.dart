import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/group.dart';
import '../../models/expense.dart';
import '../../theme/app_theme.dart';
import '../expenses/add_expense_screen.dart';
import '../../providers/data_provider.dart';
import '../settlement/record_settlement_screen.dart';
import 'widgets/expense_chart.dart';

class GroupDetailsScreen extends StatelessWidget {
  final Group group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return StreamBuilder<List<Expense>>(
          stream: dataProvider.getGroupExpenses(group.id),
          builder: (context, snapshot) {
            final expenses = snapshot.data ?? [];

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Row(
                      children: [
                        Hero(
                          tag: 'group_icon_${group.id}',
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getGroupIcon(group.type),
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(group.name),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        tooltip: 'Invite via Link',
                        onPressed: () {
                          final link =
                              'splitwiseclone://join?groupId=${group.id}';
                          Share.share(
                            'Join my group "${group.name}" on Splitwise Clone: $link',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: () => _showAddMemberDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showGroupMembersDialog(context),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'settle') {
                            _showSettleUpDialog(context, dataProvider);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'settle',
                            child: Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.handshake,
                                  size: 18,
                                  color: AppTheme.success,
                                ),
                                SizedBox(width: 12),
                                Text('Settle Up'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primary.withOpacity(0.2),
                              AppTheme.secondary,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending this week',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ExpenseChart(
                            expenses: expenses,
                            members: group.members,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(child: Text('Error: ${snapshot.error}')),
                      ),
                    )
                  else if (snapshot.connectionState == ConnectionState.waiting)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (expenses.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text('No expenses yet'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final expense = expenses[index];
                          return _buildExpenseItem(
                            context,
                            expense,
                            index,
                            dataProvider.currentUser?.id,
                          );
                        }, childCount: expenses.length),
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(groupId: group.id),
                    ),
                  );
                },
                backgroundColor: AppTheme.primary,
                icon: const Icon(FontAwesomeIcons.receipt),
                label: const Text('Add Expense'),
              ).animate().scale(delay: 300.ms),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseItem(
    BuildContext context,
    Expense expense,
    int index,
    String? currentUserId,
  ) {
    final isPayer = expense.payerId == currentUserId;
    final myShare = expense.splitDetails[currentUserId] ?? 0.0;

    double displayAmount;
    String actionText;
    Color textColor;

    if (isPayer) {
      displayAmount = expense.amount - myShare;
      actionText = 'you lent';
      textColor = AppTheme.success;
    } else {
      displayAmount = myShare;
      actionText = 'you borrowed';
      textColor = AppTheme.accent;
    }

    // If user is not involved (share is 0 and not payer)
    if (!isPayer && myShare == 0) {
      actionText = 'not involved';
      displayAmount = 0;
      textColor = AppTheme.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: expense.isSettlement
                ? AppTheme.success.withOpacity(0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: expense.isSettlement
                ? Border.all(color: AppTheme.success.withOpacity(0.3))
                : Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: expense.isSettlement
              ? const Icon(
                  FontAwesomeIcons.circleCheck,
                  color: AppTheme.success,
                  size: 20,
                )
              : Text(
                  DateFormat('MMM\ndd').format(expense.date),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'paid by ${isPayer ? 'you' : 'someone'}',
          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${displayAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
            Text(
              actionText,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Show expense details
        },
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX();
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

  void _showAddMemberDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            final availableFriends = dataProvider.friends.where((friend) {
              return !group.members.any((member) => member.id == friend.id);
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add friend to group',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (availableFriends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No friends available to add.\nAdd more friends from the Home screen.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableFriends.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppTheme.secondary),
                        itemBuilder: (context, index) {
                          final friend = availableFriends[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(
                                friend.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                FontAwesomeIcons.plus,
                                color: AppTheme.primary,
                              ),
                              onPressed: () {
                                dataProvider.addMemberToGroup(group.id, friend);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${friend.name} added to ${group.name}',
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGroupMembersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Members',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: group.members.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppTheme.secondary),
                  itemBuilder: (context, index) {
                    final member = group.members[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        member.email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettleUpDialog(BuildContext context, DataProvider dataProvider) {
    final currentUserId = dataProvider.currentUser?.id;
    if (currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.handshake,
                    color: AppTheme.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settle Up',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a member to settle with',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: FutureBuilder<List<MapEntry<String, double>>>(
                  future: _calculateMemberBalances(dataProvider, currentUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final balances = snapshot.data ?? [];
                    final nonZeroBalances = balances
                        .where((entry) => entry.value.abs() >= 0.01)
                        .toList();

                    if (nonZeroBalances.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'All settled up!',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: nonZeroBalances.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: AppTheme.secondary),
                      itemBuilder: (context, index) {
                        final entry = nonZeroBalances[index];
                        final memberId = entry.key;
                        final balance = entry.value;
                        final member = group.members.firstWhere(
                          (m) => m.id == memberId,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            child: Text(
                              member.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            balance > 0
                                ? 'Owes you ₹${balance.toStringAsFixed(2)}'
                                : 'You owe ₹${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: balance > 0
                                  ? AppTheme.success
                                  : AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.arrowRight,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecordSettlementScreen(
                                    friend: member,
                                    groupId: group.id,
                                    currentBalance: balance,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<MapEntry<String, double>>> _calculateMemberBalances(
    DataProvider dataProvider,
    String currentUserId,
  ) async {
    final expenses = await dataProvider.getGroupExpenses(group.id).first;
    final Map<String, double> balances = {};

    // Initialize balances for all members except current user
    for (final member in group.members) {
      if (member.id != currentUserId) {
        balances[member.id] = 0.0;
      }
    }

    // Calculate balances
    for (final expense in expenses) {
      final paidByMe = expense.payerId == currentUserId;
      final myShare = expense.splitDetails[currentUserId] ?? 0.0;

      for (final member in group.members) {
        if (member.id == currentUserId) continue;

        final memberShare = expense.splitDetails[member.id] ?? 0.0;
        final paidByMember = expense.payerId == member.id;

        if (paidByMe && memberShare > 0) {
          // I paid, member owes me
          balances[member.id] = (balances[member.id] ?? 0) + memberShare;
        } else if (paidByMember && myShare > 0) {
          // Member paid, I owe member
          balances[member.id] = (balances[member.id] ?? 0) - myShare;
        }
      }
    }

    return balances.entries.toList();
  }
}
