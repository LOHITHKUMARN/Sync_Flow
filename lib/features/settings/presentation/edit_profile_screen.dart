import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/neumorphic_widgets.dart';
import '../../auth/presentation/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _roleController;
  late final TextEditingController _avatarUrlController;
  bool _isSaving = false;
  String? _selectedAvatarUrl;

  // Curated modern avatar presets
  static const List<String> _avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
  ];

  static const List<String> _roleSuggestions = [
    'Lead Architect',
    'Senior Developer',
    'Product Lead',
    'UI/UX Designer',
    'Engineering Manager',
    'DevOps Specialist',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _roleController = TextEditingController(text: user?.roleTitle ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _selectedAvatarUrl = user?.avatarUrl;

    _avatarUrlController.addListener(() {
      final text = _avatarUrlController.text.trim();
      if (text != _selectedAvatarUrl) {
        setState(() {
          _selectedAvatarUrl = text.isEmpty ? null : text;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedAvatarUrl = picked.path;
          _avatarUrlController.text = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access photos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPhotoOptionsSheet(BuildContext context, Color accentColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        child: NeumorphicContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Profile Photo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a photo from your device or camera',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: NeumorphicContainer(
                    shape: BoxShape.circle,
                    isPressed: true,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.photo_library_rounded, color: accentColor, size: 20),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: NeumorphicContainer(
                    shape: BoxShape.circle,
                    isPressed: true,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.camera_alt_rounded, color: accentColor, size: 20),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_selectedAvatarUrl != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const NeumorphicContainer(
                      shape: BoxShape.circle,
                      isPressed: true,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    ),
                    title: Text(
                      'Remove Photo',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedAvatarUrl = null;
                        _avatarUrlController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _isSaving = true);
    try {
      await ref.read(currentUserProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            roleTitle: _roleController.text.trim().isNotEmpty
                ? _roleController.text.trim()
                : 'Team Contributor',
            avatarUrl: _selectedAvatarUrl,
          );

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        nav.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = ref.watch(accentColorProvider);
    final effectiveAccent = (!isDark &&
            accentColor.toARGB32() == const Color(0xFFFFFFFF).toARGB32())
        ? const Color(0xFF0F172A)
        : accentColor;
    final user = ref.watch(currentUserProvider);

    final scaffoldBg =
        isDark ? NeumorphicColors.darkBase : NeumorphicColors.lightBase;
    final primaryText =
        isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText =
        isDark ? const Color(0xFF8E95A5) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Neumorphic Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      size: 42,
                      iconSize: 16,
                      iconColor: primaryText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'Edit Tactile Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryText,
                      ),
                    ),
                    NeumorphicButton(
                      label: 'Save',
                      isLoading: _isSaving,
                      color: effectiveAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      borderRadius: 12,
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Neumorphic Avatar Preview Hub
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoOptionsSheet(context, effectiveAccent, isDark),
                        child: NeumorphicContainer(
                          shape: BoxShape.circle,
                          isPressed: true,
                          padding: const EdgeInsets.all(6),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              NeumorphicContainer(
                                shape: BoxShape.circle,
                                width: 92,
                                height: 92,
                                child: ClipOval(
                                  child: (_selectedAvatarUrl != null &&
                                          _selectedAvatarUrl!.isNotEmpty)
                                      ? (_selectedAvatarUrl!.startsWith('http')
                                          ? Image.network(_selectedAvatarUrl!,
                                              fit: BoxFit.cover)
                                          : Image.file(File(_selectedAvatarUrl!),
                                              fit: BoxFit.cover))
                                      : Container(
                                          color: effectiveAccent.withValues(alpha: 0.15),
                                          child: Center(
                                            child: Text(
                                              (_nameController.text.isNotEmpty
                                                      ? _nameController.text[0]
                                                      : (user?.fullName.isNotEmpty == true
                                                          ? user!.fullName[0]
                                                          : 'U'))
                                                  .toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                color: effectiveAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: effectiveAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? NeumorphicColors.darkBase : Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: effectiveAccent.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeumorphicButton(
                            label: 'Change Photo',
                            icon: Icons.upload_rounded,
                            color: effectiveAccent,
                            isOutlined: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            borderRadius: 10,
                            onPressed: () =>
                                _showPhotoOptionsSheet(context, effectiveAccent, isDark),
                          ),
                          if (_selectedAvatarUrl != null) ...[
                            const SizedBox(width: 8),
                            NeumorphicButton(
                              label: 'Remove',
                              icon: Icons.close_rounded,
                              color: Colors.redAccent,
                              isOutlined: true,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              borderRadius: 10,
                              onPressed: () {
                                setState(() {
                                  _selectedAvatarUrl = null;
                                  _avatarUrlController.clear();
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar Presets Row in Neumorphic Card
                NeumorphicContainer(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVATAR PRESET GALLERY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _avatarPresets.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final preset = _avatarPresets[index];
                            final isSelected = _selectedAvatarUrl == preset;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAvatarUrl = preset;
                                  _avatarUrlController.text = preset;
                                });
                              },
                              child: NeumorphicContainer(
                                shape: BoxShape.circle,
                                isPressed: isSelected,
                                glowWithAccent: isSelected,
                                accentColor: effectiveAccent,
                                padding: const EdgeInsets.all(3),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(preset),
                                  onBackgroundImageError: (_, __) {},
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeumorphicContainer(
                        isPressed: true,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: TextField(
                          controller: _avatarUrlController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: primaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Or enter custom image URL...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: mutedText,
                            ),
                            icon: Icon(Icons.link_rounded, size: 18, color: effectiveAccent),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            suffixIcon: _avatarUrlController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _avatarUrlController.clear();
                                      setState(() => _selectedAvatarUrl = null);
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Details Neumorphic Section
                Text(
                  'PERSONAL SPECIFICATIONS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: mutedText,
                  ),
                ),
                const SizedBox(height: 12),
                NeumorphicContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      Text(
                        'Full Name',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeumorphicContainer(
                        isPressed: true,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                size: 18, color: effectiveAccent),
                            hintText: 'e.g. Alex Rivera',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: mutedText,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Full name cannot be empty';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Email Address
                      Text(
                        'Account Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeumorphicContainer(
                        isPressed: true,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined,
                                size: 18, color: effectiveAccent),
                            hintText: 'e.g. alex@syncflow.dev',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: mutedText,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Email cannot be empty';
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Role / Title
                      Text(
                        'Role / Title',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeumorphicContainer(
                        isPressed: true,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        child: TextFormField(
                          controller: _roleController,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined,
                                size: 18, color: effectiveAccent),
                            hintText: 'e.g. Lead Architect',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: mutedText,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Role suggestions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _roleSuggestions.map((role) {
                          final isSelected = _roleController.text == role;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _roleController.text = role;
                              });
                            },
                            child: NeumorphicContainer(
                              isPressed: isSelected,
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              glowWithAccent: isSelected,
                              accentColor: effectiveAccent,
                              child: Text(
                                role,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected ? effectiveAccent : mutedText,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save Changes Neumorphic Action Button
                NeumorphicButton(
                  label: 'Commit Profile Changes',
                  icon: Icons.check_circle_rounded,
                  isLoading: _isSaving,
                  color: effectiveAccent,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
