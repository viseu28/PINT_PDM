import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';

class FileDownloader {
  /// Faz o download de um arquivo para a pasta Downloads do Android.
  /// Retorna o caminho do arquivo salvo ou lança uma exceção.
  static Future<String> downloadFileToDownloads(String url, String fileName) async {
    // Solicitar permissão de armazenamento
    if (Platform.isAndroid) {
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  final status = await Permission.manageExternalStorage.status;

  if (!status.isGranted) {
    throw Exception('Permissão MANAGE_EXTERNAL_STORAGE negada');
  }
}


    // Obter diretório de downloads compatível com Android 10+
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      final downloadsPath = await ExternalPath.getExternalStoragePublicDirectory("Download");
      downloadsDir = Directory(downloadsPath);
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    final savePath = '${downloadsDir.path}/$fileName';
    final dio = Dio();
    final response = await dio.download(url, savePath);
    if (response.statusCode == 200) {
      return savePath;
    } else {
      throw Exception('Falha ao baixar arquivo: ${response.statusCode}');
    }
  }
}
