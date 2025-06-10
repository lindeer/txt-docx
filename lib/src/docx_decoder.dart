import 'dart:async' show StreamTransformerBase;
import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:archive/archive_io.dart' as ar;
import 'package:xml/xml_events.dart' as xml;

final class DocxDecoder extends StreamTransformerBase<List<int>, String> {
  final int _length;
  final bool verbose;

  const DocxDecoder(this._length, {this.verbose = false});

  @override
  Stream<String> bind(Stream<List<int>> stream) async* {
    final zip = ar.ZipDecoder();
    final ss = stream.map(Uint8List.fromList);
    final t1 = DateTime.now().millisecondsSinceEpoch;
    final fs = await ar.InputFileStream.asRamFile(ss, _length);
    final t2 = DateTime.now().millisecondsSinceEpoch;
    _log('docx_reader: stream asRamFile [$_length], ${t2 - t1} ms.');
    final archive = zip.decodeStream(fs);
    final t3 = DateTime.now().millisecondsSinceEpoch;
    _log('docx_reader: zip decodeStream, ${t3 - t2} ms.');
    final files = archive.where((f) {
      return f.isFile && f.name == 'word/document.xml';
    });
    for (final f in files) {
      final raw = f.rawContent?.getStream();
      if (raw == null) {
        continue;
      }

      final events = _from(raw)
          .transform(utf8.decoder)
          .transform(xml.XmlEventDecoder())
          .expand((events) => events);

      final t4 = DateTime.now().millisecondsSinceEpoch;
      _log('docx_reader: stream transformed, ${t4 - t3} ms.');
      var save = false;
      await for (final e in events) {
        if (e is xml.XmlStartElementEvent) {
          if (e.name == 'w:t') {
            save = true;
          }
        } else if (e is xml.XmlTextEvent) {
          if (save) {
            /// [e.value] should not be trimmed! In case it ends with spaces.
            final v = e.value;
            if (v.isNotEmpty) {
              yield v;
            }
          }
        } else if (e is xml.XmlEndElementEvent) {
          if (e.name == 'w:t') {
            yield '\n';
            save = false;
          }
        }
      }
      final t5 = DateTime.now().millisecondsSinceEpoch;
      _log('docx_reader: handle events done, ${t5 - t4} ms.');
    }
  }

  void _log(String msg) {
    if (verbose) {
      print('\x1B[32m$msg\x1B[0m');
    }
  }

  static Stream<List<int>> _from(ar.InputStream input) async* {
    const chunkSize = 1024 * 1024;
    var size = input.length;
    while (size > chunkSize) {
      final bytes = input.readBytes(chunkSize).toUint8List();
      yield bytes;
      size -= chunkSize;
    }
    if (size > 0) {
      final bytes = input.readBytes(size).toUint8List();
      yield bytes;
    }
  }
}
