import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/timetable_api.dart';
import '../providers/auth_provider.dart';
import '../widgets/create_sheet_kit.dart';

class SchoolGalleryHub extends StatefulWidget {
  const SchoolGalleryHub({super.key});

  @override
  State<SchoolGalleryHub> createState() => _SchoolGalleryHubState();
}

class _SchoolGalleryHubState extends State<SchoolGalleryHub> {
  bool _isLoading = true;
  List<dynamic> _albums = [];
  List<dynamic> _filteredAlbums = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGalleries();
    _searchController.addListener(_filterAlbums);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGalleries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.getGalleries();

    if (mounted) {
      final data = res['data'];
      if (data is List) {
        setState(() {
          _albums = data;
          _filteredAlbums = data;
          _isLoading = false;
        });
      } else if (res['success'] == true && data == null) {
        setState(() {
          _albums = [];
          _filteredAlbums = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              res['message']?.toString() ?? 'Failed to load gallery albums.';
          _isLoading = false;
        });
      }
    }
  }

  void _filterAlbums() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredAlbums = List.from(_albums);
      } else {
        _filteredAlbums = _albums.where((album) {
          final title = (album['event_name'] ?? '').toString().toLowerCase();
          final desc = (album['description'] ?? '').toString().toLowerCase();
          return title.contains(query) || desc.contains(query);
        }).toList();
      }
    });
  }

  String _formatImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return 'https://eliteinternationalschool-live.us.stackstaging.com$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddGalleryDialog,
              backgroundColor: const Color(0xFF0077BE),
              icon: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
              label: const Text('Add Gallery Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeroHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0077BE),
                        strokeWidth: 3,
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _filteredAlbums.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _fetchGalleries,
                              color: const Color(0xFF0077BE),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                                itemCount: _filteredAlbums.length,
                                itemBuilder: (context, index) {
                                  final album = _filteredAlbums[index];
                                  return _buildPremiumAlbumCard(album, isAdmin);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2540), Color(0xFF0077BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x330077BE),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                'Media Gallery',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _fetchGalleries,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'School Events & Memories 📸',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Browse high-quality photo albums of sports, exhibitions & ceremonies',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                icon: Icon(Icons.search_rounded, color: Color(0xFF0077BE)),
                hintText: 'Search album by event name...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAlbumCard(Map<String, dynamic> album, bool isAdmin) {
    final String title = album['event_name'] ?? 'School Event';
    final String description = album['description'] ?? '';
    final String date = album['event_date'] ?? '';
    final List<dynamic> images = album['images'] ?? [];
    final int count = images.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openAlbumDetails(album),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Collage Preview Header
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  children: [
                    _buildPhotoMosaic(images),
                    // Gradient Shadow Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(140),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: GestureDetector(
                          onTap: () => _confirmDeleteGallery(album),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withAlpha(60)),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Photo Counter Floating Pill
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.collections_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$count Photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Title over Image (Bottom Left)
                    Positioned(
                      bottom: 14,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Card Details Bottom
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (date.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0077BE).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event_outlined,
                                  size: 13,
                                  color: Color(0xFF0077BE),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0077BE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: const [
                            Text(
                              'View Album',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0077BE),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Color(0xFF0077BE),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoMosaic(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        color: const Color(0xFFE2E8F0),
        child: const Center(
          child: Icon(
            Icons.photo_library_outlined,
            size: 50,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    final String cover1 = _formatImageUrl(images[0]['image_url'].toString());

    if (images.length == 1) {
      return Image.network(
        cover1,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _buildPlaceholderMosaic(),
      );
    }

    final String cover2 = _formatImageUrl(images[1]['image_url'].toString());

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Image.network(
            cover1,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _buildPlaceholderMosaic(),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 1,
          child: Image.network(
            cover2,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _buildPlaceholderMosaic(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderMosaic() {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 36),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0077BE).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.collections_outlined,
                size: 60,
                color: Color(0xFF0077BE),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Event Galleries Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When the administration uploads photos of school events, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchGalleries,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077BE),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAlbumDetails(Map<String, dynamic> album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventAlbumDetailScreen(
          album: album,
          formatImageUrl: _formatImageUrl,
        ),
      ),
    );
  }

  // ---------------- Admin: Create / Delete Gallery Album ----------------

  void _showAddGalleryDialog() {
    final eventNameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    List<XFile> selectedImages = [];
    bool isSubmitting = false;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-'
                '${selectedDate.month.toString().padLeft(2, '0')}-'
                '${selectedDate.day.toString().padLeft(2, '0')}';

            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 14,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sheetDragHandle(),
                    sheetHeader(
                      icon: Icons.collections_rounded,
                      title: 'Create Gallery Event Album',
                      subtitle: 'Upload photos for a school event',
                    ),
                    const SizedBox(height: 24),
                    sheetSectionLabel('Event Name'),
                    TextField(
                      controller: eventNameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: sheetFieldDecoration(
                        hint: 'e.g. Annual Sports Day 2026',
                        icon: Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Event Date'),
                    sheetPickerTile(
                      icon: Icons.calendar_month_rounded,
                      label: 'DATE',
                      value: dateStr,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setModalState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Description'),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: sheetFieldDecoration(
                        hint: 'Brief details or highlights of this event...',
                      ),
                    ),
                    const SizedBox(height: 18),
                    sheetSectionLabel('Photos'),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final picked = await picker.pickMultiImage();
                        if (picked.isNotEmpty) {
                          setModalState(() => selectedImages.addAll(picked));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: kSheetAccentColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kSheetAccentColor.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kSheetAccentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: kSheetAccentColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              selectedImages.isEmpty ? 'Tap to select photos' : 'Add more photos',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: kSheetAccentColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'JPG, PNG or WEBP · up to 10MB each',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '${selectedImages.length} photo${selectedImages.length == 1 ? '' : 's'} selected',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final img = selectedImages[index];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(img.path),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => selectedImages.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    sheetSubmitButton(
                      label: 'UPLOAD GALLERY ALBUM',
                      icon: Icons.cloud_upload_rounded,
                      isLoading: isSubmitting,
                      onPressed: () async {
                        if (eventNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event name is required')),
                          );
                          return;
                        }
                        if (selectedImages.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one photo')),
                          );
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        final response = await ApiService.createGallery(
                          eventName: eventNameController.text.trim(),
                          description: descriptionController.text.trim(),
                          eventDate: dateStr,
                          imagePaths: selectedImages.map((x) => x.path).toList(),
                        );
                        final success = response['success'] == true || response['data'] != null;
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Gallery event album created successfully!'
                                  : (response['message']?.toString() ?? 'Failed to create gallery album')),
                              backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                            ),
                          );
                          if (success) _fetchGalleries();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteGallery(Map<String, dynamic> album) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Gallery Album'),
        content: const Text('Are you sure you want to delete this gallery album and all its photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final id = album['id'];
              final response = await ApiService.deleteGallery(id is int ? id : int.parse(id.toString()));
              final success = response['success'] == true;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Gallery album deleted successfully!' : (response['message']?.toString() ?? 'Failed to delete album')),
                    backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
                  ),
                );
                if (success) _fetchGalleries();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class EventAlbumDetailScreen extends StatelessWidget {
  final Map<String, dynamic> album;
  final String Function(String) formatImageUrl;

  const EventAlbumDetailScreen({
    super.key,
    required this.album,
    required this.formatImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final String title = album['event_name'] ?? 'Event Album';
    final String description = album['description'] ?? '';
    final String date = album['event_date'] ?? '';
    final List<dynamic> images = album['images'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Banner Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 14, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🖼️ Total ${images.length} High-Res Photos',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Photos Grid
          Expanded(
            child: images.isEmpty
                ? const Center(
                    child: Text(
                      'No photos uploaded to this album yet.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imgUrl = formatImageUrl(
                        images[index]['image_url'].toString(),
                      );
                      return GestureDetector(
                        onTap: () =>
                            _openFullScreenImage(context, images, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.white38),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(
      BuildContext context, List<dynamic> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageGallery(
          images: images,
          initialIndex: initialIndex,
          formatImageUrl: formatImageUrl,
        ),
      ),
    );
  }
}

class FullScreenImageGallery extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final String Function(String) formatImageUrl;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.formatImageUrl,
  });

  @override
  State<FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Photo ${_currentIndex + 1} of ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imgUrl = widget.formatImageUrl(
            widget.images[index]['image_url'].toString(),
          );
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 60),
                    SizedBox(height: 8),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
