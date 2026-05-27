import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class PersonalInfoPage extends ConsumerStatefulWidget {
  static const String routeName = '/personal-info';
  const PersonalInfoPage({super.key});

  @override
  ConsumerState<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends ConsumerState<PersonalInfoPage> {
  late TextEditingController _nameController;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appUserNotifierProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final error = await ref.read(authNotifierProvider.notifier).updateProfile(
          fullName: newName,
        );
    
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress image
    );

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);

      final error = await ref.read(authNotifierProvider.notifier).uploadAvatar(
            File(pickedFile.path),
          );

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserNotifierProvider);
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Personal Information', style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.getTextPrimary(context))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppPallete.getCardColor(context),
                      boxShadow: AppPallete.getDynamicSoftShadow(context),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                      child: _isUploading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : (user?.avatarUrl == null
                              ? Text(
                                  user?.fullName?.isNotEmpty == true ? user!.fullName![0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppPallete.getPrimaryColor(context)),
                                )
                              : null),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppPallete.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPallete.getBackgroundColor(context), width: 2),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      onPressed: _isUploading ? null : _pickAndUploadImage,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: AppPallete.getInputDecoration(
                context,
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppPallete.getCardColor(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.getBorderColor(context).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, size: 20, color: AppPallete.getTextSecondary(context).withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Text(
                    userEmail,
                    style: TextStyle(color: AppPallete.getTextSecondary(context), fontSize: 15),
                  ),
                  const Spacer(),
                  Icon(Icons.lock_outline_rounded, size: 16, color: AppPallete.getTextSecondary(context).withValues(alpha: 0.3)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppPallete.getTextSecondary(context),
      ),
    );
  }
}
