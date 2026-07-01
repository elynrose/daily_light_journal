class MoodProfile {
  final String title;
  final List<String> tags;
  final String message;

  const MoodProfile({
    required this.title,
    required this.tags,
    required this.message,
  });

  String get tagsLabel => tags.join(' • ');

  static const _profiles = <String, MoodProfile>{
    'Anxious': MoodProfile(
      title: 'Feeling Anxious',
      tags: ['Worried', 'Uneasy', 'Stressed'],
      message:
          'Cast your cares on Him. Take a breath, pray, and let God’s peace '
          'guard your heart and mind today.',
    ),
    'Afraid': MoodProfile(
      title: 'Feeling Afraid',
      tags: ['Fearful', 'Uncertain', 'Vulnerable'],
      message:
          'You are not alone. God is with you—be strong and courageous, and '
          'trust that He will help you through this moment.',
    ),
    'Sad': MoodProfile(
      title: 'Feeling Sad',
      tags: ['Grieving', 'Downcast', 'Heavy'],
      message:
          'The Lord is close to the brokenhearted. Your sorrow is seen, and '
          'comfort is near—joy will come again in His time.',
    ),
    'Discouraged': MoodProfile(
      title: 'Feeling Discouraged',
      tags: ['Weary', 'Weak', 'Defeated'],
      message:
          'Do not lose heart. Wait on the Lord—He renews strength for those '
          'who hope in Him. Keep going; you are not finished yet.',
    ),
    'Guilty': MoodProfile(
      title: 'Feeling Guilty',
      tags: ['Ashamed', 'Regretful', 'Burdened'],
      message:
          'If we confess our sins, He is faithful to forgive. You are not '
          'defined by your mistakes—receive His mercy and walk forward.',
    ),
    'Angry': MoodProfile(
      title: 'Feeling Angry',
      tags: ['Frustrated', 'Bitter', 'Upset'],
      message:
          'Pause before you react. Lay aside wrath, seek peace, and let God '
          'help you respond with grace instead of harm.',
    ),
    'Thankful': MoodProfile(
      title: 'Feeling Good',
      tags: ['Positive', 'Calm', 'Content'],
      message:
          'You’re feeling good! Keep enjoying the little moments that make '
          'your day great. Let’s keep this positive energy going.',
    ),
  };

  static MoodProfile forMood(String moodName) {
    return _profiles[moodName] ??
        MoodProfile(
          title: 'Feeling $moodName',
          tags: [moodName],
          message: 'God sees where you are today. Let His word meet you here.',
        );
  }
}
