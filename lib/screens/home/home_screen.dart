import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../models/group.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import 'widgets/group_card.dart';
import 'widgets/friend_item.dart';
import '../groups/create_group_screen.dart';
import '../friends/add_friend_screen.dart';
import '../profile/profile_screen.dart';
import '../activity/activity_feed.dart';
import '../expenses/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Splitwise'),
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.user),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.userPlus),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.users),
            tooltip: 'Create Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Groups'),
            Tab(text: 'Friends'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: Consumer<DataProvider>(
        builder: (context, dataProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildGroupsList(dataProvider.groups),
              _buildFriendsList(dataProvider.friends),
              const ActivityFeed(),
            ],
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primary,
            icon: const Icon(FontAwesomeIcons.plus),
            label: const Text('Add Expense'),
          ).animate().scale(
            delay: 500.ms,
            duration: 300.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildGroupsList(List<Group> groups) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              FontAwesomeIcons.users,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
              child: const Text('Start a new group'),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return GroupCard(
          group: groups[index],
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildFriendsList(List<User> friends) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      separatorBuilder: (context, index) =>
          const Divider(color: AppTheme.surface),
      itemBuilder: (context, index) {
        return FriendItem(
          user: friends[index],
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}
