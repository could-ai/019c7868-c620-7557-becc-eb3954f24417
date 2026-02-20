import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';

class FileService {
  static const String _filesKey = 'uploaded_files';

  Future<List<FileModel>> getFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = prefs.getStringList(_filesKey) ?? [];
    return filesJson.map((json) => FileModel.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveFile(FileModel file) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await getFiles();
    files.add(file);
    final filesJson = files.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_filesKey, filesJson);
  }

  Future<void> deleteFile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final files = await getFiles();
    files.removeWhere((file) => file.id == id);
    final filesJson = files.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_filesKey, filesJson);
  }
}