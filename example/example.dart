import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:txt_docx/txt_docx.dart';

void main(List<String> argv) async {
  for (final f in argv) {
    final docx = '${p.basenameWithoutExtension(f)}.docx';

    await File(f)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .transform(DocxEncoder())
        .pipe(File(docx).openWrite());

    final wf = File(docx);
    await DocxDecoder()
        .open(wf.openSync())
        .transform(utf8.encoder)
        .pipe(File('$docx.txt').openWrite());
  }
}
