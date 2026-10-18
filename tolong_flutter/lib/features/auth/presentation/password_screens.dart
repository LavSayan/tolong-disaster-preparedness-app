import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../application/session.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  AuthFailure? _error;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FormPage(
      title: l.forgotTitle,
      subtitle: l.forgotSubtitle,
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators(l).email,
              decoration: InputDecoration(labelText: l.email),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_sent) ...[
              InlineMessage(l.resetSent, tone: MessageTone.success),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (_error != null) ...[
              InlineMessage(l.authError(_error!), tone: MessageTone.error),
              const SizedBox(height: AppSpacing.lg),
            ],
            LoadingButton(label: _sent ? l.sendAgain : l.sendResetLink, loading: _loading, onPressed: _submit),
          ]),
        ),
      ],
    );
  }
}

/// Shown after the user opens the reset link from their email (Supabase "password recovery" event).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  AuthFailure? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.passwordUpdated)));
      ref.read(sessionProvider.notifier).finishPasswordRecovery();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators(l);
    return FormPage(
      title: l.resetTitle,
      showBack: false,
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            PasswordField(controller: _password, label: l.newPassword, validator: v.password),
            gap,
            PasswordField(
              controller: _confirm,
              label: l.confirmNewPassword,
              validator: v.confirmPassword(() => _password.text),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              InlineMessage(l.authError(_error!), tone: MessageTone.error),
              const SizedBox(height: AppSpacing.lg),
            ],
            LoadingButton(label: l.saveNewPassword, loading: _loading, onPressed: _submit),
          ]),
        ),
      ],
    );
  }
}
