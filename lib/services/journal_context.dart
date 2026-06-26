import 'package:flutter/foundation.dart';

import '../models/entry.dart';
import 'entry_storage.dart';

/// Tracks the journal date/period used when adding from Songs or Bible tabs.
class JournalContext extends ChangeNotifier {
  JournalContext._();

  static final JournalContext instance = JournalContext._();

  DateTime _date = EntryStorage.normalizeDate(DateTime.now());
  ServicePeriod _period = servicePeriodFromTime(DateTime.now());

  DateTime get date => _date;
  ServicePeriod get period => _period;

  void update({
    required DateTime date,
    required ServicePeriod period,
  }) {
    final normalizedDate = EntryStorage.normalizeDate(date);
    if (EntryStorage.isSameDate(normalizedDate, _date) && period == _period) {
      return;
    }
    _date = normalizedDate;
    _period = period;
    notifyListeners();
  }
}
