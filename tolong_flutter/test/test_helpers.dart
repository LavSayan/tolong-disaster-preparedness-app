import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tolong_flutter/core/clock.dart';
import 'package:tolong_flutter/core/database/app_database.dart';
import 'package:tolong_flutter/features/sync/application/sync_engine.dart';
import 'package:tolong_flutter/features/sync/data/sync_remote.dart';
import 'package:tolong_flutter/features/sync/domain/sync_types.dart';
import 'package:tolong_flutter/features/tol/data/tol_service.dart';
import 'package:tolong_flutter/features/tol/domain/tol_models.dart';
import 'package:tolong_flutter/core/storage/secure_vault.dart';
import 'package:tolong_flutter/features/auth/data/auth_repository.dart';
import 'package:tolong_flutter/features/guidebook/data/guidebook_repository.dart';
import 'package:tolong_flutter/features/household/domain/models.dart';
import 'package:tolong_flutter/features/safe_places/data/evacuation_center_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/location_service.dart';
import 'package:tolong_flutter/features/safe_places/data/offline_map_service.dart';
import 'package:tolong_flutter/features/safe_places/data/qc_area_repository.dart';
import 'package:tolong_flutter/features/safe_places/data/route_service.dart';
import 'package:tolong_flutter/features/safe_places/domain/evacuation_center.dart';
import 'package:tolong_flutter/features/safe_places/presentation/map_view.dart';
import 'package:tolong_flutter/main.dart';

/// Stands in for MapLibre, which needs a real platform view. Records camera commands
/// and renders one tappable chip per center so tests can "tap a marker".
class FakeMap implements MapHandle {
  final calls = <String>[];

  @override
  Future<void> focus(GeoPoint point, {double zoom = 15}) async => calls.add('focus ${point.lat},${point.lng}');

  @override
  Future<void> showBounds(GeoBounds bounds) async => calls.add('bounds');

  @override
  Future<void> zoomIn() async => calls.add('zoomIn');

  @override
  Future<void> zoomOut() async => calls.add('zoomOut');

  MapViewBuilder get builder => (
          {required centers,
          required selectedId,
          required user,
          required route,
          required outline,
          required onCenterTap,
          required onReady,
          hazardGroup,
          onHazardDrawState}) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onReady(this));
        // Padded so the fake "pins" don't sit under the real map control buttons on the right.
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 36, 64, 8),
          child: Wrap(children: [
            for (final c in centers)
              TextButton(
                  key: ValueKey('marker-${c.id}'), onPressed: () => onCenterTap(c.id), child: Text('pin ${c.id}')),
            if (user != null) const Text('user-dot'),
            if (route != null) Text('route-line ${route.length}'),
            if (outline != null) const Text('qc-outline'),
          ]),
        );
      };
}

class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  LocationResult result;
  int settingsOpened = 0;
  final positions = StreamController<GeoPoint>.broadcast();

  @override
  Future<LocationResult> current() async => result;

  @override
  Stream<GeoPoint> watch() => positions.stream;

  @override
  Future<void> openAppSettings() async => settingsOpened++;

  @override
  Future<void> openLocationSettings() async => settingsOpened++;
}

final fixedNow = DateTime(2026, 10, 18, 9, 30);

/// Boots the real app on a 360x780 dp phone with in-memory storage.
Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {'language': 'en'},
  MemoryVault? vault,
  AuthRepository? auth,
  FakeMap? map,
  LocationService? location,
  RouteService? routes,
  OfflineMapService? offline,
  SyncRemote? syncRemote,
  AppDatabase? database,
  OnlineTolService? tol,
  Size logicalSize = const Size(360, 780),
  bool failCenters = false,
  bool failGuidebook = false,
}) async {
  tester.view.physicalSize = logicalSize * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // OS-level "remove animations": stops the looping Tol button so pumpAndSettle can settle,
  // without touching the in-app reduced-motion setting that tests toggle.
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(instance),
      secureVaultProvider.overrideWithValue(vault ?? MemoryVault()),
      clockProvider.overrideWithValue(() => fixedNow),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
      mapViewBuilderProvider.overrideWithValue((map ?? FakeMap()).builder),
      // rootBundle caches its futures across tests, which never complete in a later test's fake clock.
      evacuationCentersProvider.overrideWith((ref) async => failCenters
          ? throw const FormatException('test: unreadable centers file')
          : EvacuationCenterRepository.parse(File(EvacuationCenterRepository.assetPath).readAsStringSync())),
      qcBoundaryProvider.overrideWith(
          (ref) async => QcAreaRepository.parseBoundary(File(QcAreaRepository.boundaryPath).readAsStringSync())),
      barangaysProvider.overrideWith(
          (ref) async => QcAreaRepository.parseBarangays(File(QcAreaRepository.barangaysPath).readAsStringSync())),
      guidebookProvider.overrideWith((ref) async => failGuidebook
          ? throw const FormatException('test: unreadable guidebook')
          : GuidebookRepository.parse(File(GuidebookRepository.assetPath).readAsStringSync())),
      offlineMapServiceProvider.overrideWithValue(offline ?? FakeOfflineMapService()),
      syncRemoteProvider.overrideWithValue(syncRemote),
      appDatabaseProvider.overrideWith((ref) {
        final db = database ?? AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
      connectivityProvider.overrideWithValue(const Stream.empty()),
      onlineTolServiceProvider.overrideWithValue(tol),
      locationServiceProvider.overrideWithValue(location ?? FakeLocationService(const LocationDenied())),
      routeServiceProvider
          .overrideWithValue(routes ?? FakeRouteService(const RouteFailed(RouteErrorCode.notConfigured))),
    ],
    child: const TolongApp(),
  ));
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
  return instance;
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> enterGuestMode(WidgetTester tester) async {
  await scrollTo(tester, find.text('Emergency access without an account'));
  await tester.tap(find.text('Emergency access without an account'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue without account'));
  await tester.pumpAndSettle();
}

/// In-memory stand-in for the Supabase `sync_records` table, applying the same
/// "newer change wins" rule as the `sync_push` SQL function.
class FakeSyncRemote implements SyncRemote {
  final rows = <String, RemoteRecord>{};
  final pushed = <RemoteRecord>[];
  SyncFailure? failNext;
  var serverClock = DateTime.utc(2026, 10, 18);

  @override
  Future<void> push(List<RemoteRecord> records) async {
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    for (final r in records) {
      pushed.add(r);
      final key = '${r.entity.name}/${r.recordId}';
      final existing = rows[key];
      if (existing == null || !existing.clientModifiedAt.isAfter(r.clientModifiedAt)) {
        serverClock = serverClock.add(const Duration(seconds: 1));
        rows[key] = RemoteRecord(
          entity: r.entity,
          recordId: r.recordId,
          data: r.data,
          deleted: r.deleted,
          clientModifiedAt: r.clientModifiedAt,
          serverUpdatedAt: serverClock,
        );
      }
    }
  }

  /// Simulates a change made on another device.
  void seed(RemoteRecord r) {
    serverClock = serverClock.add(const Duration(seconds: 1));
    rows['${r.entity.name}/${r.recordId}'] = RemoteRecord(
      entity: r.entity,
      recordId: r.recordId,
      data: r.data,
      deleted: r.deleted,
      clientModifiedAt: r.clientModifiedAt,
      serverUpdatedAt: serverClock,
    );
  }

  @override
  Future<List<RemoteRecord>> pull({DateTime? since}) async => [
        for (final r in rows.values)
          if (since == null || r.serverUpdatedAt!.isAfter(since)) r,
      ]..sort((a, b) => a.serverUpdatedAt!.compareTo(b.serverUpdatedAt!));
}

class FakeTolService implements OnlineTolService {
  FakeTolService({this.reply = 'Pack water, food and a flashlight.'});

  String reply;
  TolFailure? failNext;
  final calls = <({List<Map<String, String>> conversation, String language, Map<String, Object?>? context})>[];

  @override
  Future<String> ask({
    required List<Map<String, String>> conversation,
    required String language,
    required TolFacts facts,
    Map<String, Object?>? context,
  }) async {
    calls.add((conversation: conversation, language: language, context: context));
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
    return reply;
  }
}

class FakeOfflineMapService implements OfflineMapService {
  OfflineMapStatus current = const OfflineNotDownloaded();
  final progress = StreamController<OfflineMapStatus>();
  GeoBounds? requestedBounds;
  int deletes = 0;

  @override
  Future<OfflineMapStatus> status() async => current;

  @override
  Stream<OfflineMapStatus> download(GeoBounds bounds) {
    requestedBounds = bounds;
    return progress.stream;
  }

  @override
  Future<void> delete() async {
    deletes++;
    current = const OfflineNotDownloaded();
  }
}

class FakeRouteService implements RouteService {
  FakeRouteService(this.result);

  RouteResult result;
  final requests = <(GeoPoint, GeoPoint, RouteProfile)>[];

  @override
  Future<RouteResult> route(GeoPoint from, GeoPoint to, RouteProfile profile) async {
    requests.add((from, to, profile));
    return result;
  }
}

class FakeAuthRepository implements AuthRepository {
  UserProfile? synced;
  bool deleted = false;

  @override
  bool get isConfigured => true;

  @override
  AuthUserInfo? get currentUser => deleted
      ? null
      : const AuthUserInfo(
          id: 'user-1',
          email: 'maria@example.com',
          fullName: 'Maria Santos',
          age: 34,
          barangay: 'Batasan Hills',
        );

  @override
  Stream<AuthEvent> get changes => const Stream.empty();

  @override
  Future<void> syncProfile(UserProfile profile) async => synced = profile;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async => deleted = true;

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String barangay,
    required String languageCode,
  }) async =>
      SignUpResult.signedIn;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}
}
