import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:txt_docx/txt_docx.dart';

void main(List<String> argv) async {
  for (final f in argv) {
    final docx = '${p.basenameWithoutExtension(f)}.docx';
    final wf = File(docx);

    final file = File(f);
    await file.openRead()
        .transform(utf8.decoder)
        .transform(DocxEncoder(file.lengthSync()))
        .pipe(wf.openWrite());

    await wf.openRead()
        .transform(DocxDecoder(wf.lengthSync()))
        .transform(utf8.encoder)
        .pipe(File('$f.txt').openWrite());
  }
}
