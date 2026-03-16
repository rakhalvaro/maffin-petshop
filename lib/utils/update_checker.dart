import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _channel =
      MethodChannel('com.example.maffin_petshop/installer');

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await _firestore
          .collection('config')
          .doc('app_config')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final latestVersion = data['latestVersion'] as String;
      final downloadUrl = data['downloadUrl'] as String;
      final changelog = data['changelog'] as String;
      final forceUpdate = data['forceUpdate'] as bool? ?? false;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            downloadUrl: downloadUrl,
            changelog: changelog,
            forceUpdate: forceUpdate,
          );
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String downloadUrl,
    required String changelog,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => _UpdateDialog(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        changelog: changelog,
        forceUpdate: forceUpdate,
      ),
    );
  }

  static Future<void> installApk(String apkPath) async {
    try {
      debugPrint('Calling installApk with path: $apkPath');
      await _channel.invokeMethod('installApk', {'path': apkPath});
      debugPrint('installApk called successfully');
    } catch (e) {
      debugPrint('Install error: $e');
    }
  }
}

class _UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String downloadUrl;
  final String changelog;
  final bool forceUpdate;

  const _UpdateDialog({
    required this.latestVersion,
    required this.downloadUrl,
    required this.changelog,
    required this.forceUpdate,
  });

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = '';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _statusText = 'Memeriksa izin...';
    });

    // Request izin install unknown apps
    if (Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        setState(() => _statusText = 'Meminta izin install...');
        final result = await Permission.requestInstallPackages.request();
        if (!result.isGranted) {
          setState(() {
            _isDownloading = false;
            _statusText = '';
          });
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Izin Diperlukan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                content: Text(
                  'Izin install aplikasi diperlukan untuk update. Aktifkan di Pengaturan.',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Batal',
                        style: GoogleFonts.poppins(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Buka Pengaturan',
                        style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    }

    setState(() {
      _statusText = 'Mengunduh...';
      _downloadProgress = 0.0;
    });

    try {
      debugPrint('Starting download from: ${widget.downloadUrl}');

      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await http.Client().send(request);
      final contentLength = response.contentLength ?? 0;

      debugPrint('Content length: $contentLength');

      final List<int> bytes = [];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = bytes.length / contentLength;
            final dlMB = (bytes.length / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (contentLength / 1024 / 1024).toStringAsFixed(1);
            _statusText = 'Mengunduh... $dlMB MB / $totalMB MB';
          });
        }
      }

      debugPrint('Download complete, total bytes: ${bytes.length}');

      // Simpan ke file
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/maffin_update.apk';
      final apkFile = File(apkPath);

      // Hapus file APK lama jika ada supaya tidak konflik dengan versi baru
      if (await apkFile.exists()) {
        await apkFile.delete();
        debugPrint('Old APK deleted');
      }

      await apkFile.writeAsBytes(bytes, flush: true);

      debugPrint('File written to: $apkPath');
      debugPrint('File exists: ${await apkFile.exists()}');
      debugPrint('File size: ${await apkFile.length()}');

      if (mounted) {
        setState(() => _statusText = 'Membuka installer...');
      }

      // Buka installer
      await UpdateChecker.installApk(apkPath);
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusText = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update,
                color: Colors.orange[700], size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            '🚀 Update Tersedia!',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Versi ${widget.latestVersion}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.changelog,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 16),
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: Colors.grey[200],
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: _isDownloading
          ? null
          : [
              if (!widget.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Nanti',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ),
              ElevatedButton(
                onPressed: _downloadAndInstall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Download',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ],
    );
  }
}