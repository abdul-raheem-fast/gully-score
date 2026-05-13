import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../route_paths.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  // Track which join_request cards are being acted on
  final Set<String> _acting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.fetchMyNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = data;
      _loading = false;
    });
    // Mark all as read silently.
    SupabaseService.markAllNotificationsRead();
  }

  Future<void> _handleJoinRequest(
      Map<String, dynamic> notif, String decision) async {
    final membershipId = notif['membership_id']?.toString() ?? '';
    final nId = notif['id']?.toString() ?? '';
    if (membershipId.isEmpty) return;
    setState(() => _acting.add(nId));
    try {
      await SupabaseService.updateMembershipStatus(
          id: membershipId, status: decision);
      if (!mounted) return;
      // Optimistically remove / update the card.
      setState(() {
        _notifications = _notifications.map((n) {
          if (n['id']?.toString() == nId) {
            return {...n, '_acted': decision};
          }
          return n;
        }).toList();
      });
      _showSnack(
        decision == 'approved'
            ? '✅ Player approved and added to team!'
            : '❌ Request rejected.',
        decision == 'approved' ? C.g2 : Colors.red.shade600,
      );
    } catch (_) {
      if (mounted) _showSnack('Action failed. Try again.', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _acting.remove(nId));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushReplacementNamed(RoutePaths.home),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: C.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: C.dark, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: C.dark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (!_loading && _notifications.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await SupabaseService.markAllNotificationsRead();
                        await _load();
                      },
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                            fontSize: 12,
                            color: C.g1,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: C.g2))
                  : _notifications.isEmpty
                      ? _EmptyState()
                      : RefreshIndicator(
                          color: C.g2,
                          onRefresh: _load,
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final n = _notifications[i];
                              final type = n['type']?.toString() ?? '';
                              if (type == 'join_request' || type == 'team_invitation') {
                                return _JoinRequestCard(
                                  notif: n,
                                  acting: _acting
                                      .contains(n['id']?.toString() ?? ''),
                                  onApprove: () =>
                                      _handleJoinRequest(n, 'approved'),
                                  onReject: () =>
                                      _handleJoinRequest(n, 'rejected'),
                                );
                              }
                              return _DecisionCard(notif: n);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Join Request Card (shown to captain) ──────────────────────────
class _JoinRequestCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestCard({
    required this.notif,
    required this.acting,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final type = notif['type']?.toString() ?? '';
    final playerName = notif['player_name']?.toString() ?? 'A player';
    final teamName = notif['team_name']?.toString() ?? '';
    final isRead = notif['is_read'] == true;
    final acted = notif['_acted']?.toString();
    final createdAt =
        DateTime.tryParse(notif['created_at']?.toString() ?? '') ??
            DateTime.now();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: acted != null
            ? const Color(0xFFF5F7F8)
            : isRead
                ? C.white
                : const Color(0xFFEDF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acted != null
              ? Colors.transparent
              : isRead
                  ? Colors.transparent
                  : C.g2.withAlpha(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 14, color: C.dark, height: 1.4),
                        children: [
                          TextSpan(
                            text: playerName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                              text: type == 'team_invitation'
                                  ? ' invited you to join '
                                  : ' wants to join '),
                          TextSpan(
                            text: teamName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(createdAt),
                      style: const TextStyle(fontSize: 11, color: C.grey),
                    ),
                  ],
                ),
              ),
              if (!isRead && acted == null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: C.g2,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (acted != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: acted == 'approved'
                    ? C.g2.withAlpha(18)
                    : Colors.red.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    acted == 'approved'
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    size: 16,
                    color: acted == 'approved' ? C.g2 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    acted == 'approved' ? 'Request approved' : 'Request rejected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          acted == 'approved' ? C.g2 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            )
          else if (acting)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(strokeWidth: 2.5, color: C.g2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Approve',
                    icon: Icons.check_rounded,
                    color: C.g2,
                    filled: true,
                    onTap: onApprove,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: Colors.red.shade600,
                    filled: false,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Decision Card (shown to player) ──────────────────────────────
class _DecisionCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  const _DecisionCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    final type = notif['type']?.toString() ?? '';
    final isApproved = type == 'request_approved';
    final teamName = notif['team_name']?.toString() ?? '';
    final isRead = notif['is_read'] == true;
    final createdAt =
        DateTime.tryParse(notif['created_at']?.toString() ?? '') ??
            DateTime.now();

    final color = isApproved ? C.g2 : Colors.red.shade600;
    final icon = isApproved
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;
    final gradient = isApproved
        ? const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)])
        : LinearGradient(colors: [Colors.red.shade700, Colors.red.shade600]);

    return Container(
      decoration: BoxDecoration(
        color: isRead ? C.white : (isApproved ? const Color(0xFFEDF7EE) : const Color(0xFFFFF1F1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(isRead ? 0 : 50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 14, color: C.dark, height: 1.4),
                    children: [
                      TextSpan(
                        text: isApproved ? 'Welcome aboard! ' : 'Not this time. ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: isApproved
                            ? 'Your request to join '
                            : 'Your request to join ',
                      ),
                      TextSpan(
                        text: teamName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: isApproved ? ' was approved.' : ' was rejected.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(createdAt),
                  style: const TextStyle(fontSize: 11, color: C.grey),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: filled ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : color)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: C.g2.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: C.g2),
            ),
            const SizedBox(height: 16),
            const Text(
              'All caught up!',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: C.dark),
            ),
            const SizedBox(height: 6),
            const Text(
              'No notifications yet.',
              style: TextStyle(fontSize: 13, color: C.grey),
            ),
          ],
        ),
      );
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
