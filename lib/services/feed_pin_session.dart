class FeedPinSession {
  FeedPinSession._();

  static final FeedPinSession instance = FeedPinSession._();

  final Map<String, String> _verifiedPinsByFeedUrl = {};

  bool isVerified(String feedUrl, String requiredPin) {
    return _verifiedPinsByFeedUrl[feedUrl.trim()] == requiredPin;
  }

  void markVerified(String feedUrl, String pin) {
    _verifiedPinsByFeedUrl[feedUrl.trim()] = pin;
  }

  void clearForFeed(String feedUrl) {
    _verifiedPinsByFeedUrl.remove(feedUrl.trim());
  }

  void clearAll() {
    _verifiedPinsByFeedUrl.clear();
  }
}
