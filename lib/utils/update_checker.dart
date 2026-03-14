import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cek apakah ada update tersedia
  /// Return true jika ada update, false jika tidak
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Ambil info versi app yang terinstall
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Ambil config dari Firestore
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

      // Bandingkan versi
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
      // Gagal cek update = tidak masalah, lanjut saja
    }
  }

  /// Bandingkan versi, return true jika latestVersion > currentVersion
  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  /// Tampilkan dialog update
  static void _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String downloadUrl,
    required String changelog,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Tidak bisa ditutup kalau force update
      builder: (context) => _UpdateDialog(
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        changelog: changelog,
        forceUpdate: forceUpdate,
      ),
    );
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
      _statusText = 'Memulai download...';
    });

    try {
      // Buat HTTP request dengan stream supaya bisa track progress
      final request = http.Request('GET', Uri.parse(widget.downloadUrl));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final apkPath = '${tempDir.path}/maffin_update.apk';
      final apkFile = File(apkPath);

      int downloaded = 0;
      final sink = apkFile.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            setState(() {
              _downloadProgress = downloaded / contentLength;
              final downloadedMB = (downloaded / 1024 / 1024).toStringAsFixed(1);
              final totalMB = (contentLength / 1024 / 1024).toStringAsFixed(1);
              _statusText = 'Mengunduh... $downloadedMB MB / $totalMB MB';
            });
          }
        },
        onDone: () async {
          await sink.close();
          setState(() {
            _statusText = 'Download selesai, membuka installer...';
          });
          // Buka APK installer
          await OpenFilex.open(apkPath);
        },
        onError: (e) async {
          await sink.close();
          setState(() {
            _isDownloading = false;
            _statusText = 'Download gagal, coba lagi';
          });
        },
        cancelOnError: true,
      ).asFuture();
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusText = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon & judul
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.system_update, color: Colors.orange[700], size: 36),
          ),
          SizedBox(height: 12),
          Text(
            '🚀 Update Tersedia!',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Versi ${widget.latestVersion}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),

          // Changelog
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.changelog,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
          SizedBox(height: 16),

          // Progress bar (muncul saat download)
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                minHeight: 10,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _statusText,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: _isDownloading
          ? null // Sembunyikan tombol saat download
          : [
              if (!widget.forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Nanti',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
              ElevatedButton(
                onPressed: _downloadAndInstall,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Download',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
    );
  }
}