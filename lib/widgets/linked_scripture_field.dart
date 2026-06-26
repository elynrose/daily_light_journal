import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/bible_reference_parser.dart';

class LinkedScriptureField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final ValueChanged<String> onReferenceTap;
  final double fontScale;

  const LinkedScriptureField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.onReferenceTap,
    this.fontScale = 1.0,
  });

  @override
  State<LinkedScriptureField> createState() => _LinkedScriptureFieldState();
}

class _LinkedScriptureFieldState extends State<LinkedScriptureField> {
  bool _isEditing = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.controller.text.isEmpty;
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant LinkedScriptureField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.controller.text.isEmpty) {
      _isEditing = true;
    }
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus &&
        widget.controller.text.trim().isNotEmpty) {
      setState(() {
        _isEditing = false;
      });
      return;
    }
    if (mounted) setState(() {});
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    widget.focusNode.requestFocus();
  }

  bool get _showTextField => _isEditing || widget.controller.text.isEmpty;

  TextSpan _buildLinkedSpan(String text) {
    final bodySize = 16 * widget.fontScale;
    final references = BibleReferenceParser.findReferences(text);
    if (references.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(fontSize: bodySize, color: AppColors.text, height: 1.45),
      );
    }

    final bodyStyle = TextStyle(
      fontSize: bodySize,
      color: AppColors.text,
      height: 1.45,
    );
    final linkStyle = TextStyle(
      fontSize: bodySize,
      color: AppColors.text,
      height: 1.45,
      fontWeight: FontWeight.bold,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final reference in references) {
      if (reference.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, reference.start),
            style: bodyStyle,
          ),
        );
      }

      final matchedText = text.substring(reference.start, reference.end);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => widget.onReferenceTap(reference.reference),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 13,
                  color: AppColors.text,
                ),
                const SizedBox(width: 3),
                Text(
                  matchedText,
                  style: linkStyle,
                ),
              ],
            ),
          ),
        ),
      );
      cursor = reference.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: bodyStyle,
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              widget.labelText,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 16 * widget.fontScale,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _startEditing,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              tooltip: 'Edit',
              icon: const Icon(
                Icons.edit,
                color: AppColors.text,
                size: 20,
              ),
            ),
          ],
        ),
        Expanded(
          child: _showTextField
              ? TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  readOnly: !_isEditing,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: 16 * widget.fontScale,
                    color: AppColors.text,
                  ),
                  onSubmitted: (_) => widget.focusNode.unfocus(),
                )
              : SingleChildScrollView(
                  child: Text.rich(
                    _buildLinkedSpan(text),
                    textAlign: TextAlign.left,
                  ),
                ),
        ),
      ],
    );
  }
}
