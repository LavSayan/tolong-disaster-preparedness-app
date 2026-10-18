import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/guidebook.dart';

/// The guidebook ships inside the app, so it is always available offline.
class GuidebookRepository {
  GuidebookRepository(this._bundle);

  final AssetBundle _bundle;

  static const assetPath = 'assets/guidebook/guidebook.json';

  Future<List<GuideCategory>> load() async => parse(await _bundle.loadString(assetPath));

  static List<GuideCategory> parse(String raw) => [
        for (final c in (jsonDecode(raw) as Map<String, Object?>)['categories'] as List)
          GuideCategory.fromJson(c as Map<String, Object?>),
      ];
}

final guidebookRepositoryProvider = Provider((ref) => GuidebookRepository(rootBundle));

final guidebookProvider = FutureProvider<List<GuideCategory>>((ref) => ref.watch(guidebookRepositoryProvider).load());
