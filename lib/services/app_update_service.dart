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

    final DocumentSnapshot<Map<String, dynamic>> release = await _firestore
        .collection('app_updates')
        .doc('android')
        .get(const GetOptions(source: Source.server));
    if (!release.exists) return null;

    final Map<String, dynamic> data = release.data()!;
    final Object? publishedBuild = data['buildNumber'];
    final String apkUrl = data['apkUrl'] is String
        ? (data['apkUrl'] as String).trim()
        : '';
    final Uri? uri = Uri.tryParse(apkUrl);
    if (publishedBuild is! num ||
        publishedBuild <= installedBuild ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      return null;
    }

    return AppUpdateInfo(
      version: data['version'] is String ? data['version'] as String : '',
      buildNumber: publishedBuild.toInt(),
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
}
