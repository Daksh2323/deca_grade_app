import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  UpdateChecker({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  bool _checkInProgress = false;
  bool _dialogVisible = false;
  String? _dismissedVersion;

  Future<void> checkForUpdate(BuildContext context) async {
    if (_checkInProgress || _dialogVisible || !context.mounted) return;

    _checkInProgress = true;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final snapshot = await _firestore
          .collection('app_config')
          .doc('app_version')
          .get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return;

      final latestVersion = data['latest_version'];
      final downloadUrl = data['download_url'];
      if (latestVersion is! String || downloadUrl is! String) return;
      if (latestVersion == _dismissedVersion ||
          !isVersionNewer(latestVersion, packageInfo.version)) {
        return;
      }

      final uri = Uri.tryParse(downloadUrl.trim());
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        return;
      }
      if (!context.mounted) return;

      _dialogVisible = true;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            icon: Icon(
              Icons.system_update_alt_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            title: Text(
              'Update Available!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'A new version of DecaGrade (v$latestVersion) is ready. '
              'Please update to get the latest features and bug fixes.',
              style: theme.textTheme.bodyMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  _dismissedVersion = latestVersion;
                  Navigator.of(dialogContext).pop();
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    return;
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Update Now'),
              ),
            ],
          );
        },
      );
      _dismissedVersion = latestVersion;
    } catch (_) {
      return;
    } finally {
      _dialogVisible = false;
      _checkInProgress = false;
    }
  }

  static bool isVersionNewer(String latestVersion, String currentVersion) {
    final latest = _parseVersion(latestVersion);
    final current = _parseVersion(currentVersion);
    if (latest == null || current == null) return false;

    final length = latest.length > current.length
        ? latest.length
        : current.length;
    for (var index = 0; index < length; index++) {
      final latestPart = index < latest.length ? latest[index] : 0;
      final currentPart = index < current.length ? current[index] : 0;
      if (latestPart != currentPart) return latestPart > currentPart;
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final normalized = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    if (!RegExp(r'^\d+(?:\.\d+)*$').hasMatch(normalized)) return null;
    return normalized.split('.').map(int.parse).toList();
  }
}
