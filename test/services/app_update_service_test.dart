import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_set/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel appInfo = MethodChannel('gameset/app_info');

  void mockInstalled({required int buildNumber, required String version}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appInfo, (MethodCall call) async {
          if (call.method == 'getVersion') {
            return <String, Object>{
              'buildNumber': buildNumber,
              'version': version,
            };
          }
          return null;
        });
  }

  Future<FakeFirebaseFirestore> firestoreWithRelease({
    required Object buildNumber,
    required String version,
    String apkUrl = 'https://example.com/GameSet.apk',
  }) async {
    final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
    await firestore.collection('app_updates').doc('android').set({
      'buildNumber': buildNumber,
      'version': version,
      'apkUrl': apkUrl,
      'releaseNotes': 'fixes',
    });
    return firestore;
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appInfo, null);
  });

  group('checkForAndroidUpdate', () {
    test('offers a release whose build number is higher', () async {
      mockInstalled(buildNumber: 2002, version: '1.2.0');
      final FakeFirebaseFirestore firestore = await firestoreWithRelease(
        buildNumber: 2003,
        version: '1.2.0',
      );

      final AppUpdateInfo? update = await AppUpdateService(
        firestore: firestore,
      ).checkForAndroidUpdate();

      expect(update, isNotNull);
      expect(update!.buildNumber, 2003);
    });

    test(
      'stays silent when the labels are equal but written differently',
      () async {
        // "1.2" published against a "1.2.0" install must NOT be offered, or the
        // dialog reappears forever after every install.
        mockInstalled(buildNumber: 2002, version: '1.2.0');
        final FakeFirebaseFirestore firestore = await firestoreWithRelease(
          buildNumber: 1,
          version: '1.2',
        );

        expect(
          await AppUpdateService(firestore: firestore).checkForAndroidUpdate(),
          isNull,
        );
      },
    );

    test('offers a release whose label is genuinely newer', () async {
      mockInstalled(buildNumber: 2002, version: '1.2.9');
      final FakeFirebaseFirestore firestore = await firestoreWithRelease(
        buildNumber: 1,
        version: '1.3',
      );

      expect(
        await AppUpdateService(firestore: firestore).checkForAndroidUpdate(),
        isNotNull,
      );
    });

    test('ignores a release whose label is older', () async {
      mockInstalled(buildNumber: 2002, version: '2.0.0');
      final FakeFirebaseFirestore firestore = await firestoreWithRelease(
        buildNumber: 1,
        version: '1.3',
      );

      expect(
        await AppUpdateService(firestore: firestore).checkForAndroidUpdate(),
        isNull,
      );
    });

    test('rejects an apk url that is not https', () async {
      mockInstalled(buildNumber: 1, version: '1.0.0');
      final FakeFirebaseFirestore firestore = await firestoreWithRelease(
        buildNumber: 5,
        version: '1.2',
        apkUrl: 'http://example.com/GameSet.apk',
      );

      expect(
        await AppUpdateService(firestore: firestore).checkForAndroidUpdate(),
        isNull,
      );
    });
  });

  group('reportInstalledBuild', () {
    test('writes the running build to app_versions/android', () async {
      mockInstalled(buildNumber: 2003, version: '1.2.0');
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();

      final int? reported = await AppUpdateService(
        firestore: firestore,
      ).reportInstalledBuild();

      expect(reported, 2003);
      final Map<String, dynamic>? data =
          (await firestore.collection('app_versions').doc('android').get())
              .data();
      expect(data?['lastSeenBuild'], 2003);
      expect(data?['version'], '1.2.0');
    });
  });
}
