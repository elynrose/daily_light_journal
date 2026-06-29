import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Future<String?> showFeedPinDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _FeedPinDialog(),
  );
}

class _FeedPinDialog extends StatefulWidget {
  const _FeedPinDialog();

  @override
  State<_FeedPinDialog> createState() => _FeedPinDialogState();
}

class _FeedPinDialogState extends State<_FeedPinDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _errorText = 'Enter the feed PIN');
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feed PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter the PIN for this sermon feed to play audio.',
            style: TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _errorText,
              border: AppColors.outlineInputBorder,
              enabledBorder: AppColors.outlineInputBorder,
              focusedBorder: AppColors.outlineInputBorder,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
