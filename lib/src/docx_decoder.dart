import 'dart:async' show StreamTransformerBase;
import 'dart:convert' show utf8;
import 'dart:io' show File, RandomAccessFile, stderr;

import 'package:xml/xml_events.dart' as xml;
import 'package:zip2/zip2.dart' show zip;

import 'docx_const.dart' as c;

/// A standalone class that convert a [RandomAccessFile] file to a xml stream,
/// which is the main content of the given docx file.
/// A zip file is totally designed for [RandomAccessFile], so it could not be
/// implemented as a stream transformer.
final class DocxDecoder {
  final bool verbose;

  const DocxDecoder({this.verbose = false});

  /// Get the document stream with the given [file] path.
  Stream<String> stream(String file) => open(File(file).openSync());

  /// Get the document stream with the given [RandomAccessFile] object.
  Stream<String> open(RandomAccessFile file) {
    final archive = zip.decoder.unzip(file);
    return archive.doc.data
        .transform(utf8.decoder)
        .transform(_DocxXmlDecoder(verbose: verbose));
  }
}

/// A transformer that convert docx xml file content to raw text lines.
/// It is implemented by xml events instead of xml parser, consideration for
/// super large files.
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
