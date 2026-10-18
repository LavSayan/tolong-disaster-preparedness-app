import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../../safe_places/data/qc_area_repository.dart';
import '../../safe_places/presentation/barangay_widgets.dart';
import '../../settings/settings.dart';
import '../data/auth_repository.dart';
import 'privacy_notice.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _age = TextEditingController();
  final _barangay = TextEditingController();
  bool _accepted = false;
  bool _showAcceptError = false;
  bool _loading = false;
  AuthFailure? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _age, _barangay]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _showAcceptError = !_accepted);
    if (!valid || !_accepted) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(authRepositoryProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
            age: int.parse(_age.text.trim()),
            barangay: canonicalBarangay(ref.read(barangaysProvider).value, _barangay.text),
            languageCode: ref.read(settingsProvider).language.code,
          );
      if (!mounted) return;
      if (result == SignUpResult.needsEmailVerification) {
        final l = context.l10n;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.checkEmailTitle),
            content: Text(l.checkEmailBody(_email.text.trim())),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.ok))],
          ),
        );
        if (mounted) context.pushReplacement('/login');
      }
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
      title: l.registerTitle,
      subtitle: l.registerSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                validator: v.fullName,
                decoration: InputDecoration(labelText: l.fullName),
              ),
              gap,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: v.email,
                decoration: InputDecoration(labelText: l.email),
              ),
              gap,
              PasswordField(
                controller: _password,
                label: l.password,
                validator: v.password,
                autofillHints: const [AutofillHints.newPassword],
              ),
              gap,
              PasswordField(
                controller: _confirm,
                label: l.confirmPassword,
                validator: v.confirmPassword(() => _password.text),
              ),
              gap,
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: v.age,
                    decoration: InputDecoration(labelText: l.age),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: BarangayField(controller: _barangay, textInputAction: TextInputAction.done)),
              ]),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: _accepted,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (x) => setState(() {
                  _accepted = x ?? false;
                  if (_accepted) _showAcceptError = false;
                }),
                title: Text(l.privacyAccept, style: sans(12, height: 1.4)),
                subtitle: _showAcceptError
                    ? Text(l.privacyAcceptRequired, style: sans(11, color: AppColors.error))
                    : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => showPrivacyNotice(context), child: Text(l.readPrivacy)),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_error != null) ...[
                InlineMessage(l.authError(_error!), tone: MessageTone.error),
                const SizedBox(height: AppSpacing.lg),
              ],
              LoadingButton(label: l.createAccount, loading: _loading, onPressed: _submit),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: () => context.pushReplacement('/login'), child: Text(l.haveAccount)),
            ]),
          ),
        ),
      ],
    );
  }
}
