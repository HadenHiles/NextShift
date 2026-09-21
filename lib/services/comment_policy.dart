import 'package:mofilo_content_filter/mofilo_content_filter.dart';

const int maxCommentLength = 500;

final RegExp _linkPattern = RegExp(
  r'(https?://|www\.|mailto:|data:image|(?:[a-z0-9-]+\.)+(?:com|net|org|io|co|app|dev|gg|me|tv|ly|ca|uk|us)\b)',
  caseSensitive: false,
);
final RegExp _markupPattern = RegExp(r'<[^>]*>|!?\[[^\]]*\]\s*\([^)]*\)');
final RegExp _unsafeControlCharacters =
    RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

String? validateComment(String? value) {
  final comment = value?.trim() ?? '';
  if (comment.isEmpty) return 'Please write a comment';
  if (comment.length > maxCommentLength) {
    return 'Keep comments under $maxCommentLength characters';
  }
  if (_linkPattern.hasMatch(comment)) {
    return 'Links are not allowed in comments';
  }
  if (_markupPattern.hasMatch(comment)) {
    return 'HTML, images, and embedded content are not allowed';
  }
  if (_unsafeControlCharacters.hasMatch(comment)) {
    return 'This comment contains unsupported characters';
  }
  if (ContentFilter.check(comment).isBlocked) {
    return 'This comment does not meet the community guidelines';
  }
  return null;
}
