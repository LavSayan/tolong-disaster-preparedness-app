import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/validation.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/form_widgets.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  AuthFailure? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email: _email.text.trim(), password: _password.text);
      // The session listener and router redirect move the user on from here.
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
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                validator: v.loginPassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text(l.forgotPassword)),
              ),
              if (_error != null) ...[
                InlineMessage(l.authError(_error!), tone: MessageTone.error),
                const SizedBox(height: AppSpacing.lg),
              ],
              LoadingButton(label: l.logIn, loading: _loading, onPressed: _submit),
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: () => context.pushReplacement('/register'), child: Text(l.newHere)),
            ]),
          ),
        ),
      ],
    );
  }
}
