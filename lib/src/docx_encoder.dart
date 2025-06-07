import 'dart:async' show StreamController, StreamSink, StreamTransformerBase;
import 'dart:convert' show LineSplitter, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:async/async.dart' show ChunkedStreamReader;
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;

extension _ArchiveExt on Archive {

  void addStringFile(String filename, String doc) => add(ArchiveFile(
    filename,
    doc.length,
    doc.codeUnits,
  ));
}

String _createContentTypesXml() {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element('Types', nest: () {
    builder.attribute('xmlns', 'http://schemas.openxmlformats.org/package/2006/content-types');
    builder.element('Default', nest: () {
      builder.attribute('Extension', 'rels');
      builder.attribute('ContentType', 'application/vnd.openxmlformats-package.relationships+xml');
    });
    builder.element('Default', nest: () {
      builder.attribute('Extension', 'xml');
      builder.attribute('ContentType', 'application/xml');
    });
    builder.element('Override', nest: () {
      builder.attribute('PartName', '/word/document.xml');
      builder.attribute('ContentType', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml');
    });
    builder.element('Override', nest: () {
      builder.attribute('PartName', '/word/styles.xml');
      builder.attribute('ContentType', 'application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml');
    });
    builder.element('Override', nest: () {
      builder.attribute('PartName', '/word/fontTable.xml');
      builder.attribute('ContentType', 'application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml');
    });
  });
  return builder.buildDocument().toXmlString();
}

String _createRelsXml() {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element('Relationships', nest: () {
    builder.attribute('xmlns', 'http://schemas.openxmlformats.org/package/2006/relationships');
    builder.element('Relationship', nest: () {
      builder.attribute('Id', 'rId1');
      builder.attribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument');
      builder.attribute('Target', 'word/document.xml');
    });
  });
  return builder.buildDocument().toXmlString();
}

String _createDocumentRelsXml() {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element('Relationships', nest: () {
    builder.attribute('xmlns', 'http://schemas.openxmlformats.org/package/2006/relationships');
    builder.element('Relationship', nest: () {
      builder.attribute('Id', 'rId1');
      builder.attribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles');
      builder.attribute('Target', 'styles.xml');
    });
    builder.element('Relationship', nest: () {
      builder.attribute('Id', 'rId2');
      builder.attribute('Type', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable');
      builder.attribute('Target', 'fontTable.xml');
    });
  });
  return builder.buildDocument().toXmlString();
}

String _createStylesXml() {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element('w:styles', nest: () {
    builder.attribute('xmlns:w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
    builder.element('w:docDefaults', nest: () {
      builder.element('w:rPrDefault', nest: () {
        builder.element('w:rPr', nest: () {
          builder.element('w:rFonts', nest: () {
            builder.attribute('w:ascii', 'Calibri');
            builder.attribute('w:hAnsi', 'Calibri');
          });
          builder.element('w:sz', nest: () {
            builder.attribute('w:val', '22'); // Font size in half-points (11pt * 2)
          });
        });
      });
      builder.element('w:pPrDefault');
    });
  });
  return builder.buildDocument().toXmlString();
}

String _createFontTableXml() {
  final builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
  builder.element('w:fonts', nest: () {
    builder.attribute('xmlns:w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
    builder.element('w:font', nest: () {
      builder.attribute('w:name', 'Calibri');
      builder.element('w:family', nest: () {
        builder.attribute('w:val', 'swiss');
      });
      builder.element('w:charset', nest: () {
        builder.attribute('w:val', '0');
      });
      builder.element('w:pitch', nest: () {
        builder.attribute('w:val', 'variable');
      });
      builder.element('w:sig', nest: () {
        builder.attribute('post', '0');
        builder.attribute('usb0', '16777216');
        builder.attribute('usb1', '268435456');
        builder.attribute('usb2', '0');
        builder.attribute('usb3', '0');
      });
    });
  });
  return builder.buildDocument().toXmlString();
}

final class DocxEncoder extends StreamTransformerBase<String, List<int>> {
  final int _length;

  const DocxEncoder(this._length);

  @override
  Stream<List<int>> bind(Stream<String> stream) {
    final archive = Archive();
    archive.addStringFile('[Content_Types].xml', _createContentTypesXml());
    archive.addStringFile('_rels/.rels', _createRelsXml());
    archive.addStringFile('word/_rels/document.xml.rels', _createDocumentRelsXml());
    archive.addStringFile('word/styles.xml', _createStylesXml());
    archive.addStringFile('word/fontTable.xml', _createFontTableXml());

    final lines = stream.transform(LineSplitter());
    final xml = _docStream(lines);
    final reader = _BytesReader(xml.transform(utf8.encoder), _length);
    final input = InputFileStream.withFileHandle(reader);
    archive.addFile(ArchiveFile.stream('word/document.xml', input));
    final ctrl = StreamController<List<int>>();
    final encoder = ZipEncoder();
    final writer = _BytesWriter(ctrl.sink, -1);
    final output = OutputFileStream.withFileHandle(writer);
    encoder.encodeStream(archive, output);
    return ctrl.stream;
  }

  Stream<String> _docStream(Stream<String> lines) async* {
    yield '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:body>';
    await for (final line in lines) {
      yield '<w:p><w:r><w:t>';
      yield line.replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
      yield '</w:t></w:r></w:p>';
    }
    yield '</w:body></w:document>';
  }
}

class _BytesReader implements AbstractFileHandle {
  final ChunkedStreamReader<int> _reader;
  final int _length;
  int _pos;

  _BytesReader(Stream<List<int>> stream, this._length)
      : _reader = ChunkedStreamReader<int>(stream)
      , _pos = 0;


  @override
  int get position => _pos;

  @override
  set position(int p) => _pos = p;

  @override
  int get length => _length;

  @override
  Future<void> close() {
    return _reader.cancel();
  }

  @override
  void closeSync() {
  }

  @override
  bool get isOpen => throw UnimplementedError();

  @override
  bool open({FileAccess mode = FileAccess.read}) {
    throw UnimplementedError();
  }

  @override
  int readInto(Uint8List buffer, [int? length]) {
    final len = length ?? buffer.length;
    /*
    final data = await _reader.readChunk(len);
    buffer.setRange(0, len, data);
    */
    return len;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    throw UnimplementedError();
  }
}

class _BytesWriter implements AbstractFileHandle {
  final StreamSink<List<int>> sink;
  final int _length;
  int _pos = 0;

  _BytesWriter(this.sink, this._length);

  @override
  int get position => _pos;

  @override
  set position(int p) => _pos = p;

  @override
  int get length => _length;

  @override
  Future<void> close() => sink.close();

  @override
  void closeSync() => throw UnimplementedError();

  @override
  bool get isOpen => throw UnimplementedError();

  @override
  bool open({FileAccess mode = FileAccess.read}) {
    throw UnimplementedError();
  }

  @override
  int readInto(Uint8List buffer, [int? length]) {
    throw UnimplementedError();
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    sink.add(buffer.sublist(start, end));
  }
}
