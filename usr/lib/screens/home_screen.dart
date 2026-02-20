import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';
import '../services/file_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FileService _fileService = FileService();
  List<FileModel> _files = [];
  List<FileModel> _filteredFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _filter = '';
  double _storageUsed = 0.0;
  final double _storageMax = 99999.0; // 99999 yb, but using GB for simulation

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await _fileService.getFiles();
    setState(() {
      _files = files;
      _filteredFiles = files;
      _storageUsed = files.fold(0.0, (sum, file) => sum + file.size);
    });
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final fileSize = file.lengthSync().toDouble();

      if (fileSize > _storageMax * 1024 * 1024 * 1024) { // Simulate 99999 GB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Simulate upload with progress
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        setState(() {
          _uploadProgress = i / 100.0;
        });
      }

      // Rename to epoch milliseconds with random number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomNum = 1; // As requested: only 1 number
      final extension = fileName.split('.').last;
      final newName = '$timestamp$randomNum.$extension';

      final uploadedFile = FileModel(
        id: const Uuid().v4(),
        name: newName,
        originalName: fileName,
        path: file.path,
        size: fileSize,
        type: _getFileType(fileName),
        uploadDate: DateTime.now(),
      );

      await _fileService.saveFile(uploadedFile);
      await _loadFiles();

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded: $newName')),
      );
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['mp3', 'wav', 'aac'].contains(extension)) return 'audio';
    if (['mp4', 'avi', 'mov'].contains(extension)) return 'video';
    if (extension == 'gif') return 'gif';
    if (extension == 'm3u8') return 'm3u8';
    return 'other';
  }

  void _filterFiles(String query) {
    setState(() {
      _filter = query;
      _filteredFiles = _files.where((file) =>
        file.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
      _filteredFiles.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _downloadFile(FileModel file) async {
    // Mock download - in real app, would download from server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloaded: ${file.name}')),
    );
  }

  Future<void> _deleteFile(FileModel file) async {
    await _fileService.deleteFile(file.id);
    await _loadFiles();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted: ${file.name}')),
    );
  }

  void _playFile(FileModel file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files R Us'),
        backgroundColor: const Color(0xFFFF0000),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _pickAndUploadFile,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFFFF0000)],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black54,
              child: Column(
                children: [
                  Text(
                    'Storage: ${_storageUsed.toStringAsFixed(1)} B of ${_storageMax.toStringAsFixed(0)} YB',
                    style: const TextStyle(color: Colors.white),
                  ),
                  TextField(
                    onChanged: _filterFiles,
                    decoration: const InputDecoration(
                      labelText: 'Filter A-Z',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF0000)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            if (_isUploading)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF0000)),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredFiles.length,
                itemBuilder: (context, index) {
                  final file = _filteredFiles[index];
                  return ListTile(
                    leading: _buildThumbnail(file),
                    title: Text(
                      file.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${file.type} - ${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Color(0xFFFF0000)),
                          onPressed: () => _playFile(file),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () => _downloadFile(file),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteFile(file),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(FileModel file) {
    if (file.type == 'image' || file.type == 'gif') {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: const Icon(Icons.image, color: Colors.white),
        // In real app, would load actual thumbnail
      );
    } else if (file.type == 'video') {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: const Icon(Icons.video_file, color: Colors.white),
      );
    } else if (file.type == 'audio') {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: const Icon(Icons.audio_file, color: Colors.white),
      );
    } else {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey,
        child: const Icon(Icons.file_present, color: Colors.white),
      );
    }
  }
}