import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _autoApproveTeams = true;
  bool _autoApproveMatches = false;
  bool _emailAlerts = true;
  bool _pushAlerts = true;

  @override
  Widget build(BuildContext context) {
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
          _sectionTitle('Platform'),
          _switchTile(
            title: 'Maintenance Mode',
            subtitle: 'Temporarily disable scoring for all users',
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
          ),
          _divider(),
          _switchTile(
            title: 'Auto-approve teams',
            subtitle: 'New teams are approved automatically',
            value: _autoApproveTeams,
            onChanged: (v) => setState(() => _autoApproveTeams = v),
          ),
          _divider(),
          _switchTile(
            title: 'Auto-approve matches',
            subtitle: 'Completed matches are published automatically',
            value: _autoApproveMatches,
            onChanged: (v) => setState(() => _autoApproveMatches = v),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Notifications'),
          _switchTile(
            title: 'Email alerts',
            subtitle: 'Send admin alerts to email',
            value: _emailAlerts,
            onChanged: (v) => setState(() => _emailAlerts = v),
          ),
          _divider(),
          _switchTile(
            title: 'Push alerts',
            subtitle: 'Enable push notifications for admin',
            value: _pushAlerts,
            onChanged: (v) => setState(() => _pushAlerts = v),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Danger zone'),
          ListTile(
            tileColor: C.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Sign out admin'),
            subtitle: Text('Return to role selection', style: TextStyle(color: C.grey, fontSize: 12)),
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
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
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.grey),
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
        subtitle: Text(subtitle, style: TextStyle(color: C.grey, fontSize: 12)),
      ),
    );
  }

  Widget _divider() => const SizedBox(height: 10);
}

