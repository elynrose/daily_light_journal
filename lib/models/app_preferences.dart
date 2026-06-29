enum UserRole { ministry, musician, laity }

enum NotificationFrequency { twiceDaily, morningOnly, eveningOnly, none }

enum NotificationSource { notes, bible, both }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.ministry:
        return 'Ministry';
      case UserRole.musician:
        return 'Musician';
      case UserRole.laity:
        return 'Laity';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.laity,
    );
  }
}

extension NotificationFrequencyLabel on NotificationFrequency {
  String get label {
    switch (this) {
      case NotificationFrequency.twiceDaily:
        return 'Morning & evening';
      case NotificationFrequency.morningOnly:
        return 'Morning only';
      case NotificationFrequency.eveningOnly:
        return 'Evening only';
      case NotificationFrequency.none:
        return 'Off';
    }
  }

  static NotificationFrequency fromString(String value) {
    return NotificationFrequency.values.firstWhere(
      (item) => item.name == value,
      orElse: () => NotificationFrequency.twiceDaily,
    );
  }
}

extension NotificationSourceLabel on NotificationSource {
  String get label {
    switch (this) {
      case NotificationSource.notes:
        return 'Journal notes';
      case NotificationSource.bible:
        return 'Bible verses';
      case NotificationSource.both:
        return 'Notes & Bible';
    }
  }

  static NotificationSource fromString(String value) {
    return NotificationSource.values.firstWhere(
      (item) => item.name == value,
      orElse: () => NotificationSource.both,
    );
  }
}

class AppPreferences {
  final bool onboardingComplete;
  final UserRole userRole;
  final NotificationFrequency notificationFrequency;
  final NotificationSource notificationSource;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;
  final double bibleFontScale;
  final double notesFontScale;
  final double lyricsFontScale;
  final String sermonFeedUrl;

  const AppPreferences({
    this.onboardingComplete = false,
    this.userRole = UserRole.laity,
    this.notificationFrequency = NotificationFrequency.twiceDaily,
    this.notificationSource = NotificationSource.both,
    this.morningHour = 7,
    this.morningMinute = 0,
    this.eveningHour = 19,
    this.eveningMinute = 0,
    this.bibleFontScale = 1.0,
    this.notesFontScale = 1.0,
    this.lyricsFontScale = 1.0,
    this.sermonFeedUrl = '',
  });

  AppPreferences copyWith({
    bool? onboardingComplete,
    UserRole? userRole,
    NotificationFrequency? notificationFrequency,
    NotificationSource? notificationSource,
    int? morningHour,
    int? morningMinute,
    int? eveningHour,
    int? eveningMinute,
    double? bibleFontScale,
    double? notesFontScale,
    double? lyricsFontScale,
    String? sermonFeedUrl,
  }) {
    return AppPreferences(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      userRole: userRole ?? this.userRole,
      notificationFrequency:
          notificationFrequency ?? this.notificationFrequency,
      notificationSource: notificationSource ?? this.notificationSource,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
      eveningHour: eveningHour ?? this.eveningHour,
      eveningMinute: eveningMinute ?? this.eveningMinute,
      bibleFontScale: bibleFontScale ?? this.bibleFontScale,
      notesFontScale: notesFontScale ?? this.notesFontScale,
      lyricsFontScale: lyricsFontScale ?? this.lyricsFontScale,
      sermonFeedUrl: sermonFeedUrl ?? this.sermonFeedUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'onboardingComplete': onboardingComplete,
      'userRole': userRole.name,
      'notificationFrequency': notificationFrequency.name,
      'notificationSource': notificationSource.name,
      'morningHour': morningHour,
      'morningMinute': morningMinute,
      'eveningHour': eveningHour,
      'eveningMinute': eveningMinute,
      'bibleFontScale': bibleFontScale,
      'notesFontScale': notesFontScale,
      'lyricsFontScale': lyricsFontScale,
      'sermonFeedUrl': sermonFeedUrl,
    };
  }

  factory AppPreferences.fromMap(Map<dynamic, dynamic> map) {
    return AppPreferences(
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      userRole: UserRoleLabel.fromString(map['userRole'] as String? ?? ''),
      notificationFrequency: NotificationFrequencyLabel.fromString(
        map['notificationFrequency'] as String? ?? '',
      ),
      notificationSource: NotificationSourceLabel.fromString(
        map['notificationSource'] as String? ?? '',
      ),
      morningHour: map['morningHour'] as int? ?? 7,
      morningMinute: map['morningMinute'] as int? ?? 0,
      eveningHour: map['eveningHour'] as int? ?? 19,
      eveningMinute: map['eveningMinute'] as int? ?? 0,
      bibleFontScale: (map['bibleFontScale'] as num?)?.toDouble() ?? 1.0,
      notesFontScale: (map['notesFontScale'] as num?)?.toDouble() ?? 1.0,
      lyricsFontScale: (map['lyricsFontScale'] as num?)?.toDouble() ?? 1.0,
      sermonFeedUrl: map['sermonFeedUrl'] as String? ?? '',
    );
  }
}
