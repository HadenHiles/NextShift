import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
import 'package:nextshift/globals/Roles.dart';
import 'package:nextshift/models/Item.dart';
import 'package:nextshift/models/RequestType.dart';
import 'package:nextshift/services/voting.dart';
import 'package:nextshift/widgets/PlatformBadge.dart';
import 'package:nextshift/widgets/VoteButton.dart';
import '../Login.dart';

class ListItem extends StatefulWidget {
  const ListItem({super.key, required this.item, required this.filterBy, this.rank});

  final Item item;
  final void Function(RequestType?, String?) filterBy;
  final int? rank;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  User? get user => FirebaseAuth.instance.currentUser;
  bool get isAdmin => Roles.admins.contains(user?.uid);

  @override
  Widget build(BuildContext context) {
    final hasVoted = user != null ? widget.item.voters.contains(user!.uid) : false;
    final hasDownvoted = user != null ? widget.item.downvoters.contains(user!.uid) : false;
    final status = widget.item.complete
        ? ('Completed', const Color(0xFF45B978), Icons.check_circle)
        : widget.item.upNext
            ? ("Coach's next shift", const Color(0xFFE55353), Icons.bolt)
            : ('Open', const Color(0xFF8A94A3), Icons.radio_button_unchecked);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFF292E35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openDetails,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: status.$2),
              SizedBox(
                width: 72,
                child: Center(
                  child: Text(
                    widget.rank == null ? '—' : widget.rank!.toString().padLeft(2, '0'),
                    style: const TextStyle(color: Color(0xFF59616D), fontSize: 30, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 16), color: const Color(0xFF292E35)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.15),
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
                          if (isAdmin)
                            ActionChip(
                              avatar: Icon(widget.item.type.icon, size: 18, color: widget.item.type.color),
                              label: Text(widget.item.type.descriptor),
                              onPressed: () => widget.filterBy(widget.item.type, null),
                            )
                          else
                            _TypeLabel(type: widget.item.type),
                          PlatformBadge(
                            platform: widget.item.platform,
                            onTap: () => widget.filterBy(null, widget.item.platform),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 84,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    VoteButton(
                      isUpvote: true,
                      selected: hasVoted,
                      tooltip: hasVoted ? 'Remove upvote' : 'Upvote this next shift',
                      onPressed: () => _vote(VoteDirection.up),
                    ),
                    Text('${widget.item.votes}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const Text('SCORE', style: TextStyle(fontSize: 12, color: Color(0xFFB4BDC9), fontWeight: FontWeight.w600)),
                    VoteButton(
                      isUpvote: false,
                      selected: hasDownvoted,
                      tooltip: hasDownvoted ? 'Remove downvote' : 'Downvote this next shift',
                      onPressed: () => _vote(VoteDirection.down),
                    ),
                  ],
                ),
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

  Future<void> _vote(VoteDirection direction) async {
    final currentUser = user;
    if (currentUser == null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Login()));
      return;
    }

    await setVote(widget.item.reference, currentUser.uid, direction);
  }

  Future<void> _toggleComplete() => _updateFlag('complete', !widget.item.complete);

  Future<void> _toggleUpNext() => _updateFlag('up_next', !widget.item.upNext);

  Future<void> _updateFlag(String field, bool value) {
    return widget.item.reference.update({field: value});
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});

  final RequestType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(type.icon, size: 18, color: type.color),
        const SizedBox(width: 6),
        Text(type.descriptor, style: const TextStyle(fontSize: 14)),
      ],
    );
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
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
