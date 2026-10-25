import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
  });

  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;
}

class AppUpdateService {
  AppUpdateService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const MethodChannel _appInfo = MethodChannel('gameset/app_info');
  final FirebaseFirestore _firestore;

  Future<AppUpdateInfo?> checkForAndroidUpdate() async {
    final Map<Object?, Object?>? installed = await _appInfo
        .invokeMapMethod<Object?, Object?>('getVersion');
    if (installed == null) {
      throw StateError('Could not read the installed app version.');
    }
    final int installedBuild = (installed['buildNumber'] as num).toInt();
    final String installedVersion = installed['version'] is String
        ? installed['version'] as String
        : '';

    final DocumentSnapshot<Map<String, dynamic>> release = await _firestore
        .collection('app_updates')
        .doc('android')
        .get(const GetOptions(source: Source.server));
    if (!release.exists) return null;

    final Map<String, dynamic> data = release.data()!;
    final Object? publishedBuild = data['buildNumber'];
    final String publishedVersion = data['version'] is String
        ? (data['version'] as String).trim()
        : '';
    final String apkUrl = data['apkUrl'] is String
        ? (data['apkUrl'] as String).trim()
        : '';
    final Uri? uri = Uri.tryParse(apkUrl);

    // A published release reaches "Check for Updates" when it is a higher
    // build than the installed app, or when its release label is genuinely
    // newer than the installed version name — admin uploads must surface here
    // even if the release counter lags the version code baked into installed
    // builds. Labels compare numerically so "1.2" and "1.2.0" count as the
    // same release rather than as a permanently available update.
    final bool newerBuild =
        publishedBuild is num && publishedBuild > installedBuild;
    final bool newerVersion =
        _isNewerVersion(publishedVersion, installedVersion) ?? false;
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return null;
    }
    if (!newerBuild && !newerVersion) return null;

    return AppUpdateInfo(
      version: publishedVersion,
      buildNumber: publishedBuild is num ? publishedBuild.toInt() : 0,
      apkUrl: apkUrl,
      releaseNotes: data['releaseNotes'] is String
          ? data['releaseNotes'] as String
          : '',
    );
  }

  /// Reports the build running on this device to `app_versions/android` so
  /// the admin app can publish a build number that is actually higher than
  /// what users have installed — otherwise "Check for Updates" never offers
  /// the release even though its notification was delivered.
  Future<int?> reportInstalledBuild() async {
    final Map<Object?, Object?>? installed = await _appInfo
        .invokeMapMethod<Object?, Object?>('getVersion');
    if (installed == null) return null;
    final int buildNumber = (installed['buildNumber'] as num).toInt();
    await _firestore
        .collection('app_versions')
        .doc('android')
        .set(<String, Object>{
          'lastSeenBuild': buildNumber,
          'version': installed['version'] is String
              ? installed['version'] as String
              : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    return buildNumber;
  }

  /// Compares dotted release labels numerically: `1.2` equals `1.2.0`, `1.3`
  /// beats `1.2.9`. Returns null when either side is missing or not numeric,
  /// leaving the build-number check to decide on its own.
  static bool? _isNewerVersion(String published, String installed) {
    final List<int>? expected = _parseVersion(published);
    final List<int>? current = _parseVersion(installed);
    if (expected == null || current == null) return null;
    final int length = expected.length > current.length
        ? expected.length
        : current.length;
    for (int index = 0; index < length; index++) {
      final int publishedPart = index < expected.length ? expected[index] : 0;
      final int installedPart = index < current.length ? current[index] : 0;
      if (publishedPart != installedPart) {
        return publishedPart > installedPart;
      }
    }
    return false;
  }

  static List<int>? _parseVersion(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final List<int> parts = <int>[];
    for (final String part in trimmed.split('.')) {
      final int? number = int.tryParse(part);
      if (number == null) return null;
      parts.add(number);
    }
    return parts;
  }
}
