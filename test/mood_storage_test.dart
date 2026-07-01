import 'package:church_journal/models/mood_scripture.dart';
import 'package:church_journal/services/mood_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final storage = MoodStorage.instance;

  setUp(() {
    storage.setScripturesForTest([
      const MoodScripture(
        moodName: 'Anxious',
        emoji: '😟',
        scripture: 'Philippians 4:6-7',
        scriptureText: 'Be careful for nothing.',
      ),
      const MoodScripture(
        moodName: 'Anxious',
        emoji: '😟',
        scripture: 'Matthew 6:34',
        scriptureText: 'Take therefore no thought for the morrow.',
      ),
      const MoodScripture(
        moodName: 'Thankful',
        emoji: '😊',
        scripture: 'Psalm 100:4',
        scriptureText: 'Enter into his gates with thanksgiving.',
      ),
    ]);
  });

  test('lists moods in source order', () {
    expect(storage.moods.map((mood) => mood.name).toList(),
        ['Anxious', 'Thankful']);
  });

  test('picks random scripture for mood', () {
    final scripture = storage.pickRandomForMood('Anxious');
    expect(scripture, isNotNull);
    expect(scripture!.moodName, 'Anxious');
  });

  test('finds scripture by mood and reference', () {
    final scripture =
        storage.findForMoodAndReference('Anxious', 'Matthew 6:34');
    expect(scripture?.scriptureText, contains('morrow'));
  });
}
