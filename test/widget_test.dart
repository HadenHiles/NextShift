// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nextshift/widgets/Heading.dart';
import 'package:nextshift/widgets/PlatformBadge.dart';
import 'package:nextshift/widgets/VoteButton.dart';
import 'package:nextshift/services/comment_policy.dart';
import 'package:nextshift/services/voting.dart';

void main() {
  testWidgets('Heading renders uppercase text at the requested size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Heading(text: 'Next Shift', size: 30),
      ),
    );

    final text = tester.widget<Text>(find.text('NEXT SHIFT'));
    expect(text.style?.fontSize, 30);
  });

  testWidgets('Platform badge identifies the 10,000 Shots App', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlatformBadge(platform: '10,000 Shots App'),
        ),
      ),
    );

    expect(find.text('10K SHOTS'), findsOneWidget);
    expect(find.byIcon(Icons.track_changes), findsOneWidget);
  });

  testWidgets('Vote buttons use plain icons and color only the selected vote', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              VoteButton(
                isUpvote: true,
                selected: false,
                tooltip: 'Upvote',
                onPressed: () {},
              ),
              VoteButton(
                isUpvote: false,
                selected: true,
                tooltip: 'Downvote',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final upIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    final downIcon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
    final buttons = tester.widgetList<IconButton>(find.byType(IconButton)).toList();

    expect(upIcon.color, const Color(0xFFB4BDC9));
    expect(downIcon.color, const Color(0xFFFF7373));
    for (final button in buttons) {
      expect(button.style?.backgroundColor, isNull);
      expect(button.style?.side, isNull);
    }
  });

  test('comment policy allows useful plain text', () {
    expect(validateComment('Please add a video about backward crossovers.'), isNull);
  });

  test('comment policy blocks links and embedded content', () {
    expect(validateComment('Visit https://example.com'), contains('Links'));
    expect(validateComment('<img src="bad">'), contains('HTML'));
    expect(validateComment('![photo](image.png)'), contains('HTML'));
  });

  test('comment policy blocks harmful content', () {
    expect(validateComment('kill yourself'), contains('community guidelines'));
  });

  test('vote calculation adds and removes a downvote', () {
    final added = calculateVote(
      score: 3,
      upvoters: const [],
      downvoters: const [],
      userId: 'player',
      direction: VoteDirection.down,
    );
    expect(added.score, 2);
    expect(added.downvoters, ['player']);

    final removed = calculateVote(
      score: added.score,
      upvoters: added.upvoters,
      downvoters: added.downvoters,
      userId: 'player',
      direction: VoteDirection.down,
    );
    expect(removed.score, 3);
    expect(removed.downvoters, isEmpty);
  });

  test('switching vote direction changes the score by two', () {
    final update = calculateVote(
      score: 3,
      upvoters: const ['player'],
      downvoters: const [],
      userId: 'player',
      direction: VoteDirection.down,
    );

    expect(update.score, 1);
    expect(update.upvoters, isEmpty);
    expect(update.downvoters, ['player']);
  });
}
