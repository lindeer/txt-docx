import 'dart:async' show StreamTransformerBase;
import 'dart:convert' show LineSplitter, utf8;

import 'package:zip2/zip2.dart' show zip;

import 'docx_const.dart' as c;

final class DocxEncoder extends StreamTransformerBase<String, List<int>> {
  const DocxEncoder();

  @override
  Stream<List<int>> bind(Stream<String> stream) {
    final wordDoc = stream
        .transform(LineSplitter())
        .transform(_DocxXmlEncoder())
        .transform(utf8.encoder);
    final archive = c.createDocxArchive(wordDoc);
    return zip.encoder.zip(archive);
  }
}

final class _DocxXmlEncoder extends StreamTransformerBase<String, String> {
  const _DocxXmlEncoder();

  @override
  Stream<String> bind(Stream<String> lines) async* {
    yield '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>';
    await for (final line in lines) {
      yield '<w:p><w:r><w:t>';
      yield line
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
      yield '</w:t></w:r></w:p>';
    }
    yield '</w:body></w:document>';
  }
}
