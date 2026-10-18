import '../l10n/generated/app_localizations.dart';

/// Form validators. Each returns a localized message, or null when the value is valid.
class Validators {
  Validators(this.l);

  final AppLocalizations l;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phMobile = RegExp(r'^(\+63|0)9\d{9}$');
  static final _metroLandline = RegExp(r'^(\+632|02)?\d{8}$');

  String? required(String? value, String field) => (value == null || value.trim().isEmpty) ? l.valRequired(field) : null;

  String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.valNameRequired;
    if (v.length > 120) return l.valNameTooLong;
    return null;
  }

  String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.valEmailRequired;
    if (!_email.hasMatch(v)) return l.valEmailInvalid;
    return null;
  }

  String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return l.valPasswordShort;
    if (!RegExp('[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return l.valPasswordMix;
    return null;
  }

  String? loginPassword(String? value) => (value == null || value.isEmpty) ? l.valPasswordRequired : null;

  String? Function(String?) confirmPassword(String Function() original) =>
      (value) => value != original() ? l.valPasswordMismatch : null;

  String? age(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.valAgeRequired;
    final n = int.tryParse(v);
    if (n == null || n < 1 || n > 120) return l.valAgeRange;
    return null;
  }

  String? phone(String? value) {
    final v = normalizePhone(value ?? '');
    if (v.isEmpty) return l.valPhoneRequired;
    if (!_phMobile.hasMatch(v) && !_metroLandline.hasMatch(v)) return l.valPhoneInvalid;
    return null;
  }

  String? positiveNumber(String? value) {
    final n = parseNumber(value);
    return (n == null || n <= 0) ? l.quantityInvalid : null;
  }

  String? optionalPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = parseNumber(value);
    return (n == null || n <= 0) ? l.numberInvalid : null;
  }

  static double? parseNumber(String? value) => double.tryParse((value ?? '').trim().replaceAll(',', ''));

  static String normalizePhone(String value) => value.replaceAll(RegExp(r'[\s\-()]'), '');
}
