class Quizz {
  final String name;
  final List<String> tags;
  final String icon;
  final String fileName;
  final String version;

  Quizz({
    required this.name,
    required this.tags,
    required this.icon,
    required this.fileName,
    required this.version,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
      'icon': icon,
      'file_name': fileName,
      'version': version,
    };
  }

  static Quizz fromJson(Map<String, dynamic> json) {
    return Quizz(
      name: json["name"],
      tags: json["tags"] is List<dynamic>
          ? (json["tags"] as List<dynamic>).cast<String>()
          : <String>[],
      icon: json["icon"] ?? "0xe877",
      fileName: json["file_name"],
      version: json["version"],
    );
  }
}
