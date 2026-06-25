import '../models/bible_verse.dart';
import '../services/bible_storage.dart';
import '../utils/bible_reference_range.dart';

class BibleReferenceMatch {
  final String reference;
  final int start;
  final int end;
  final String matchedText;
  final bool isRange;

  const BibleReferenceMatch({
    required this.reference,
    required this.start,
    required this.end,
    required this.matchedText,
    this.isRange = false,
  });
}

class BibleReferenceParser {
  BibleReferenceParser._();

  static final _verseNumberPattern = RegExp(r'\d+:\d+');
  static final _rangeEndPattern = RegExp(r'\d+:\d+\s*-\s*(?:\d+:\s*)?\d+');
  static final _referenceCharPattern = RegExp(r'[A-Za-z0-9]');
  static final _rangeSuffixPattern = RegExp(r'^\s*-\s*(?:\d+:\s*)?\d+');

  static List<BibleReferenceMatch> findReferences(String text) {
    if (text.isEmpty) return const [];

    final storage = BibleStorage.instance;
    final matches = <BibleReferenceMatch>[];

    for (final match in _rangeEndPattern.allMatches(text)) {
      final resolved = _resolveRangeAt(storage, text, match.start, match.end);
      if (resolved != null) {
        matches.add(resolved);
      }
    }

    for (final match in _verseNumberPattern.allMatches(text)) {
      if (_isPartOfRange(text, match.start, match.end)) continue;

      final resolved = _resolveSingleAt(storage, text, match.start, match.end);
      if (resolved != null) {
        matches.add(resolved);
      }
    }

    return _removeOverlaps(matches);
  }

  static bool _isPartOfRange(String text, int start, int end) {
    if (_rangeSuffixPattern.hasMatch(text.substring(end))) {
      return true;
    }

    for (final rangeMatch in _rangeEndPattern.allMatches(text)) {
      if (start >= rangeMatch.start && end <= rangeMatch.end) {
        return true;
      }
    }
    return false;
  }

  static BibleReferenceMatch? _resolveRangeAt(
    BibleStorage storage,
    String text,
    int rangeStart,
    int rangeEnd,
  ) {
    var start = rangeStart;
    while (start > 0) {
      final previous = text[start - 1];
      if (previous == ' ' || _referenceCharPattern.hasMatch(previous)) {
        start--;
        continue;
      }
      break;
    }

    final slice = text.substring(start, rangeEnd);
    final resolved = _resolveRangeInSlice(storage, slice);
    if (resolved == null) return null;

    final (displayReference, matchedText) = resolved;
    final localStart = slice.indexOf(matchedText);
    if (localStart < 0) return null;

    return BibleReferenceMatch(
      reference: displayReference,
      start: start + localStart,
      end: start + localStart + matchedText.length,
      matchedText: matchedText,
      isRange: true,
    );
  }

  static BibleReferenceMatch? _resolveSingleAt(
    BibleStorage storage,
    String text,
    int verseStart,
    int verseEnd,
  ) {
    var start = verseStart;
    while (start > 0) {
      final previous = text[start - 1];
      if (previous == ' ' || _referenceCharPattern.hasMatch(previous)) {
        start--;
        continue;
      }
      break;
    }

    final slice = text.substring(start, verseEnd);
    final resolved = _resolveSingleInSlice(storage, slice);
    if (resolved == null) return null;

    final (verse, matchedText) = resolved;
    final localStart = slice.indexOf(matchedText);
    if (localStart < 0) return null;

    return BibleReferenceMatch(
      reference: verse.reference,
      start: start + localStart,
      end: start + localStart + matchedText.length,
      matchedText: matchedText,
    );
  }

  static (String, String)? _resolveRangeInSlice(
    BibleStorage storage,
    String slice,
  ) {
    final trimmed = slice.trimLeft();
    if (trimmed.isEmpty) return null;

    for (final rangeMatch in _rangeEndPattern.allMatches(trimmed)) {
      var localStart = rangeMatch.start;
      while (localStart > 0) {
        final previous = trimmed[localStart - 1];
        if (previous == ' ' || _referenceCharPattern.hasMatch(previous)) {
          localStart--;
          continue;
        }
        break;
      }

      final segment = trimmed.substring(localStart, rangeMatch.end).trim();
      final words = segment.split(RegExp(r'\s+'));
      for (var index = 0; index < words.length; index++) {
        final candidate = words.sublist(index).join(' ');
        if (!candidate.contains('-')) continue;

        final verses = storage.versesForReferenceQuery(candidate);
        if (verses.length < 2) continue;

        final parsed = parseReferenceRange(candidate);
        if (parsed != null) {
          return (parsed.displayReference, candidate);
        }
      }
    }
    return null;
  }

  static (BibleVerse, String)? _resolveSingleInSlice(
    BibleStorage storage,
    String slice,
  ) {
    final trimmed = slice.trimLeft();
    if (trimmed.isEmpty) return null;

    final words = trimmed.split(RegExp(r'\s+'));
    for (var index = 0; index < words.length; index++) {
      final candidate = words.sublist(index).join(' ');
      if (!candidate.contains(':') || candidate.contains('-')) continue;

      final verse = storage.verseForReference(candidate);
      if (verse != null) {
        return (verse, candidate);
      }
    }
    return null;
  }

  static List<BibleReferenceMatch> _removeOverlaps(
    List<BibleReferenceMatch> matches,
  ) {
    if (matches.length <= 1) return matches;

    final sorted = List<BibleReferenceMatch>.from(matches)
      ..sort((a, b) {
        final byStart = a.start.compareTo(b.start);
        if (byStart != 0) return byStart;
        return b.end.compareTo(a.end);
      });

    final kept = <BibleReferenceMatch>[];
    var lastEnd = -1;

    for (final match in sorted) {
      if (match.start < lastEnd) continue;
      kept.add(match);
      lastEnd = match.end;
    }

    return kept;
  }
}
