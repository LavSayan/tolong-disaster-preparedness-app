import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import 'animations.dart';
import 'common.dart';

/// Page frame for auth and onboarding screens: centered column capped at phone width.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.outer,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: AppColors.canvas,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  SizedBox(
                    height: 56,
                    child: Row(children: [
                      if (showBack && Navigator.of(context).canPop())
                        IconButton(
                          tooltip: context.l10n.back,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                        ),
                      const Spacer(),
                      const Logo(),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(child: Text(title, style: serif(28, height: 1.08, tracking: -0.05))),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle!, style: sans(13, height: 1.45, color: AppColors.muted)),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum MessageTone { info, error, success }

class InlineMessage extends StatelessWidget {
  const InlineMessage(this.text, {super.key, this.tone = MessageTone.info});

  final String text;
  final MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (tone) {
      MessageTone.info => (AppColors.blueSoft, const Color(0xFF3D6273), Icons.info_outline_rounded),
      MessageTone.error => (AppColors.errorSoft, AppColors.error, Icons.error_outline_rounded),
      MessageTone.success => (AppColors.sageSoft, const Color(0xFF3F654A), Icons.check_circle_outline_rounded),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.md)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: AppIconSizes.md, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: sans(12, height: 1.4, color: fg))),
        ]),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscured ? context.l10n.showPassword : context.l10n.hidePassword,
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.muted),
        ),
      ),
    );
  }
}

/// Filled button that swaps its label for a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: motion(context, AppDurations.fast),
          child: loading
              ? const SizedBox(
                  key: ValueKey('spinner'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : Text(label, key: const ValueKey('label')),
        ),
      ),
    );
  }
}

const gap = SizedBox(height: AppSpacing.md);

void showSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
