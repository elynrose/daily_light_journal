import 'dart:async';

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;

/// Thrown when the on-device handwriting model could not be downloaded.
class InkModelUnavailableException implements Exception {
  const InkModelUnavailableException();

  @override
  String toString() => 'InkModelUnavailableException';
}

/// Wraps ML Kit Digital Ink Recognition so both the handwriting canvas and the
/// keyboard toggle can transcribe strokes with the same behavior.
class InkRecognitionService {
  InkRecognitionService._();

  static final InkRecognitionService instance = InkRecognitionService._();

  static const _languageCode = 'en';

  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();

  /// A single long-lived recognizer. Creating one per call and awaiting
  /// [mlkit.DigitalInkRecognizer.close] can block indefinitely, which leaves
  /// the UI spinner hanging, so we reuse one instance instead.
  mlkit.DigitalInkRecognizer? _recognizer;

  mlkit.DigitalInkRecognizer get _sharedRecognizer =>
      _recognizer ??=
          mlkit.DigitalInkRecognizer(languageCode: _languageCode);

  /// Recognizes the given [strokes] (a list of strokes, each a list of
  /// `[x, y]` points) and returns the best text candidate.
  ///
  /// Returns an empty string when there is nothing to recognize or the model
  /// produced no candidates. Throws [TimeoutException] if the download or
  /// recognition takes too long, or [InkModelUnavailableException] if the model
  /// could not be downloaded.
  Future<String> transcribe(
    List<List<List<double>>> strokes, {
    void Function()? onDownloadingModel,
  }) async {
    final ink = _buildInk(strokes);
    if (ink == null) return '';

    await _ensureModelReady(onDownloadingModel: onDownloadingModel);

    final candidates = await _sharedRecognizer
        .recognize(ink)
        .timeout(const Duration(seconds: 30));
    if (candidates.isEmpty) return '';
    return candidates.first.text;
  }

  mlkit.Ink? _buildInk(List<List<List<double>>> strokes) {
    final ink = mlkit.Ink();
    var timestamp = 0;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final points = <mlkit.StrokePoint>[];
      for (final point in stroke) {
        points.add(mlkit.StrokePoint(x: point[0], y: point[1], t: timestamp));
        timestamp += 10;
      }
      ink.strokes.add(mlkit.Stroke()..points = points);
    }
    return ink.strokes.isEmpty ? null : ink;
  }

  /// Ensures the on-device handwriting model is downloaded. The download only
  /// happens once and needs an internet connection the first time.
  Future<void> _ensureModelReady({void Function()? onDownloadingModel}) async {
    if (await _modelManager.isModelDownloaded(_languageCode)) {
      return;
    }

    onDownloadingModel?.call();

    // Allow the download over any connection (not just Wi-Fi); otherwise the
    // download job is queued and never completes on mobile data.
    final downloaded = await _modelManager
        .downloadModel(_languageCode, isWifiRequired: false)
        .timeout(const Duration(minutes: 2));
    if (!downloaded) {
      throw const InkModelUnavailableException();
    }
  }
}
