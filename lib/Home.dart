import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextshift/Request.dart';
import 'package:nextshift/models/RequestType.dart';
import 'models/Item.dart';
import 'widgets/ListItem.dart';
import 'Login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final user = FirebaseAuth.instance.currentUser;

  RequestType? typeFilter;
  String? platformFilter;
  bool showCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logos/hth_logo_red.png',
              height: 36,
            ),
            const SizedBox(width: 12),
            const Text(
              'NEXT SHIFT',
              style: TextStyle(
                fontFamily: 'Teko',
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: user == null ? 'Sign in' : 'Account',
            onPressed: user == null
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Login()),
                    )
                : null,
            icon: Icon(user == null ? Icons.login : Icons.account_circle),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntro(),
                  const SizedBox(height: 24),
                  _buildFilters(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildItems(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2F36))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should Coach Jeremy do next?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vote on the ideas that matter most, request new hockey content, or report an issue with one of our products.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFADB5C0),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _showRequestMenu,
            icon: const Icon(Icons.add),
            label: const Text('Suggest the next shift'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const platforms = ['The Pond', 'How To Hockey', '10,000 Shots App'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Text(
              showCompleted ? 'Completed shifts' : 'Community priorities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            );
            final statusControl = SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Open')),
                ButtonSegment(value: true, label: Text('Done')),
              ],
              selected: {showCompleted},
              onSelectionChanged: (value) => setState(() => showCompleted = value.first),
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const SizedBox(height: 12), statusControl],
              );
            }

            return Row(
              children: [Expanded(child: heading), statusControl],
            );
          },
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All products'),
              selected: platformFilter == null,
              onSelected: (_) => setState(() => platformFilter = null),
            ),
            ...platforms.map(
              (platform) => ChoiceChip(
                label: Text(platform),
                selected: platformFilter == platform,
                onSelected: (_) => setState(() => platformFilter = platform),
              ),
            ),
          ],
        ),
        if (typeFilter != null) ...[
          const SizedBox(height: 10),
          InputChip(
            avatar: Icon(typeFilter!.icon, size: 18),
            label: Text(typeFilter!.descriptor),
            onDeleted: () => setState(() => typeFilter = null),
          ),
        ],
      ],
    );
  }

  // Build the list of items
  Widget _buildItems(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').orderBy('votes', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('We could not load community ideas right now.'));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return _buildItemList(context, snapshot.data!.docs);
        });
  }

  Widget _buildItemList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<ListItem> items = snapshot
        .map((data) => ListItem(
              item: Item.fromSnapshot(data),
              filterBy: filterBy,
            ))
        .toList();

    // Put the items that are up next first
    items = items.where((element) => element.item.upNext).toList() + items.where((e) => !e.item.upNext).toList();

    items = items.where((element) => element.item.complete == showCompleted).toList();

    if (typeFilter != null) {
      items = items.where((element) => element.item.type.name == typeFilter!.name).toList();
    }

    if (platformFilter != null) {
      items = items.where((element) => element.item.platform == platformFilter).toList();
    }

    return items.isNotEmpty
        ? ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => items[index],
          )
        : Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 38, color: Color(0xFF737C89)),
                const SizedBox(height: 12),
                Text(
                  'No matching shifts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text('Try another product or clear your filters.'),
                TextButton(
                  onPressed: () => setState(() {
                    showCompleted = false;
                    typeFilter = null;
                    platformFilter = null;
                  }),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          );
  }

  Future<void> _showRequestMenu() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('What should the next shift be?', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _requestOption('Content Request', Icons.movie, 'Suggest a video, drill, or lesson'),
              _requestOption('Feature Request', Icons.list_alt, 'Improve one of our products'),
              _requestOption('Idea', Icons.lightbulb, 'Share another way we can help'),
              _requestOption('Bug', Icons.bug_report, 'Report something that is broken'),
            ],
          ),
        ),
      ),
    );

    if (selection != null && mounted) newRequest(selection);
  }

  Widget _requestOption(String type, IconData icon, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(type),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).pop(type),
    );
  }

  void newRequest(String type) {
    if (user == null) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Login();
            },
          ),
        );
      });
    } else {
      RequestType requestType = RequestType(name: type);

      if (type == "Bug") {
        requestType.color = Theme.of(context).colorScheme.secondary;
        requestType.descriptor = "Report a bug";
        requestType.icon = Icons.bug_report;
      } else if (type == "Idea") {
        requestType.color = Colors.orange;
        requestType.descriptor = "I have an idea";
        requestType.icon = Icons.lightbulb;
      } else if (type == "Content Request") {
        requestType.color = Colors.green;
        requestType.descriptor = "I would like to learn about..";
        requestType.icon = Icons.movie;
      } else if (type == "Feature Request") {
        requestType.color = Colors.blue;
        requestType.descriptor = "I would like to be able to..";
        requestType.icon = Icons.list_alt;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Request(type: requestType);
          },
        ),
      );
    }
  }

  void filterBy(RequestType? type, String? platform) {
    setState(() {
      if (type != null) typeFilter = type;
      if (platform != null) platformFilter = platform;
    });
  }

  bool includeType(RequestType? type) {
    return type == null || type.name == typeFilter?.name;
  }
}
