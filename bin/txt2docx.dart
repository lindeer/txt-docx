import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show File;

import 'package:path/path.dart' as p;
import 'package:txt_docx/src/docx_encoder.dart' show DocxEncoder;

void main(List<String> argv) async {
  final futures = argv.map((f) {
    final docx = '${p.basenameWithoutExtension(f)}.docx';
    return File(f)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .transform(DocxEncoder())
        .pipe(File(docx).openWrite());
  });
  await Future.wait(futures);
}
