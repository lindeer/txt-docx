import 'dart:async' show StreamTransformerBase;
import 'dart:convert' show utf8;
import 'dart:io' show File, RandomAccessFile, stderr;

import 'package:xml/xml_events.dart' as xml;
import 'package:zip2/zip2.dart' show zip;

import 'docx_const.dart' as c;

final class DocxDecoder {
  final bool verbose;

  const DocxDecoder({this.verbose = false});

  Stream<String> stream(String file) => open(File(file).openSync());

  Stream<String> open(RandomAccessFile file) {
    final archive = zip.decoder.unzip(file);
    return archive.doc.data
        .transform(utf8.decoder)
        .transform(_DocxXmlDecoder(verbose: verbose));
  }
}

/// A transformer that convert docx xml file content to raw text lines.
final class _DocxXmlDecoder extends StreamTransformerBase<String, String> {
  final bool verbose;

  const _DocxXmlDecoder({this.verbose = false});

  @override
  Stream<String> bind(Stream<String> stream) async* {
    {
      final t3 = DateTime.now().millisecondsSinceEpoch;

      final events = stream.transform(xml.XmlEventDecoder()).expand((ev) => ev);

      final t4 = DateTime.now().millisecondsSinceEpoch;
      _log('docx_reader: stream transformed, ${t4 - t3} ms.');
      var save = false;
      final buf = StringBuffer();
      await for (final e in events) {
        if (e is xml.XmlStartElementEvent) {
          if (e.name == 'w:t') {
            save = true;
          }
        } else if (e is xml.XmlTextEvent) {
          if (save) {
            /// [e.value] should not be trimmed! In case it ends with spaces.
            final v = e.value;

            /// text may be truncated, so we buffered it. e.g. '&quot;' was
            /// split into '&q' and 'uot;'
            buf.write(v);
          }
        } else if (e is xml.XmlEndElementEvent) {
          if (e.name == 'w:t') {
            buf.writeln();
            final str = buf
                .toString()
                .replaceAll('&amp;', '&')
                .replaceAll('&lt;', '<')
                .replaceAll('&gt;', '>')
                .replaceAll('&quot;', '"')
                .replaceAll('&apos;', "'");
            buf.clear();
            yield str;
            save = false;
          }
        }
      }
      if (buf.isNotEmpty) {
        yield buf.toString();
      }
      final t5 = DateTime.now().millisecondsSinceEpoch;
      _log('docx_reader: handle events done, ${t5 - t4} ms.');
    }
  }

  void _log(String msg) {
    if (verbose) {
      stderr.writeln('\x1B[32m$msg\x1B[0m');
    }
  }
}
