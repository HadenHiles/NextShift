import 'package:cloud_firestore/cloud_firestore.dart';

enum VoteDirection { up, down }

class VoteUpdate {
  const VoteUpdate({
    required this.score,
    required this.upvoters,
    required this.downvoters,
  });

  final int score;
  final List<dynamic> upvoters;
  final List<dynamic> downvoters;
}

VoteUpdate calculateVote({
  required int score,
  required List<dynamic> upvoters,
  required List<dynamic> downvoters,
  required String userId,
  required VoteDirection direction,
}) {
  final nextUpvoters = List<dynamic>.from(upvoters);
  final nextDownvoters = List<dynamic>.from(downvoters);
  final hadUpvote = nextUpvoters.remove(userId);
  final hadDownvote = nextDownvoters.remove(userId);
  late int change;

  if (direction == VoteDirection.up) {
    if (hadUpvote) {
      change = -1;
    } else {
      nextUpvoters.add(userId);
      change = hadDownvote ? 2 : 1;
    }
  } else if (hadDownvote) {
    change = 1;
  } else {
    nextDownvoters.add(userId);
    change = hadUpvote ? -2 : -1;
  }

  return VoteUpdate(
    score: score + change,
    upvoters: nextUpvoters,
    downvoters: nextDownvoters,
  );
}

Future<void> setVote(
  DocumentReference reference,
  String userId,
  VoteDirection direction,
) {
  return FirebaseFirestore.instance.runTransaction((transaction) async {
    final snapshot = await transaction.get(reference);
    final data = snapshot.data()! as Map<String, dynamic>;
    final upvoters = List<dynamic>.from(data['voters'] ?? const []);
    final downvoters = List<dynamic>.from(data['downvoters'] ?? const []);
    final score = data['votes'] as int? ?? 0;
    final update = calculateVote(
      score: score,
      upvoters: upvoters,
      downvoters: downvoters,
      userId: userId,
      direction: direction,
    );

    transaction.update(reference, {
      'votes': update.score,
      'voters': update.upvoters,
      'downvoters': update.downvoters,
    });
  });
}
