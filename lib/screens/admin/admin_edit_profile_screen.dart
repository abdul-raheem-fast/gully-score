import 'package:flutter/material.dart';

import '../../route_paths.dart';
import '../../services/supabase_service.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class AdminEditProfileScreen extends StatefulWidget {
  const AdminEditProfileScreen({super.key});

  @override
  State<AdminEditProfileScreen> createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final currentUser = SupabaseService.currentUser;
    final name = currentUser?.userMetadata?['name']?.toString() ??
        AppStore.of(context).userName;
    final organization = currentUser?.userMetadata?['organization']?.toString() ?? '';

    _nameCtrl.text = name;
    _orgCtrl.text = organization;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final organization = _orgCtrl.text.trim();
    final currentUser = SupabaseService.currentUser;

    if (name.isEmpty) {
      _showError('Name cannot be empty.');
      return;
    }

    if (currentUser == null) {
      _showError('No signed-in admin user found.');
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.updateAdminProfile(
        userId: currentUser.id,
        name: name,
        organization: organization,
      );

      AppStore.of(context).login(name);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.'),
          backgroundColor: C.g2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      _showError('Failed to update profile. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseService.currentUser;
    final email = currentUser?.email ?? 'admin@unknown.com';

    return Scaffold(
      backgroundColor: C.white,
      appBar: AppBar(
        title: const Text('Edit Admin Profile'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your name and organization details below.',
                style: TextStyle(color: C.grey, fontSize: 14),
              ),
              const SizedBox(height: 26),
              AppField(
                label: 'Full Name',
                hint: 'Admin Name',
                icon: Icons.person_outline,
                ctrl: _nameCtrl,
              ),
              const SizedBox(height: 18),
              AppField(
                label: 'Organization / Club',
                hint: 'City Cricket Club',
                icon: Icons.business_outlined,
                ctrl: _orgCtrl,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: C.gLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 18, color: C.g1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email,
                        style: const TextStyle(color: C.dark, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _loading
                  ? Center(child: CircularProgressIndicator(color: C.adminBlue))
                  : AppButton(
                      label: 'Save changes',
                      onTap: _saveProfile,
                      color: C.adminBlue,
                    ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(
                    context,
                    RoutePaths.adminProfile,
                  ),
                  child: Text(
                    'Back to profile',
                    style: TextStyle(color: C.adminBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
