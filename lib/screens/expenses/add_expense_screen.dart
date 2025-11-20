import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/group.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? groupId;
  const AddExpenseScreen({super.key, this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedGroupId;
  Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final groups = dataProvider.groups;

    // If no group is selected and there are groups, default to the first one
    if (_selectedGroupId == null && groups.isNotEmpty) {
      _selectedGroupId = groups.first.id;
    }

    // Return early if no groups exist
    if (groups.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.users,
                size: 64,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'No groups yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a group first to add expenses',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Get members of the selected group
    final selectedGroup = groups.firstWhere(
      (g) => g.id == _selectedGroupId,
      orElse: () => groups.first,
    );
    final members = selectedGroup.members;

    // Initialize selected members if empty (default to all except current user)
    if (_selectedMemberIds.isEmpty && members.isNotEmpty) {
      final currentUserId = dataProvider.currentUser?.id;
      _selectedMemberIds = members
          .where((m) => currentUserId != null && m.id != currentUserId)
          .map((m) => m.id)
          .toSet();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add expense'),
        actions: [
          TextButton(
            onPressed: () {
              if (_descriptionController.text.isNotEmpty &&
                  _amountController.text.isNotEmpty &&
                  _selectedGroupId != null) {
                final amount = double.tryParse(_amountController.text) ?? 0.0;

                // Calculate split details
                final splitDetails = <String, double>{};
                final currentUserId =
                    dataProvider.currentUser?.id ?? 'curr_user';
                final involvedUsers = [currentUserId, ..._selectedMemberIds];
                final splitAmount = amount / involvedUsers.length;

                for (final userId in involvedUsers) {
                  splitDetails[userId] = splitAmount;
                }

                dataProvider.addExpense(
                  _selectedGroupId!,
                  _descriptionController.text,
                  amount,
                  currentUserId,
                  splitDetails,
                );
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.groupId == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGroupId,
                    isExpanded: true,
                    hint: const Text('Select a group'),
                    items: groups.map((Group group) {
                      return DropdownMenuItem<String>(
                        value: group.id,
                        child: Text(group.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGroupId = newValue;
                        _selectedMemberIds
                            .clear(); // Reset selection on group change
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.receipt,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a description',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.textSecondary.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.dollarSign,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'With you and:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members
                  .where(
                    (m) =>
                        dataProvider.currentUser != null &&
                        m.id != dataProvider.currentUser!.id,
                  )
                  .map((member) {
                    final isSelected = _selectedMemberIds.contains(member.id);
                    return FilterChip(
                      label: Text(member.name),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedMemberIds.add(member.id);
                          } else {
                            _selectedMemberIds.remove(member.id);
                          }
                        });
                      },
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.textSecondary.withOpacity(0.3),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Paid by '),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('you'),
                ).animate().scale(delay: 300.ms, duration: 200.ms),
                const Text(' and split '),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    _selectedMemberIds.isEmpty
                        ? 'equally'
                        : 'with ${_selectedMemberIds.length} people',
                  ),
                ).animate().scale(delay: 400.ms, duration: 200.ms),
              ],
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }
}
