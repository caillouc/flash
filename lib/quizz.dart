class Quizz {
  final String name;
  final List<String> tags;
  final String icon;
  final String fileName;
  final String version;
  final String imageFolder; // Optional folder for private quiz images

  Quizz({
    required this.name,
    required this.tags,
    required this.icon,
    required this.fileName,
    required this.version,
    required this.imageFolder,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tags': tags,
      'icon': icon,
      'file_name': fileName,
      'version': version,
      'image_folder': imageFolder,
    };
  }

  static Quizz fromJson(Map<String, dynamic> json) {
    String imageFolder = "";
    if (json.containsKey("image_folder") && json["image_folder"] != null) {
      // If image_folder contains a '/' at the end, remove it
      imageFolder = json["image_folder"];
      if (imageFolder.endsWith('/')) {
        imageFolder = imageFolder.substring(0, imageFolder.length - 1);
      }
    }
    return Quizz(
      name: json["name"],
      tags: json["tags"] is List<dynamic>
          ? (json["tags"] as List<dynamic>).cast<String>()
          : <String>[],
      icon: json["icon"] ?? "0xe877",
      fileName: json["file_name"],
      version: json["version"],
      imageFolder: imageFolder,
    );
  }
}
