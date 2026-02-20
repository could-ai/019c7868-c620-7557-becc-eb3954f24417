class FileModel {
  final String id;
  final String name;
  final String originalName;
  final String path;
  final double size;
  final String type;
  final DateTime uploadDate;

  FileModel({
    required this.id,
    required this.name,
    required this.originalName,
    required this.path,
    required this.size,
    required this.type,
    required this.uploadDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'originalName': originalName,
      'path': path,
      'size': size,
      'type': type,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      name: json['name'],
      originalName: json['originalName'],
      path: json['path'],
      size: json['size'],
      type: json['type'],
      uploadDate: DateTime.parse(json['uploadDate']),
    );
  }
}