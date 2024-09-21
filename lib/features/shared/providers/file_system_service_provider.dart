import 'dart:io';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:path_provider/path_provider.dart';

const kExternalStorageDir = '/storage/emulated/0/';
const kDownloadsDir = 'Downloads';
const kDocumentsDir = 'Documents';

final fileSystemProvider =
    Provider.autoDispose<DeviceIO>((_) => _FileSystemService());

abstract class DeviceIO {
  Future<String> writeToDocuments(
    String content, {
    String? fileName,
  });

  Future<String> readFromDocuments({
    String? filePath,
  });

  Future<String?> findFileInDocuments({
    required String query,
  });
}

class _FileSystemService implements DeviceIO {
  @override
  Future<String> writeToDocuments(
    String content, {
    String? fileName,
  }) async {
    final directory = await _getDocumentsDir();
    fileName ??= '${DateTime.now().toIso8601String().split('T').first}.txt';
    final file = File('${directory.path}/$fileName');
    final res = await file.writeAsString(content);
    logger.d('[DeviceIO] File written to: ${res.path}');
    return res.path;
  }

  @override
  Future<String?> findFileInDocuments({
    required String query,
  }) async {
    final directory = await _getDocumentsDir();
    final files = directory.listSync();
    for (final file in files) {
      if (file.path.contains(query)) {
        return file.path;
      }
    }
    return null;
  }

  @override
  Future<String> readFromDocuments({String? filePath}) async {
    final file = File(filePath!);
    final content = await file.readAsString();
    return content;
  }

  Future<Directory> _getDocumentsDir() async {
    if (Platform.isAndroid) {
      final documents = Directory('$kExternalStorageDir/$kDocumentsDir');
      final downloads = Directory('$kExternalStorageDir/$kDownloadsDir');
      if (documents.existsSync()) {
        return documents;
      }
      if (downloads.existsSync()) {
        return downloads;
      }
      return getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
