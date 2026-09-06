
import "dart:io";

void main() {
  final file = File("lib/screens/news/news_feed_screen.dart");
  String content = file.readAsStringSync();
  content = content.replaceFirst("EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 100.0)", "EdgeInsets.fromLTRB(20.0.w, 0.0, 20.0.w, 160.0.h)");
  file.writeAsStringSync(content);
}

