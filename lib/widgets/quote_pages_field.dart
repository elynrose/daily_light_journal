import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'linked_scripture_field.dart';

class QuotePagesField extends StatefulWidget {
  final List<String> initialPages;
  final ValueChanged<List<String>> onPagesChanged;
  final ValueChanged<String> onReferenceTap;

  const QuotePagesField({
    super.key,
    required this.initialPages,
    required this.onPagesChanged,
    required this.onReferenceTap,
  });

  @override
  State<QuotePagesField> createState() => QuotePagesFieldState();
}

class QuotePagesFieldState extends State<QuotePagesField> {
  late final PageController _pageController;
  late List<String> _pages;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _normalizePages(widget.initialPages);
    _controllers = [];
    _focusNodes = [];
    _buildControllers();
  }

  @override
  void didUpdateWidget(covariant QuotePagesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPages != widget.initialPages) {
      _disposeControllers();
      _pages = _normalizePages(widget.initialPages);
      _currentPage = 0;
      _buildControllers();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  List<String> _normalizePages(List<String> pages) {
    if (pages.isEmpty) return [''];
    return List<String>.from(pages);
  }

  void _buildControllers() {
    _controllers = _pages
        .map(
          (page) => TextEditingController(text: page)
            ..addListener(_notifyPagesChanged),
        )
        .toList();
    _focusNodes = List.generate(_pages.length, (_) => FocusNode());
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.removeListener(_notifyPagesChanged);
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _controllers = [];
    _focusNodes = [];
  }

  void _syncPagesFromControllers() {
    for (var index = 0; index < _controllers.length; index++) {
      _pages[index] = _controllers[index].text;
    }
  }

  void _notifyPagesChanged() {
    _syncPagesFromControllers();
    widget.onPagesChanged(List<String>.from(_pages));
  }

  List<String> collectPages() {
    _syncPagesFromControllers();
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

  void _addPage() {
    _syncPagesFromControllers();
    setState(() {
      _pages.add('');
      final controller = TextEditingController()
        ..addListener(_notifyPagesChanged);
      final focusNode = FocusNode();
      _controllers.add(controller);
      _focusNodes.add(focusNode);
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
    _disposeControllers();
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
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: LinkedScriptureField(
                  key: ValueKey('quote-page-$index-${_pages.length}'),
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  labelText: 'Quotes',
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
