import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// Clinical User Profile & Security Settings Screen for SkinGuard UAE.
class ProfileScreen extends StatefulWidget {
  final VoidCallback onLoggedOut;
  final bool isArabic;

  const ProfileScreen({
    super.key,
    required this.onLoggedOut,
    this.isArabic = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  bool _isSavingName = false;
  String? _selectedAvatarBase64;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    _nameController.text = user?.fullName ?? '';
    _selectedAvatarBase64 = user?.avatarData;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatarImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() => _selectedAvatarBase64 = base64Image);
        await AuthService.updateProfile(avatarData: base64Image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF059669),
              content: Text('Profile picture updated successfully.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Avatar pick error: $e');
    }
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSavingName = true);
    final res = await AuthService.updateProfile(fullName: newName);
    setState(() => _isSavingName = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: res.success ? const Color(0xFF059669) : const Color(0xFFDC2626),
          content: Text(res.message),
        ),
      );
    }
  }

  void _showChangePasswordSheet() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 22),
                      SizedBox(width: 8),
                      Text('Strict Password Change', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Requires verification of your existing old password before applying salted PBKDF2 update.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: oldPwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Old Password',
                  prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Secure Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPwdCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18, color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (oldPwdCtrl.text.isEmpty || newPwdCtrl.text.isEmpty) return;
                          if (newPwdCtrl.text != confirmPwdCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFFDC2626),
                                content: Text('New passwords do not match.'),
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          final res = await AuthService.changePassword(
                            oldPassword: oldPwdCtrl.text,
                            newPassword: newPwdCtrl.text,
                          );
                          if (!modalCtx.mounted) return;
                          setModalState(() => isSubmitting = false);

                          if (res.success) {
                            Navigator.pop(modalCtx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF059669),
                                  content: Text(res.message),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFFDC2626),
                                  content: Text(res.message),
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify Old & Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out of SkinGuard?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Your offline patient records will remain stored securely on this device, but your session token will be cleared.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              widget.onLoggedOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgSurface = Color(0xFFF8FAFC);
    const brandSky = Color(0xFF0284C7);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF64748B);
    const borderSubtle = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isArabic ? 'الملف الشخصي والأمان' : 'Profile & Security',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: ValueListenableBuilder<UserProfile?>(
        valueListenable: AuthService.currentUserNotifier,
        builder: (context, user, _) {
          if (user == null) {
            return const Center(child: Text('No active user profile.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0284C7).withOpacity(0.12),
                        border: Border.all(color: brandSky, width: 2.5),
                      ),
                      child: ClipOval(
                        child: _selectedAvatarBase64 != null && _selectedAvatarBase64!.startsWith('data:image')
                            ? Image.memory(
                                base64Decode(_selectedAvatarBase64!.split(',').last),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: brandSky),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAvatarImage,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: brandSky,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Text(
                    user.role == 'clinician_navigator' ? 'Abu Dhabi Malaffi Verified Clinician' : 'Registered Citizen Patient',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: brandSky),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Profile Information
              const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 10),

              // Full Name (Editable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Full Name (Editable)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: brandSky),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandSky,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSavingName ? null : _saveName,
                          child: _isSavingName
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Email Address (STRICTLY LOCKED)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Registered Health Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_rounded, size: 10, color: Color(0xFF059669)),
                              SizedBox(width: 3),
                              Text('Permanently Locked', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mail_lock_outlined, size: 18, color: textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                          ),
                          const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Under Abu Dhabi Malaffi HIE regulations, registered healthcare identity emails are strictly immutable.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Security & Credentials
              const Text('SECURITY & CREDENTIALS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderSubtle),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded, color: brandSky, size: 20),
                      title: const Text('Change Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                      subtitle: const Text('Requires old password verification', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textSecondary),
                      onTap: _showChangePasswordSheet,
                    ),
                    const Divider(height: 1, indent: 50),
                    const ListTile(
                      leading: Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 20),
                      title: Text('Encryption & Zero-PII Standard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                      subtitle: Text('PBKDF2-HMAC-SHA256 salted hashes', style: TextStyle(fontSize: 10.5, color: textSecondary)),
                      trailing: Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log Out of Session', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
