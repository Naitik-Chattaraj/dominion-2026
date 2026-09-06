
import "dart:io";

void main() {
  final file = File("lib/services/news_service.dart");
  String content = file.readAsStringSync();
  
  // Replace html cleaning regex with entity stripping
  content = content.replaceAll(
    "final cleanDesc = description.replaceAll(RegExp(r\x27<[^>]*>\x27), \x27\x27).trim();",
    "String cleanDesc = description.replaceAll(RegExp(r\x27<[^>]*>\x27), \x27\x27);\n    cleanDesc = cleanDesc.replaceAll(\x27&nbsp;\x27, \x27 \x27).replaceAll(\x27&amp;\x27, \x27&\x27).replaceAll(\x27&quot;\x27, \x27\"\x27).replaceAll(\x27&#39;\x27, \x27\x27\x27\x27).replaceAll(RegExp(r\x27\\s+\x27), \x27 \x27).trim();"
  );

  file.writeAsStringSync(content);
}

