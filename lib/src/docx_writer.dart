import 'dart:async' show StreamTransformerBase;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:io' show Directory, File;

import 'package:archive/archive_io.dart' as ar;

import 'docx_const.dart' as c;

/// [DocxEncoder] could not be available now, 'case [AbstractFileHandle] of
/// archive could not be implemented as async way.
class DocxWriter {
  Future<void> writeLines(List<String> lines, String file) {
    return _write(Stream.fromIterable(lines), file);
  }

  Future<void> writeStream(Stream<List<int>> stream, String file) {
    final lines = stream.transform(utf8.decoder).transform(LineSplitter());
    return _write(lines, file);
  }

  Future<void> _write(Stream<String> lines, String file) async {
    final t1 = DateTime.now().millisecondsSinceEpoch;
    final docFile = await _createDocFile(lines);
    final t2 = DateTime.now().millisecondsSinceEpoch;
    print("Write temp doc xml file: '$docFile', ${t2 - t1} ms.");

    /// We have to create this intermediate file instead of a stream, 'cause
    /// [ar.InputStream] needs [fileLength] param, which we could not get it.
    final archive = c.createDocxArchive(docFile);
    final t3 = DateTime.now().millisecondsSinceEpoch;
    print("Creating archive file: ${t3 - t2} ms.");
    await _writeZipFile(archive, file);
    final t4 = DateTime.now().millisecondsSinceEpoch;
    print("Write docx file '$file': ${t4 - t3} ms.");
  }

  Future<String> _createDocFile(Stream<String> lines) async {
    final file = '${Directory.systemTemp.path}/word_document_'
        '${DateTime.now().microsecondsSinceEpoch}.xml';
    final wordDoc = lines.transform(_DocXmlTransformer());
    final tmp = File(file);
    await wordDoc.transform(utf8.encoder).pipe(tmp.openWrite());
    return file;
  }

  Future<void> _writeZipFile(ar.Archive archive, String file) async {
    final output = ar.OutputFileStream(file);
    final encoder = ar.ZipEncoder();
    encoder.encode(
      archive,
      level: ar.DeflateLevel.bestCompression,
      output: output,
    );
    await output.close();
  }
}

final class _DocXmlTransformer extends StreamTransformerBase<String, String> {
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
