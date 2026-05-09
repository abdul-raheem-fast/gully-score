import 'package:flutter/material.dart';
import '../../models/player_models.dart';
import '../../state/app_store.dart';
import '../../theme/app_theme.dart';

/// Admin inbox for team membership requests.
class AdminInboxScreen extends StatelessWidget {
  const AdminInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.of(context);
    final memberships = store.adminMemberships;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: C.adminBlue,
        foregroundColor: C.white,
        actions: [
          IconButton(
            onPressed: () async {
              await store.refreshAdminMemberships();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inbox refreshed')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.isLoadingAdminMemberships) const LinearProgressIndicator(minHeight: 2),
          if (store.adminMembershipsLoadError != null)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                store.adminMembershipsLoadError!,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: memberships.isEmpty
                ? Center(
                    child: Text(
                      'No requests found',
                      style: TextStyle(color: C.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: memberships.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final membership = memberships[i];
                      return Card(
                        color: C.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${membership.teamName} (${membership.teamAbbreviation})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Applied: ${membership.appliedAt.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(fontSize: 12, color: C.grey),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: membership.status == MembershipStatus.pending
                                          ? Colors.yellow.shade100
                                          : membership.status == MembershipStatus.approved
                                              ? Colors.green.shade100
                                              : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      membership.status.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: membership.status == MembershipStatus.pending
                                            ? Colors.yellow.shade800
                                            : membership.status == MembershipStatus.approved
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (membership.status == MembershipStatus.pending) ...[
                                    TextButton(
                                      onPressed: () async {
                                        await store.updateMembershipStatus(
                                          membership.id,
                                          MembershipStatus.approved,
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Approved')),
                                        );
                                      },
                                      child: const Text('Approve'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await store.updateMembershipStatus(
                                          membership.id,
                                          MembershipStatus.rejected,
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Rejected')),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
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
}