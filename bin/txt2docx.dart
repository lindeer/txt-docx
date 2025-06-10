import 'dart:io' show File;

import 'package:path/path.dart' as p;
import 'package:txt_docx/txt_docx.dart' show DocxWriter;

void main(List<String> argv) async {
  final futures = argv.map((f) {
    final docx = '${p.basenameWithoutExtension(f)}.docx';
    final writer = DocxWriter();
    return writer.writeStream(File(f).openRead(), docx);
  });
  await Future.wait(futures);
}
