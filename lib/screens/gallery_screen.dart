import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/entry.dart';
import '../models/journal_photo.dart';
import '../services/journal_context.dart';
import '../services/photo_storage.dart';
import '../theme/app_colors.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PhotoStorage _storage = PhotoStorage.instance;
  List<JournalPhoto> _photos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    setState(() {
      _photos = _storage.getAllPhotos();
    });
  }

  Future<void> _capturePhoto() async {
    await _addPhoto(_storage.captureFromCamera);
  }

  Future<void> _pickFromGallery() async {
    await _addPhoto(_storage.pickFromGallery);
  }

  Future<void> _addPhoto(
    Future<JournalPhoto?> Function({
      DateTime? journalDate,
      ServicePeriod? journalPeriod,
    }) add,
  ) async {
    setState(() => _isLoading = true);
    try {
      final journal = JournalContext.instance;
      final photo = await add(
        journalDate: journal.date,
        journalPeriod: journal.period,
      );
      if (!mounted) return;
      if (photo != null) {
        _loadPhotos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to gallery')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPhoto(JournalPhoto photo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailScreen(
          photo: photo,
          onDeleted: () {
            _loadPhotos();
          },
        ),
      ),
    );
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.creamyYellow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildActions(),
            const Divider(
              height: AppColors.borderWidth,
              thickness: AppColors.borderWidth,
              color: AppColors.border,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Photo Gallery',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _capturePhoto,
              icon: const Icon(Icons.camera_alt, color: AppColors.text),
              label: const Text(
                'Take Photo',
                style: TextStyle(color: AppColors.text),
              ),
              style: OutlinedButton.styleFrom(
                side: AppColors.borderSide,
                backgroundColor: AppColors.offWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library, color: AppColors.text),
              label: const Text(
                'Browse',
                style: TextStyle(color: AppColors.text),
              ),
              style: OutlinedButton.styleFrom(
                side: AppColors.borderSide,
                backgroundColor: AppColors.offWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _photos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No photos yet.\nCapture a moment or add one from your device.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final file = _storage.getPhotoFile(photo);
        return InkWell(
          onTap: () => _openPhoto(photo),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(AppColors.borderSide),
              color: AppColors.offWhite,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file != null)
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _missingImage(),
                  )
                else
                  _missingImage(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      _formatShortDate(photo.capturedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _missingImage() {
    return const Center(
      child: Icon(Icons.broken_image, color: AppColors.text),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _PhotoDetailScreen extends StatelessWidget {
  final JournalPhoto photo;
  final VoidCallback onDeleted;

  const _PhotoDetailScreen({
    required this.photo,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final file = PhotoStorage.instance.getPhotoFile(photo);
    final dateLabel = _formatDetailDate(photo.capturedAt);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(dateLabel),
        actions: [
          if (file != null)
            IconButton(
              onPressed: () => Share.shareXFiles(
                [XFile(file.path)],
                text: 'Church Journal photo',
              ),
              icon: const Icon(Icons.share),
            ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: file != null
                    ? Image.file(file, fit: BoxFit.contain)
                    : const Icon(Icons.broken_image, color: Colors.white, size: 64),
              ),
            ),
          ),
          if (photo.journalLabel.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Journal: ${photo.journalLabel}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo will be removed from your gallery.'),
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

    if (confirmed != true || !context.mounted) return;

    await PhotoStorage.instance.deletePhoto(photo.id);
    onDeleted();
    if (context.mounted) Navigator.pop(context);
  }

  String _formatDetailDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.month}/${date.day}/${date.year} $hour:$minute $period';
  }
}
