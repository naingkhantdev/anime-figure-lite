import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/blacklist_repository.dart';
import '../../l10n/l10n.dart';
import '../../models/blacklist_entry.dart';
import '../../providers/providers.dart';
import '../../utils/dates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/glass.dart';

/// Super admin only: every blocked account, why, and since when.
class BlacklistPage extends ConsumerStatefulWidget {
  const BlacklistPage({super.key});

  @override
  ConsumerState<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends ConsumerState<BlacklistPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.blacklist)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBlockSheet(context),
        icon: const Icon(Icons.block),
        label: Text(l.blockSomeone),
      ),
      body: AsyncBody(
        value: ref.watch(blacklistProvider),
        data: (entries) {
          final q = _query.trim().toLowerCase();
          final visible = entries
              .where((e) =>
                  q.isEmpty ||
                  e.email.contains(q) ||
                  e.remark.toLowerCase().contains(q))
              .toList();
          return ListView(
            // Room for the button over the last card.
            padding: pagePadding(context, bottom: 96),
            children: [
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l.searchBlacklist,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                EmptyState(
                  icon: Icons.verified_user_outlined,
                  title: l.nobodyBlocked,
                  message: l.nobodyBlockedBody,
                )
              else
                for (final (i, entry) in visible.indexed) ...[
                  Reveal(index: i, child: _EntryTile(entry: entry)),
                  const SizedBox(height: 8),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final BlacklistEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        leading: const Icon(Icons.block, color: AppColors.dangerInk),
        title: Text(entry.email,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            entry.remark,
            if (entry.createdAt != null)
              l.blockedOn(formatDate(entry.createdAt!)),
          ].join('\n'),
          style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
        ),
        isThreeLine: true,
        onTap: () => showBlockSheet(context, entry: entry),
      ),
    );
  }
}

/// Blocks someone new ([email] fills in the field), or, given an [entry],
/// edits its remark or unblocks it.
Future<void> showBlockSheet(BuildContext context,
        {BlacklistEntry? entry, String? email}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _BlockSheet(entry: entry, email: email),
    );

class _BlockSheet extends ConsumerStatefulWidget {
  const _BlockSheet({this.entry, this.email});

  final BlacklistEntry? entry;
  final String? email;

  @override
  ConsumerState<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends ConsumerState<_BlockSheet> {
  late final _email =
      TextEditingController(text: widget.entry?.email ?? widget.email ?? '');
  late final _remark = TextEditingController(text: widget.entry?.remark);
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (mounted) showMessage(context, friendlyError(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    final l = context.l10n;
    final String email;
    try {
      (email, _) = BlacklistRepository.check(_email.text, _remark.text);
    } on BlacklistException catch (e) {
      showMessage(context, friendlyError(context, e));
      return;
    }
    final me = ref.read(authStateProvider).valueOrNull?.email;
    if (me != null && BlacklistRepository.keyFor(me) == email) {
      showMessage(context, l.errCannotBlockYourself);
      return;
    }
    _run(
      () => ref.read(blacklistRepositoryProvider).block(email, _remark.text),
      widget.entry == null ? l.emailBlocked(email) : l.remarkSaved,
    );
  }

  Future<void> _unblock() async {
    final l = context.l10n;
    final email = widget.entry!.email;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.unblockQuestion(email)),
        content: Text(l.unblockBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.unblock),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref.read(blacklistRepositoryProvider).unblock(email),
          l.emailUnblocked(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entry = widget.entry;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(entry == null ? l.blockSomeone : entry.email,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l.blockExplain,
                style: const TextStyle(color: AppColors.inkMuted)),
            const SizedBox(height: 16),
            if (entry == null) ...[
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.email),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _remark,
              minLines: 2,
              maxLines: 5,
              maxLength: maxRemarkLength,
              decoration: InputDecoration(
                labelText: l.remark,
                hintText: l.remarkHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: entry == null
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.dangerInk)
                  : null,
              onPressed: _busy ? null : _save,
              icon: Icon(entry == null ? Icons.block : Icons.check),
              label: Text(entry == null ? l.block : l.save),
            ),
            if (entry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _unblock,
                child: Text(l.unblock),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
