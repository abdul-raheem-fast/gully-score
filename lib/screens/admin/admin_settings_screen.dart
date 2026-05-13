import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _emailAlerts = true;
  bool _pushAlerts = true;
  bool _maintenanceMode = false;
  bool _autoApprove = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailAlerts = prefs.getBool('email_alerts') ?? true;
      _pushAlerts = prefs.getBool('push_alerts') ?? true;
      _maintenanceMode = prefs.getBool('maintenance_mode') ?? false;
      _autoApprove = prefs.getBool('auto_approve') ?? false;
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _syncAll(AppStoreState store) async {
    await Future.wait([
      store.refreshMatches(),
      store.refreshTeams(),
      store.refreshUsers(),
      store.refreshMyMemberships(),
      store.refreshAdminMemberships(),
    ]);
  }

  Future<void> _clearLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email_alerts');
    await prefs.remove('push_alerts');
    await prefs.remove('maintenance_mode');
    await prefs.remove('auto_approve');
    setState(() {
      _emailAlerts = true;
      _pushAlerts = true;
      _maintenanceMode = false;
      _autoApprove = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: C.adminBlue,
          foregroundColor: C.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('System'),
          ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(Icons.sync, color: C.adminBlue),
            ),
            title: const Text('Sync all data'),
            subtitle: const Text('Refresh users, teams, matches, and requests',
                style: TextStyle(color: C.grey, fontSize: 12)),
            onTap: () async {
              final store = AppStore.of(context);
              await _syncAll(store);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data synced successfully')),
              );
            },
          ),
          _divider(),
          ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.cleaning_services, color: Colors.deepOrange),
            ),
            title: const Text('Clear local settings'),
            subtitle: const Text('Reset toggles to defaults',
                style: TextStyle(color: C.grey, fontSize: 12)),
            onTap: () async {
              await _clearLocalSettings();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local settings cleared')),
              );
            },
          ),
          const SizedBox(height: 18),
          _sectionTitle('Platform'),
          _switchTile(
            title: 'Maintenance Mode',
            subtitle: 'Temporarily disable user access to the app',
            value: _maintenanceMode,
            onChanged: (v) {
              setState(() => _maintenanceMode = v);
              _saveSetting('maintenance_mode', v);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v ? 'Maintenance mode enabled' : 'Maintenance mode disabled')));
            },
          ),
          _divider(),
          _switchTile(
            title: 'Auto-approve Teams',
            subtitle: 'Automatically approve new team registrations',
            value: _autoApprove,
            onChanged: (v) {
              setState(() => _autoApprove = v);
              _saveSetting('auto_approve', v);
            },
          ),
          const SizedBox(height: 18),
          _sectionTitle('Notifications'),
          _switchTile(
            title: 'Email alerts',
            subtitle: 'Receive admin alerts via email',
            value: _emailAlerts,
            onChanged: (v) {
              setState(() => _emailAlerts = v);
              _saveSetting('email_alerts', v);
            },
          ),
          _divider(),
          _switchTile(
            title: 'Push notifications',
            subtitle: 'Enable push notifications',
            value: _pushAlerts,
            onChanged: (v) {
              setState(() => _pushAlerts = v);
              _saveSetting('push_alerts', v);
            },
          ),
          const SizedBox(height: 18),
          _sectionTitle('Account'),
          ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Sign out'),
            subtitle: const Text('Return to role selection', style: TextStyle(color: C.grey, fontSize: 12)),
            onTap: () async {
              final store = AppStore.of(context);
              await store.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/role-select', (r) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.grey),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: C.g2,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: C.grey, fontSize: 12)),
      ),
    );
  }

  Widget _divider() => const SizedBox(height: 10);
}