import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../route_paths.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AdminGate extends StatefulWidget {
  final Widget child;
  const AdminGate({super.key, required this.child});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final Future<_GateStatus> _status;

  @override
  void initState() {
    super.initState();
    _status = _checkStatus();
  }

  Future<_GateStatus> _checkStatus() async {
    final status = await SupabaseService.fetchCurrentUserStatus();
    return _GateStatus(
      role: status['role']?.toString(),
      isBlocked: (status['is_blocked'] as bool?) ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateStatus>(
      future: _status,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _GateLoading();
        }
        final status = snapshot.data!;
        if (status.isBlocked) {
          return const _BlockedScreen();
        }
        if (status.role == 'admin') {
          return widget.child;
        }
        return _AccessDenied(
          onSignIn: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RoutePaths.roleSelect,
            (r) => false,
          ),
        );
      },
    );
  }
}

class MaintenanceGate extends StatefulWidget {
  final Widget child;
  const MaintenanceGate({super.key, required this.child});

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  late final Future<_GateState> _state;

  @override
  void initState() {
    super.initState();
    _state = _loadState();
  }

  Future<_GateState> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final maintenance = prefs.getBool('maintenance_mode') ?? false;
    final status = await SupabaseService.fetchCurrentUserStatus();
    final isAdmin = status['role']?.toString() == 'admin';
    final isBlocked = (status['is_blocked'] as bool?) ?? false;
    return _GateState(
      maintenance: maintenance,
      isAdmin: isAdmin,
      isBlocked: isBlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GateState>(
      future: _state,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _GateLoading();
        }
        final state = snapshot.data!;
        if (state.isBlocked) {
          return const _BlockedScreen();
        }
        if (state.maintenance && !state.isAdmin) {
          return const _MaintenanceScreen();
        }
        return widget.child;
      },
    );
  }
}

class _GateState {
  final bool maintenance;
  final bool isAdmin;
  final bool isBlocked;
  const _GateState({
    required this.maintenance,
    required this.isAdmin,
    required this.isBlocked,
  });
}

class _GateStatus {
  final String? role;
  final bool isBlocked;
  const _GateStatus({required this.role, required this.isBlocked});
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: C.bg,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _MaintenanceScreen extends StatelessWidget {
  const _MaintenanceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: C.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.build_circle, color: C.adminBlue, size: 42),
              SizedBox(height: 12),
              Text(
                'Maintenance in progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'We are upgrading the app. Please try again soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  final VoidCallback onSignIn;
  const _AccessDenied({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: C.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, color: C.adminBlue, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Admin access only',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'You do not have permission to view this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.adminBlue,
                  foregroundColor: C.white,
                ),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: C.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.block, color: Colors.red, size: 42),
              SizedBox(height: 12),
              Text(
                'Account blocked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Contact support to restore access.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
