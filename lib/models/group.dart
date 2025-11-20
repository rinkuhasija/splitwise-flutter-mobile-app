import 'user.dart';
import 'expense.dart';

class Group {
  final String id;
  final String name;
  final String type; // e.g., "Trip", "Home", "Couple"
  final String? coverUrl;
  final List<User> members;
  final List<Expense> expenses;

  Group({
    required this.id,
    required this.name,
    required this.type,
    this.coverUrl,
    required this.members,
    this.expenses = const [],
  });

  double get totalExpenses {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }
}
