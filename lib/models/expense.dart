class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String payerId;
  final String groupId;
  final Map<String, double> splitDetails; // UserId -> Amount
  final bool isSettlement; // Flag to identify settlement transactions

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.payerId,
    required this.groupId,
    required this.splitDetails,
    this.participantIds = const [],
    this.isSettlement = false,
  });

  final List<String> participantIds;
}
