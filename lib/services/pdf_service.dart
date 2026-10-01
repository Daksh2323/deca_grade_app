import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfService {
  final Dio _dio = Dio();

  /// Download PDF and return local file path.
  Future<String?> downloadPdf({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      final trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) {
        throw ArgumentError('PDF URL is missing');
      }

      final uri = Uri.tryParse(trimmedUrl);
      if (uri == null ||
          !uri.isAbsolute ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        throw ArgumentError('Invalid PDF URL');
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          return filePath;
        }
        await file.delete();
      }

      final bytes = await _downloadPdfBytes(trimmedUrl, onProgress);
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists() || await file.length() == 0) {
        return null;
      }

      return filePath;
    } on DioException catch (e, stack) {
      print('PdfService download error: ${e.message}');
      print('Request URI: ${e.requestOptions.uri}');
      print(stack);
      return null;
    } catch (e, stack) {
      print('PdfService download error: $e');
      print(stack);
      return null;
    }
  }

  Future<Uint8List?> _downloadPdfBytes(
    String url,
    Function(int received, int total)? onProgress,
  ) async {
    final parsedUrl = Uri.parse(url);
    final urls = <String>[url];
    if (parsedUrl.host == 'ncert.nic.in') {
      urls.add(parsedUrl.replace(host: 'www.ncert.nic.in').toString());
    } else if (parsedUrl.host == 'www.ncert.nic.in') {
      urls.add(parsedUrl.replace(host: 'ncert.nic.in').toString());
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      for (final candidateUrl in urls) {
        try {
          final response = await _dio.get<Uint8List>(
            candidateUrl,
            onReceiveProgress: onProgress,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(minutes: 5),
              sendTimeout: const Duration(minutes: 2),
              followRedirects: true,
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: {
                'Accept': 'application/pdf,*/*',
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
                'Connection': 'close',
              },
            ),
          );

          final bytes = response.data;
          if (bytes != null && bytes.isNotEmpty) {
            return bytes;
          }
        } on DioException catch (e) {
          print(
            'PdfService attempt ${attempt + 1} failed for $candidateUrl: ${e.message}',
          );
        } catch (e) {
          print(
            'PdfService attempt ${attempt + 1} failed for $candidateUrl: $e',
          );
        }
      }

      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    print('PdfService bytes download failed after retries: $url');
    return null;
  }

  /// Save PDF to device downloads folder.
  Future<String?> saveToDevice({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return null;
        }
      }

      Directory downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download/DecaGrade');
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/$fileName';

      await _dio.download(url, filePath, onReceiveProgress: onProgress);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// Get file size in MB.
  Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }

  /// Format file size for display.
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clean up cached PDFs older than 7 days.
  Future<void> cleanCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File && file.path.endsWith('.pdf')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          if (age.inDays > 7) {
            await file.delete();
          }
        }
      }
    } catch (_) {
      // Ignore cache cleanup failures so the viewer itself can stay resilient.
    }
  }
}
