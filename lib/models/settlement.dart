class Settlement {
  final String id;
  final String fromUserId; // User who is paying
  final String toUserId; // User who is receiving
  final double amount;
  final DateTime date;
  final String? groupId; // Optional group context
  final String? note; // Optional note/description

  Settlement({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.date,
    this.groupId,
    this.note,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'date': date,
      'groupId': groupId,
      'note': note,
    };
  }

  // Create from Firestore document
  factory Settlement.fromMap(String id, Map<String, dynamic> map) {
    return Settlement(
      id: id,
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date']?.toDate() ?? DateTime.now(),
      groupId: map['groupId'],
      note: map['note'],
    );
  }
}
