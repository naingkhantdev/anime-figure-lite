import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/blacklist_repository.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../models/blacklist_entry.dart';
import '../../models/shop.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';
import 'blacklist_page.dart';

enum _Filter { all, customers, shopAdmins, blocked }

/// Super admin only: every account that has opened the app, customers and
/// shop admins alike, to find someone and block or unblock them.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // A shop's id is its owner's uid.
    final shops = {
      for (final s in ref.watch(allShopsProvider).valueOrNull ?? const <Shop>[])
        s.id: s,
    };
    final blocked = {
      for (final e in ref.watch(blacklistProvider).valueOrNull ??
          const <BlacklistEntry>[])
        e.email: e,
    };
    final me = ref.watch(authStateProvider).valueOrNull?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(l.users)),
      body: AsyncBody(
        value: ref.watch(allUsersProvider),
        data: (users) {
          BlacklistEntry? blockOf(AppUser u) =>
              blocked[BlacklistRepository.keyFor(u.email)];
          final q = _query.trim().toLowerCase();
          final visible = users.where((u) {
            final shop = shops[u.id];
            final keep = switch (_filter) {
              _Filter.all => true,
              _Filter.customers => shop == null,
              _Filter.shopAdmins => shop != null,
              _Filter.blocked => blockOf(u) != null,
            };
            return keep &&
                (q.isEmpty ||
                    u.email.toLowerCase().contains(q) ||
                    (shop?.name.toLowerCase().contains(q) ?? false));
          }).toList();
          return ListView(
            padding: pagePadding(context),
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchUsers,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (label, filter) in [
                    (l.all, _Filter.all),
                    (l.customers, _Filter.customers),
                    (l.shopAdmins, _Filter.shopAdmins),
                    (l.blockedFilter, _Filter.blocked),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                EmptyState(
                  icon: Icons.person_search_outlined,
                  title: l.noUsersHere,
                  message: l.usersFootnote,
                )
              else ...[
                for (final (i, user) in visible.indexed) ...[
                  Reveal(
                    index: i,
                    child: _UserTile(
                      user: user,
                      shop: shops[user.id],
                      block: blockOf(user),
                      isMe: user.id == me,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Text(l.usersFootnote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.inkSubtle, fontSize: 13)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.shop,
    required this.block,
    required this.isMe,
  });

  final AppUser user;
  final Shop? shop;
  final BlacklistEntry? block;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = isMe
        ? l.you
        : shop == null
            ? l.roleCustomer
            : l.roleShopAdmin(shop!.name);
    final subtitle = [
      role,
      if (user.lastSeenAt != null) l.lastSeenOn(formatDate(user.lastSeenAt!)),
    ].join(' · ');
    final blocked = block != null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        leading: CircleAvatar(
          backgroundColor:
              blocked ? AppColors.dangerSoft : AppColors.accentSoft,
          foregroundColor: blocked ? AppColors.dangerInk : AppColors.accent,
          child: Icon(blocked
              ? Icons.block
              : shop == null
                  ? Icons.person_outline
                  : Icons.storefront_outlined),
        ),
        title: Text(user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppColors.inkMuted)),
        trailing: blocked
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.dangerLine),
                ),
                child: Text(l.blockedTag,
                    style: const TextStyle(
                        color: AppColors.dangerInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              )
            : null,
        // Your own account can't be blocked.
        onTap: isMe
            ? null
            : () => blocked
                ? showBlockSheet(context, entry: block)
                : showBlockSheet(context, email: user.email),
      ),
    );
  }
}
