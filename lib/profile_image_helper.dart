import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileImageAvatar extends StatefulWidget {
  final String? imageUrl;
  final Color accentColor;
  final double size;
  final IconData iconData;
  final Future<void> Function(String newUrl) onUploaded;
  final bool editable;

  const ProfileImageAvatar({
    super.key,
    required this.imageUrl,
    required this.accentColor,
    required this.onUploaded,
    this.size = 82,
    this.iconData = Icons.person,
    this.editable = true,
  });

  @override
  State<ProfileImageAvatar> createState() => _ProfileImageAvatarState();
}

class _ProfileImageAvatarState extends State<ProfileImageAvatar> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final ext = picked.name.split('.').last;
      final uid = DateTime.now().millisecondsSinceEpoch;
      final ref =
          FirebaseStorage.instance.ref().child('profile_images/$uid.$ext');

      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );

      final url = await task.ref.getDownloadURL();
      await widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'CHANGE PROFILE PHOTO',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              _sourceOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                sub: 'Phone gallery ',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _sourceOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                sub: 'Take a new photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _sourceOption(
                  icon: Icons.delete_outline,
                  label: 'Photo remove',
                  sub: 'Default icon ',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    widget.onUploaded('');
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? widget.accentColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: c, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(sub,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    final sz = widget.size;

    return GestureDetector(
      onTap: widget.editable && !_uploading ? _showSourceSheet : null,
      child: Stack(
        children: [
          // ── Avatar circle ──
          Container(
            width: sz,
            height: sz,
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: widget.accentColor.withOpacity(0.35), width: 2),
            ),
            child: ClipOval(
              child: _uploading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: widget.accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : hasImage
                      ? Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: CircularProgressIndicator(
                                        color: widget.accentColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => Icon(
                            widget.iconData,
                            color: widget.accentColor,
                            size: sz * 0.45,
                          ),
                        )
                      : Icon(
                          widget.iconData,
                          color: widget.accentColor,
                          size: sz * 0.45,
                        ),
            ),
          ),

          // ── Edit badge (bottom-right) ──
          if (widget.editable && !_uploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D1117), width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.black, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  uploadProfileImage()  — standalone helper function
//  collection: 'guides' | 'riders' | 'hotels' | 'users' | 'admins'
//  docId: Firestore document ID
//  returns: new URL or null on failure
// ═══════════════════════════════════════════════════════════════════
Future<String?> uploadProfileImageToFirestore({
  required String collection,
  required String docId,
  required BuildContext context,
  required Color accentColor,
}) async {
  final picker = ImagePicker();
  String? source;

  // Source selection dialog
  await showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C2128),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.photo_library_outlined, color: accentColor),
          title: const Text('Gallery', style: TextStyle(color: Colors.white)),
          onTap: () {
            source = 'gallery';
            Navigator.pop(ctx);
          },
        ),
        ListTile(
          leading: Icon(Icons.camera_alt_outlined, color: accentColor),
          title: const Text('Camera', style: TextStyle(color: Colors.white)),
          onTap: () {
            source = 'camera';
            Navigator.pop(ctx);
          },
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );

  if (source == null) return null;

  try {
    final XFile? picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final ext = picked.name.split('.').last;
    final uid = DateTime.now().millisecondsSinceEpoch;
    final ref =
        FirebaseStorage.instance.ref().child('profile_images/$uid.$ext');

    final task =
        await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    final url = await task.ref.getDownloadURL();

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update({'profileImageUrl': url});

    return url;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent),
      );
    }
    return null;
  }
}
