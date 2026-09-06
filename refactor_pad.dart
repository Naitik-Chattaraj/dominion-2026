
import "dart:io";

void main() {
  final file = File("lib/screens/home/riskgrid_home_screen.dart");
  String content = file.readAsStringSync();
  content = content.replaceFirst("SizedBox(height: 130.h),", "SizedBox(height: 170.h),");
  file.writeAsStringSync(content);
}

