import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';

class MockDataService {
  static const _uuid = Uuid();

  static final User currentUser = User(
    id: 'curr_user',
    name: 'You',
    email: 'you@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?u=curr_user',
  );

  static final List<User> friends = [
    User(
      id: 'u1',
      name: 'Alice',
      email: 'alice@test.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u1',
    ),
    User(
      id: 'u2',
      name: 'Bob',
      email: 'bob@test.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u2',
    ),
    User(
      id: 'u3',
      name: 'Charlie',
      email: 'charlie@test.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u3',
    ),
    User(
      id: 'u4',
      name: 'David',
      email: 'david@test.com',
      avatarUrl: 'https://i.pravatar.cc/150?u=u4',
    ),
  ];

  static List<Group> getGroups() {
    return [
      Group(
        id: _uuid.v4(),
        name: 'Trip to Vegas',
        type: 'Trip',
        members: [currentUser, friends[0], friends[1]],
        expenses: [
          Expense(
            id: _uuid.v4(),
            description: 'Hotel Booking',
            amount: 450.00,
            date: DateTime.now().subtract(const Duration(days: 2)),
            payerId: currentUser.id,
            groupId: 'g1',
            splitDetails: {
              currentUser.id: 150,
              friends[0].id: 150,
              friends[1].id: 150,
            },
          ),
          Expense(
            id: _uuid.v4(),
            description: 'Dinner at Bellagio',
            amount: 120.00,
            date: DateTime.now().subtract(const Duration(days: 1)),
            payerId: friends[0].id,
            groupId: 'g1',
            splitDetails: {
              currentUser.id: 40,
              friends[0].id: 40,
              friends[1].id: 40,
            },
          ),
        ],
      ),
      Group(
        id: _uuid.v4(),
        name: 'Apartment 404',
        type: 'Home',
        members: [currentUser, friends[2], friends[3]],
        expenses: [
          Expense(
            id: _uuid.v4(),
            description: 'Wifi Bill',
            amount: 60.00,
            date: DateTime.now().subtract(const Duration(days: 5)),
            payerId: friends[2].id,
            groupId: 'g2',
            splitDetails: {
              currentUser.id: 20,
              friends[2].id: 20,
              friends[3].id: 20,
            },
          ),
        ],
      ),
    ];
  }
}
