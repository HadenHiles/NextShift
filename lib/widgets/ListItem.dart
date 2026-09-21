import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
import 'package:nextshift/globals/Roles.dart';
import 'package:nextshift/models/Item.dart';
import 'package:nextshift/models/RequestType.dart';
import 'package:nextshift/widgets/PlatformBadge.dart';
import '../Login.dart';

class ListItem extends StatefulWidget {
  const ListItem({super.key, required this.item, required this.filterBy});

  final Item item;
  final void Function(RequestType?, String?) filterBy;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  User? get user => FirebaseAuth.instance.currentUser;
  bool get isAdmin => Roles.admins.contains(user?.uid);

  @override
  Widget build(BuildContext context) {
    final hasVoted = user != null ? widget.item.voters.contains(user!.uid) : false;
    final status = widget.item.complete
        ? ('Completed', const Color(0xFF45B978), Icons.check_circle)
        : widget.item.upNext
            ? ("Coach's next shift", const Color(0xFFE55353), Icons.bolt)
            : ('Open', const Color(0xFF8A94A3), Icons.radio_button_unchecked);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF292E35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    IconButton(
                      tooltip: hasVoted ? 'Remove vote' : 'Vote for this',
                      onPressed: _toggleVote,
                      icon: Icon(
                        hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: hasVoted ? Theme.of(context).colorScheme.secondary : const Color(0xFF9AA3AF),
                      ),
                    ),
                    Text(
                      '${widget.item.votes}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Text('votes', style: TextStyle(fontSize: 11, color: Color(0xFF8A94A3))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.25),
                          ),
                        ),
                        if (isAdmin)
                          PopupMenuButton<String>(
                            tooltip: 'Manage request',
                            onSelected: (action) => action == 'status' ? _toggleComplete() : _toggleUpNext(),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'next', child: Text(widget.item.upNext ? 'Remove from next shift' : 'Mark as next shift')),
                              PopupMenuItem(value: 'status', child: Text(widget.item.complete ? 'Reopen request' : 'Mark completed')),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusBadge(label: status.$1, color: status.$2, icon: status.$3),
                        ActionChip(
                          avatar: Icon(widget.item.type.icon, size: 17, color: widget.item.type.color),
                          label: Text(widget.item.type.name),
                          onPressed: () => widget.filterBy(widget.item.type, null),
                        ),
                        PlatformBadge(
                          platform: widget.item.platform,
                          onTap: () => widget.filterBy(null, widget.item.platform),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.chevron_right, color: Color(0xFF737C89)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RequestDetail(item: widget.item)),
    );
  }

  Future<void> _toggleVote() async {
    final currentUser = user;
    if (currentUser == null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Login()));
      return;
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(widget.item.reference);
      final fresh = Item.fromSnapshot(snapshot);
      final voters = List<dynamic>.from(fresh.voters);
      final hasVoted = voters.remove(currentUser.uid);
      if (!hasVoted) voters.add(currentUser.uid);

      transaction.update(widget.item.reference, {
        'votes': fresh.votes + (hasVoted ? -1 : 1),
        'voters': voters,
      });
    });
  }

  Future<void> _toggleComplete() => _updateFlag('complete', !widget.item.complete);

  Future<void> _toggleUpNext() => _updateFlag('up_next', !widget.item.upNext);

  Future<void> _updateFlag(String field, bool value) {
    return widget.item.reference.update({field: value});
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
