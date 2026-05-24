// This is a work in progress

import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart';

import 'reader.dart';

class BinReader extends Reader {
  BinReader(this.formats, super.bytes);

  final Map<int, BinFormat> formats;
  final fields = <String, Uint8Buffer>{};
  final indices = <String, int>{};

  BinFormat get fmt => formats[formatVersion]!;

  void addByte(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.add(value);
  }

  void addUInt32(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 4;
    buf.buffer.asByteData().setUint32(buf.length - 4, value);
  }

  void addInt64(String name, int value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 8;
    buf.buffer.asByteData().setInt64(buf.length - 8, value);
  }

  void addDouble(String name, double value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.length += 8;
    buf.buffer.asByteData().setFloat64(buf.length - 8, value);
  }

  void addBytes(String name, Uint8List value) {
    final buf = fields[name] ??= Uint8Buffer();
    buf.addAll(value);
  }

  void readArr(String name, int count, BinType c) {
    for (var i = 0; i < count; i++) {
      readType('$name.element', c);
    }
  }

  void readRList(String name, int start, int end, BinType c) {
    byteOffset = end - 4;
    final length = readUInt32();
    byteOffset = start;
    addUInt32(name, length);
    for (var i = 0; i < length; i++) {
      readType('$name.element', c);
    }
  }

  int getParentUInt32(String name, String field) {
    final nameParts = name.split('.');
    final parentName = nameParts.take(nameParts.length - 1).join('.');
    final buf = fields['$parentName.$field']!;
    return buf.buffer.asByteData().getUint32((buf.length - 1) ~/ 4);
  }

  void readType(String name, BinType c) {
    final delim = name.isEmpty ? '' : '$name.';
    switch (c) {
      case final NamedBinType c:
        switch (c.name) {
          case 'Bool':
            addByte(name, readByte());
            break;
          case 'UInt':
            addUInt32(name, readUInt30());
            break;
          case 'UInt32':
            addUInt32(name, readUInt32());
            break;
          case 'Double':
            addDouble(name, readDouble());
            break;
          case 'ComponentFile':
            final cl = fmt.classes[c.name]!;
            for (final field in cl.fields.entries) {
              final name = '$delim${c.name}.${field.key}';
              if (field.key == 'libraries') {
                readArr(name, libraryCount, c);
                continue;
              } else if (field.key == 'sourceMap') {
                byteOffset = indices['sourceMapOffset']!;
              } else if (field.key == 'constantsMapping') {
                // Skip because we generate when serializing
                continue;
              } else if (field.key == 'canonicalNames') {
                byteOffset = indices['binaryOffsetForCanonicalNames']!;
              } else if (field.key == 'metadataPayloads') {
                // Metadata is just opaque bytes
                byteOffset = indices['binaryOffsetForMetadataPayloads']!;
                final end = indices['binaryOffsetForMetadataMappings']!;
                addBytes(name, readBytes(end - byteOffset));
                continue;
              } else if (field.key == 'metadataMappings') {
                final t = (field.value as RListBinType).elementType;
                readRList(
                  name,
                  indices['binaryOffsetForMetadataMappings']!,
                  indices['binaryOffsetForStringTable']!,
                  t,
                );
                continue;
              } else if (field.key == 'componentIndex') {
                break;
              }
              readType('$delim${c.name}.${field.key}', field.value);
            }
          default:
            final cl = fmt.classes[c.name]!;
            for (final field in cl.fields.entries) {
              readType('$delim${c.name}.${field.key}', field.value);
            }
        }
      case final ListBinType c:
        final length = readUInt30();
        addUInt32(name, length);
        for (var i = 0; i < length; i++) {
          readType('${delim}element', c.elementType);
        }
      case final ArrayBinType c:
        int realSize;
        switch (c.size) {
          case 'endOffsets.last':
            realSize = getParentUInt32(name, 'endOffsets.element');
          case 'length':
            if (!name.endsWith('.UriSource.source') && !name.endsWith('.UriSource.sourceIndex')) {
              throw UnimplementedError('Unknown array size: ${c.size} in $name');
            }
            realSize = getParentUInt32(name, 'length');
          case 'classes.length + 1':
            if (!name.endsWith('.Library.classOffsets')) {
              throw UnimplementedError('Unknown array size: ${c.size} in $name');
            }
            realSize = getParentUInt32(name, 'classes') + 1;
          case 'procedures.length + 1':
            if (!name.endsWith('.Library.procedureOffsets')) {
              throw UnimplementedError('Unknown array size: ${c.size} in $name');
            }
            realSize = getParentUInt32(name, 'procedures') + 1;
          default:
            throw UnimplementedError('Unknown array size: ${c.size} in $name');
        }
        for (var i = 0; i < realSize; i++) {
          readType('${delim}element', c.elementType);
        }
      case final OptionBinType c:
        final hasValue = readByte();
        addByte(name, hasValue);
        if (hasValue != 0) {
          assert(hasValue == 1);
          readType('${delim}value', c.elementType);
        }
      case final PairBinType c:
        readType('${delim}first', c.firstType);
        readType('${delim}second', c.secondType);
      default:
        throw UnimplementedError('Unknown type: $c');
    }
  }

  void read() {
    final componentIndex = fmt.classes['ComponentIndex']!;
    var componentIndexSize = 0;
    for (final entry in componentIndex.fields.entries) {
      final name = entry.key;
      if (name == 'libraryOffsets') break;
      final type = entry.value;
      if (type case NamedBinType(name: 'UInt32')) {
        componentIndexSize += 4;
      } else {
        throw UnimplementedError(
          'Unexpected type in index: $componentIndexSize',
        );
      }
    }

    // libraryOffsets
    componentIndexSize += libraryCount * 4;

    // libraryCount and componentFileSizeInBytes
    componentIndexSize += 8;

    byteOffset = byteData.lengthInBytes - componentIndexSize;

    for (final entry in componentIndex.fields.entries) {
      final name = entry.key;
      if (name == 'libraryOffsets') break;
      final type = entry.value;
      if (type is NamedBinType && type.name == 'UInt32') {
        indices[name] = readUInt32();
      } else {
        throw UnimplementedError(
          'Unexpected type in index: $componentIndexSize',
        );
      }
    }

    indices['libraryCount'] = libraryCount;
    indices['componentFileSizeInBytes'] = componentFileSize;

    byteOffset = 0;
    readType('', NamedBinType('ComponentFile'));
  }
}

class BinFormat {
  BinFormat(this.classes);
  final Map<String, BinClass> classes;

  factory BinFormat.fromSchema(dynamic schema) {
    final typeSchemas = <String, dynamic>{};
    final enumNames = <String>{};
    for (final decl in schema as List) {
      if (decl['type'] != null) {
        final name = decl['type'][1] as String;
        typeSchemas[name] = decl['type'];
      } else if (decl['enum'] != null) {
        enumNames.add(decl['enum'][0] as String);
      } else {
        throw UnimplementedError('Unknown type: $decl');
      }
    }

    final classes = <String, BinClass>{};
    for (final decl in schema) {
      if (decl['type'] != null) {
        final name = decl['type'][1] as String;
        final fields = <String, BinType>{};
        for (final fieldDecl in decl['type'][3] as List) {
          if (fieldDecl['field'] != null) {
            final tpe = BinType.fromSchema(
              fieldDecl['field'][0],
              typeSchemas,
              enumNames,
            );
            final fieldName = fieldDecl['field'][1] as String;
            fields[fieldName] = tpe;
          } else if (fieldDecl['bitfield'] != null) {
            final tpe = BinType.fromSchema(
              fieldDecl['bitfield'][0],
              typeSchemas,
              enumNames,
            );
            final fieldName = fieldDecl['bitfield'][1] as String;
            fields[fieldName] = tpe;
          } else {
            throw UnimplementedError('Unknown field: $fieldDecl');
          }
        }

        final children = <int, NamedBinType>{};
        void visitDecl(String parentName, dynamic childDecl) {
          if (childDecl['type'] == null) return;
          if (childDecl['type'][2] != parentName) return;
          final childName = childDecl['type'][1] as String;

          if (childDecl['type'][0] == true || (childDecl['type'][3] as List).isEmpty) {
            // Enumerate the children of abstract types too
            for (final childChildDecl in childDecl['type'][3] as List) {
              visitDecl(childName, childChildDecl);
            }
            return;
          }
          final tag = childDecl['type'][3][0]['field'];
          assert(tag[0] == 'Byte');
          assert(tag[1] == 'tag');
          final tagValue = tag[2] as String;
          if ((childName == 'SpecializedVariableGet' ||
                  childName == 'SpecializedVariableSet' ||
                  childName == 'SpecializedIntLiteral') &&
              tagValue.endsWith('+ N')) {
            final startValue = int.parse(tagValue.split(' ').first);
            for (var i = startValue; i < startValue + 8; i++) {
              children[i] = NamedBinType(childName);
            }
          } else {
            children[int.parse(tag[2] as String)] = NamedBinType(childName);
          }
        }

        for (final childDecl in schema) {
          visitDecl(name, childDecl);
        }

        classes[name] = BinClass(fields, children);
      }
    }

    return BinFormat(classes);
  }
}

class BinClass {
  BinClass(this.fields, this.children);
  final Map<String, BinType> fields;
  final Map<int, NamedBinType> children;
}

abstract class BinType {
  BinType();
  factory BinType.fromSchema(
    dynamic schema,
    Map<String, dynamic> typeSchemas,
    Set<String> enumNames,
  ) {
    return switch (schema) {
      final String str when enumNames.contains(str) => NamedBinType('Byte'),
      final String str => NamedBinType(str),
      {'option': final opt} => OptionBinType(
        BinType.fromSchema(opt, typeSchemas, enumNames),
      ),
      {'list': final lst} => ListBinType(
        BinType.fromSchema(lst, typeSchemas, enumNames),
      ),
      {'rlist': final rlist} => RListBinType(
        BinType.fromSchema(rlist, typeSchemas, enumNames),
      ),
      {'pair': final pair} => PairBinType(
        BinType.fromSchema(pair[0], typeSchemas, enumNames),
        BinType.fromSchema(pair[1], typeSchemas, enumNames),
      ),
      {'array': final arr} => ArrayBinType(
        arr[0] as String,
        BinType.fromSchema(arr[1], typeSchemas, enumNames),
      ),
      {'union': final union} => NamedBinType(typeSchemas[union[0]]![1] as String),
      {'ifPrivate': final ifPrivate} => IfPrivateBinType(
        BinType.fromSchema(ifPrivate, typeSchemas, enumNames),
      ),
      _ => throw UnimplementedError('Unknown type: $schema'),
    };
  }
}

class NamedBinType extends BinType {
  NamedBinType(this.name);
  final String name;
}

class ListBinType extends BinType {
  ListBinType(this.elementType);
  final BinType elementType;
}

class ArrayBinType extends BinType {
  ArrayBinType(this.size, this.elementType);
  final String size;
  final BinType elementType;
}

class RListBinType extends BinType {
  RListBinType(this.elementType);
  final BinType elementType;
}

class OptionBinType extends BinType {
  OptionBinType(this.elementType);
  final BinType elementType;
}

class PairBinType extends BinType {
  PairBinType(this.firstType, this.secondType);
  final BinType firstType;
  final BinType secondType;
}

class IfPrivateBinType extends BinType {
  IfPrivateBinType(this.elementType);
  final BinType elementType;
}
