import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ink_recognition_service.dart';
import '../theme/app_colors.dart';
import '../utils/ink_storage.dart';
import 'handwriting_canvas.dart';
import 'linked_scripture_field.dart';

class QuotePagesField extends StatefulWidget {
  final List<String> initialPages;
  final ValueChanged<List<String>> onPagesChanged;
  final ValueChanged<String> onReferenceTap;
  final double fontScale;

  const QuotePagesField({
    super.key,
    required this.initialPages,
    required this.onPagesChanged,
    required this.onReferenceTap,
    this.fontScale = 1.0,
  });

  @override
  State<QuotePagesField> createState() => QuotePagesFieldState();
}

class QuotePagesFieldState extends State<QuotePagesField> {
  late final PageController _pageController;
  late List<String> _pages;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<List<List<List<double>>>> _strokes;
  late List<bool> _inkModes;
  late List<int> _transcribedHashes;
  int _currentPage = 0;
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _normalizePages(widget.initialPages);
    _buildState();
  }

  @override
  void didUpdateWidget(covariant QuotePagesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPages != widget.initialPages) {
      _disposeState();
      _pages = _normalizePages(widget.initialPages);
      _currentPage = 0;
      _buildState();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  List<String> _normalizePages(List<String> pages) {
    if (pages.isEmpty) return [''];
    return List<String>.from(pages);
  }

  void _buildState() {
    _controllers = [];
    _focusNodes = [];
    _strokes = [];
    _inkModes = [];
    _transcribedHashes = [];
    for (final page in _pages) {
      final data = decodeInkPage(page);
      _strokes.add(data.strokes);
      _inkModes.add(data.inkMode);
      _transcribedHashes.add(0);
      _controllers.add(
        TextEditingController(text: data.text)..addListener(_notifyPagesChanged),
      );
      _focusNodes.add(FocusNode());
    }
  }

  void _disposeState() {
    for (final controller in _controllers) {
      controller.removeListener(_notifyPagesChanged);
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _controllers = [];
    _focusNodes = [];
    _strokes = [];
    _inkModes = [];
    _transcribedHashes = [];
  }

  String _composePage(int index) => encodeInkPage(
        strokes: _strokes[index],
        text: _controllers[index].text,
        inkMode: _inkModes[index],
      );

  void _syncPages() {
    for (var index = 0; index < _pages.length; index++) {
      _pages[index] = _composePage(index);
    }
  }

  void _notifyPagesChanged() {
    _syncPages();
    widget.onPagesChanged(List<String>.from(_pages));
  }

  void _onInkChanged(int index, String inkValue) {
    _strokes[index] = decodeInkStrokes(inkValue);
    _syncPages();
    widget.onPagesChanged(List<String>.from(_pages));
  }

  int _strokesHash(List<List<List<double>>> strokes) =>
      encodeInkStrokes(strokes).hashCode;

  Future<void> _toggleInkMode(int index) async {
    if (_transcribing) return;

    // Keyboard -> stylus: just show the sketch, keeping both text and strokes.
    if (!_inkModes[index]) {
      setState(() => _inkModes[index] = true);
      _notifyPagesChanged();
      return;
    }

    // Stylus -> keyboard: transcribe the sketch (once per drawing) into the
    // text, but never discard the strokes or the existing text.
    final strokes = _strokes[index];
    final hash = _strokesHash(strokes);
    final needsTranscription =
        strokes.isNotEmpty && hash != _transcribedHashes[index];

    if (needsTranscription) {
      setState(() => _transcribing = true);
      String? recognized;
      try {
        recognized = await InkRecognitionService.instance.transcribe(
          strokes,
          onDownloadingModel: () => _showSnack(
            'Downloading handwriting model (one-time, needs internet)…',
          ),
        );
      } on TimeoutException {
        _showSnack(
          'Handwriting recognition timed out. Check your internet '
          'connection and try again.',
        );
      } on InkModelUnavailableException {
        _showSnack(
          'Could not download the handwriting model. Connect to the '
          'internet and try again.',
        );
      } catch (error) {
        _showSnack('Could not recognize handwriting: $error');
      } finally {
        if (mounted) setState(() => _transcribing = false);
      }

      if (!mounted) return;
      if (recognized == null) {
        // Recognition failed; stay in stylus mode so nothing is lost.
        return;
      }

      final text = recognized.trim();
      if (text.isNotEmpty) {
        final current = _controllers[index].text.trim();
        _controllers[index].text =
            current.isEmpty ? text : '$current\n$text';
      }
      _transcribedHashes[index] = hash;
    }

    setState(() => _inkModes[index] = false);
    _notifyPagesChanged();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> collectPages() {
    _syncPages();
    return List<String>.from(_pages);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _deletePage() async {
    if (_pages.length <= 1) return;

    _syncPages();
    final index = _currentPage;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete page?'),
        content: Text(
          'Delete page ${index + 1} of ${_pages.length}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _controllers[index].removeListener(_notifyPagesChanged);
      _controllers[index].dispose();
      _focusNodes[index].dispose();

      _pages.removeAt(index);
      _controllers.removeAt(index);
      _focusNodes.removeAt(index);
      _strokes.removeAt(index);
      _inkModes.removeAt(index);
      _transcribedHashes.removeAt(index);

      if (_currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
      }
    });

    widget.onPagesChanged(List<String>.from(_pages));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_currentPage);
    });
  }

  void _addPage() {
    _syncPages();
    setState(() {
      _pages.add('');
      _controllers.add(TextEditingController()..addListener(_notifyPagesChanged));
      _focusNodes.add(FocusNode());
      _strokes.add(<List<List<double>>>[]);
      _inkModes.add(false);
      _transcribedHashes.add(0);
      _currentPage = _pages.length - 1;
    });
    widget.onPagesChanged(List<String>.from(_pages));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      _focusNodes[_currentPage].requestFocus();
    });
  }

  @override
  void dispose() {
    _disposeState();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            physics: _inkModes[_currentPage]
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (_inkModes[index]) {
                return HandwritingCanvas(
                  key: ValueKey('ink-page-$index'),
                  initialValue: encodeInkStrokes(_strokes[index]),
                  fontScale: widget.fontScale,
                  onChanged: (value) => _onInkChanged(index, value),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: LinkedScriptureField(
                  key: ValueKey('quote-page-$index-${_pages.length}'),
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  labelText: 'Notes',
                  fontScale: widget.fontScale,
                  onReferenceTap: widget.onReferenceTap,
                ),
              );
            },
          ),
        ),
        const Divider(
          height: AppColors.borderWidth,
          thickness: AppColors.borderWidth,
          color: AppColors.border,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Previous page',
                icon: const Icon(Icons.chevron_left, color: AppColors.text),
              ),
              IconButton(
                onPressed:
                    _transcribing ? null : () => _toggleInkMode(_currentPage),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: _inkModes[_currentPage]
                    ? 'Switch to keyboard (transcribe handwriting)'
                    : 'Switch to stylus',
                icon: _transcribing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _inkModes[_currentPage] ? Icons.keyboard : Icons.draw,
                        color: AppColors.text,
                      ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    final isActive = index == _currentPage;
                    return GestureDetector(
                      onTap: () => _goToPage(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 10 : 8,
                        height: isActive ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.text
                              : AppColors.text.withValues(alpha: 0.35),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Text(
                '${_currentPage + 1} / ${_pages.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              IconButton(
                onPressed: _currentPage < _pages.length - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right, color: AppColors.text),
              ),
              IconButton(
                onPressed: _pages.length > 1 ? _deletePage : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Delete page',
                icon: const Icon(Icons.delete_outline, color: AppColors.text),
              ),
              IconButton(
                onPressed: _addPage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Add page',
                icon: const Icon(Icons.add, color: AppColors.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
