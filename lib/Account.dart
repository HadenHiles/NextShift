import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/Home.dart';
import 'package:nextshift/RequestDetail.dart';
import 'package:nextshift/auth.dart' as app_auth;
import 'package:nextshift/models/Comment.dart';
import 'package:nextshift/models/Item.dart';
import 'package:nextshift/widgets/PlatformBadge.dart';
import 'package:timeago/timeago.dart' as timeago;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? get user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const Home();
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MY ACCOUNT'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
              Tab(icon: Icon(Icons.sports_hockey), text: 'My shifts'),
              Tab(icon: Icon(Icons.notifications_none), text: 'Activity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(
              user: currentUser,
              onNameChanged: _changeDisplayName,
              onEmailChanged: _changeEmail,
              onPasswordReset: _sendPasswordReset,
              onLogout: _logout,
            ),
            _SubmissionsTab(userId: currentUser.uid),
            _ActivityTab(userId: currentUser.uid),
          ],
        ),
      ),
    );
  }

  Future<void> _changeDisplayName() async {
    final controller = TextEditingController(text: user?.displayName ?? '');
    final name = await _showTextDialog(
      title: 'Change display name',
      label: 'Display name',
      controller: controller,
      keyboardType: TextInputType.name,
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;

    await _runAccountAction(
      () async {
        await user!.updateDisplayName(name.trim());
        await user!.reload();
        if (mounted) setState(() {});
      },
      'Display name updated.',
    );
  }

  Future<void> _changeEmail() async {
    final controller = TextEditingController(text: user?.email ?? '');
    final email = await _showTextDialog(
      title: 'Change email address',
      label: 'New email address',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      message: 'We will send a verification link to the new address before it changes.',
    );
    controller.dispose();
    if (email == null || email.trim() == user?.email) return;

    await _runAccountAction(
      () => user!.verifyBeforeUpdateEmail(email.trim()),
      'Check your new email address to confirm the change.',
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = user?.email;
    if (email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password?'),
        content: Text('Send a secure password reset link to $email?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send link')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAccountAction(
      () => FirebaseAuth.instance.sendPasswordResetEmail(email: email),
      'Password reset email sent.',
    );
  }

  Future<void> _logout() async {
    await app_auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  Future<String?> _showTextDialog({
    required String title,
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    String? message,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(message),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: InputDecoration(labelText: label),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Continue')),
        ],
      ),
    );
  }

  Future<void> _runAccountAction(Future<void> Function() action, String successMessage) async {
    try {
      await action();
      if (mounted) _showMessage(successMessage);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      final message = switch (error.code) {
        'requires-recent-login' => 'For security, sign out and sign in again before making this change.',
        'email-already-in-use' => 'That email address is already in use.',
        'invalid-email' => 'Enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please wait and try again.',
        _ => 'The account change could not be completed. Please try again.',
      };
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.user,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPasswordReset,
    required this.onLogout,
  });

  final User user;
  final VoidCallback onNameChanged;
  final VoidCallback onEmailChanged;
  final VoidCallback onPasswordReset;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final providerNames = user.providerData
        .map((provider) => switch (provider.providerId) {
              'google.com' => 'Google',
              'facebook.com' => 'Facebook',
              'password' => 'Email and password',
              _ => provider.providerId,
            })
        .toSet()
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: user.photoURL == null ? null : NetworkImage(user.photoURL!),
                      child: user.photoURL == null ? const Icon(Icons.person, size: 34) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName?.isNotEmpty == true ? user.displayName! : 'Hockey fan', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(user.email ?? 'No email address', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('PROFILE', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _AccountAction(icon: Icons.badge_outlined, title: 'Display name', subtitle: 'Shown beside new comments', onTap: onNameChanged),
                _AccountAction(icon: Icons.email_outlined, title: 'Email address', subtitle: user.email ?? 'No email address', onTap: onEmailChanged),
                const SizedBox(height: 24),
                Text('SECURITY', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _AccountAction(
                  icon: Icons.lock_reset,
                  title: 'Password',
                  subtitle: user.email == null ? 'No email address is available' : 'Send a secure password reset email',
                  onTap: user.email == null ? null : onPasswordReset,
                ),
                _AccountAction(icon: Icons.verified_user_outlined, title: 'Sign-in method', subtitle: providerNames.isEmpty ? 'Email link' : providerNames),
                const SizedBox(height: 28),
                OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout), label: const Text('LOG OUT')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SubmissionsTab extends StatelessWidget {
  const _SubmissionsTab({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('items').where('created_by', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const _AccountEmpty(icon: Icons.error_outline, title: 'Submissions could not be loaded');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final items = snapshot.data!.docs.map(Item.fromSnapshot).toList()
          ..sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
        if (items.isEmpty) return const _AccountEmpty(icon: Icons.sports_hockey, title: 'No next shifts yet', message: 'Your submissions will appear here.');

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _SubmissionTile(item: items[index]),
        );
      },
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final status = item.complete
        ? 'Completed'
        : item.upNext
            ? "Coach's next shift"
            : 'Open';
    final date = item.createdAt == null ? 'Earlier submission' : timeago.format(item.createdAt!.toDate());

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(item.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlatformBadge(platform: item.platform),
              Text(status),
              Text(date),
              Text('${item.votes} score'),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetail(item: item))),
      ),
    );
  }
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab({required this.userId});

  final String userId;

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  late Future<List<_PostActivity>> _activity;

  @override
  void initState() {
    super.initState();
    _activity = _loadActivity();
  }

  Future<List<_PostActivity>> _loadActivity() async {
    final itemSnapshot = await FirebaseFirestore.instance.collection('items').where('created_by', isEqualTo: widget.userId).get();
    final items = itemSnapshot.docs.map(Item.fromSnapshot).toList();
    final batches = await Future.wait(
      items.map((item) async {
        final comments = await FirebaseFirestore.instance.collection('comments').doc(item.reference.id).collection('comments').orderBy('timestamp', descending: true).limit(20).get();
        return comments.docs.map((document) => _PostActivity(item: item, comment: Comment.fromSnapshot(document))).toList();
      }),
    );
    final activity = batches.expand((batch) => batch).toList()..sort((a, b) => b.comment.timestamp.compareTo(a.comment.timestamp));
    return activity.take(50).toList();
  }

  void _refresh() {
    setState(() => _activity = _loadActivity());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_PostActivity>>(
      future: _activity,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AccountEmpty(icon: Icons.error_outline, title: 'Activity could not be loaded', action: TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Try again')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return _AccountEmpty(icon: Icons.notifications_none, title: 'No activity yet', message: 'Comments on your next shifts will appear here.', action: TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')));

        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final activity = snapshot.data![index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                leading: CircleAvatar(
                  backgroundImage: activity.comment.avatarUrl == null ? null : NetworkImage(activity.comment.avatarUrl!),
                  child: activity.comment.avatarUrl == null ? const Icon(Icons.person_outline) : null,
                ),
                title: Text(activity.comment.comment, maxLines: 3, overflow: TextOverflow.ellipsis),
                subtitle: Text('${activity.comment.displayName} on “${activity.item.name}” · ${timeago.format(activity.comment.timestamp.toDate())}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetail(item: activity.item))),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostActivity {
  const _PostActivity({required this.item, required this.comment});

  final Item item;
  final Comment comment;
}

class _AccountEmpty extends StatelessWidget {
  const _AccountEmpty({required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFFB4BDC9)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
