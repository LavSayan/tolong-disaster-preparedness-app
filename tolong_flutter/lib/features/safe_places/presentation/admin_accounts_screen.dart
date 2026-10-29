import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../data/shelter_review_repository.dart';

/// Admin account management: finding accounts by email and moving them between user
/// and government reviewer. The first admin is seeded in the Supabase dashboard
/// (bootstrap); this screen cannot create one, and the server ignores role changes
/// from anyone who is not an admin.
class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  final _search = TextEditingController();
  List<AdminAccount>? _accounts;
  bool _loading = false;
  String? _busyUserId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final accounts = await ref.read(adminAccountRepositoryProvider).directory(emailQuery: _search.text);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } on AdminFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _accounts = [];
        _loading = false;
      });
      showMessage(context, context.l10n.adminError(f.code));
    }
  }

  Future<void> _setRole(AdminAccount account, AppUserRole role) async {
    setState(() => _busyUserId = account.id);
    try {
      await ref.read(adminAccountRepositoryProvider).setRole(account.id, role);
      if (!mounted) return;
      showMessage(context, context.l10n.adminDone);
      await _load();
    } on AdminFailure catch (f) {
      if (!mounted) return;
      setState(() => _busyUserId = null);
      showMessage(context, context.l10n.adminError(f.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accounts = _accounts;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        title: Text(l.adminTitle, style: serif(20)),
      ),
      body: accounts == null
          ? _Loader(l: l, loading: _loading, onSearch: _load, searchController: _search)
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
              children: [
                _SearchRow(l: l, loading: _loading, onSearch: _load, searchController: _search),
                gap,
                if (accounts.isEmpty)
                  InlineMessage(l.adminEmpty)
                else
                  for (final a in accounts)
                    _AccountCard(account: a, busyUserId: _busyUserId, onSetRole: _setRole),
              ],
            ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.l, required this.loading, required this.onSearch, required this.searchController});

  final AppLocalizations l;
  final bool loading;
  final VoidCallback onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _SearchRow(l: l, loading: loading, onSearch: onSearch, searchController: searchController),
        gap,
        InlineMessage(l.adminEmpty),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.l, required this.loading, required this.onSearch, required this.searchController});

  final AppLocalizations l;
  final bool loading;
  final VoidCallback onSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(hintText: l.adminSearchHint, labelText: l.adminSearchHint),
          onSubmitted: (_) => onSearch(),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      FilledButton(
        onPressed: loading ? null : onSearch,
        child: Text(l.adminSearch),
      ),
    ]);
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.busyUserId, required this.onSetRole});

  final AdminAccount account;
  final String? busyUserId;
  final Future<void> Function(AdminAccount, AppUserRole) onSetRole;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = busyUserId == account.id;
    final role = account.role ?? AppUserRole.user;
    final promote = role == AppUserRole.user;

    return CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(account.email ?? '—', style: sans(13, weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(account.fullName ?? '', style: sans(11, color: AppColors.muted)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Eyebrow(l.roleName(role).toUpperCase()),
          if (!busy)
            TextButton(
              onPressed: () => onSetRole(account, promote ? AppUserRole.government : AppUserRole.user),
              child: Text(promote ? l.adminPromote : l.adminDemote),
            )
          else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ]),
      ]),
    );
  }
}
