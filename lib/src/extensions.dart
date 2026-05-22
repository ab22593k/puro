import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

export 'formatting_extensions.dart';

extension ListIntStreamExtensions on Stream<List<int>> {
  Future<Uint8List> toBytes() {
    final completer = Completer<Uint8List>();
    final sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)),
    );
    listen(
      sink.add,
      onError: completer.completeError,
      onDone: sink.close,
      cancelOnError: true,
    );
    return completer.future;
  }
}

extension RandomAccessFileExtensions on RandomAccessFile {
  Future<String> readAllAsString() async {
    setPositionSync(0);
    return utf8.decode(await read(lengthSync()));
  }

  String readAllAsStringSync() {
    setPositionSync(0);
    return utf8.decode(readSync(lengthSync()));
  }

  Future<void> writeAll(List<int> bytes) async {
    await truncate(0);
    setPositionSync(0);
    await writeFrom(bytes);
  }

  Future<void> writeAllString(String string) {
    return writeAll(utf8.encode(string));
  }

  void writeAllSync(List<int> bytes) {
    truncateSync(0);
    setPositionSync(0);
    writeFromSync(bytes);
  }

  void writeAllStringSync(String string) {
    writeAllSync(utf8.encode(string));
  }
}

extension FileSystemEntityExtensions on FileSystemEntity {
  bool pathEquals(FileSystemEntity other) {
    return path.equals(this.path, other.path);
  }

  bool resolvedPathEquals(FileSystemEntity other) {
    if (!existsSync() || !other.existsSync()) {
      return path.equals(this.path, other.path);
    }
    return path.equals(
      resolveSymbolicLinksSync(),
      other.resolveSymbolicLinksSync(),
    );
  }
}

extension DirectoryExtensions on Directory {
  Directory resolve() {
    return fileSystem.directory(resolveSymbolicLinksSync());
  }

  Directory resolveIfExists() {
    if (!existsSync()) return this;
    return fileSystem.directory(resolveSymbolicLinksSync());
  }
}

extension FileExtensions on File {
  void deleteOrRenameSync() {
    final oldFile = parent.childFile('$basename.old');
    if (oldFile.existsSync()) {
      try {
        oldFile.deleteSync();
      } catch (exception) {
        // Might fail if its still open, idk
      }
    }
    try {
      deleteSync();
    } catch (exception) {
      if (existsSync()) {
        renameSync(oldFile.path);
      }
    }
  }

  File resolve() {
    return fileSystem.file(resolveSymbolicLinksSync());
  }

  File resolveIfExists() {
    if (!existsSync()) return this;
    return fileSystem.file(resolveSymbolicLinksSync());
  }

  void moveSync(String newPath) {
    try {
      renameSync(newPath);
    } catch (e) {
      final data = readAsBytesSync();
      fileSystem.file(newPath).writeAsBytesSync(data);
      deleteSync();
    }
  }
}

extension FileSystemExtension on FileSystem {
  bool existsSync(String path) {
    return statSync(path).type != FileSystemEntityType.notFound;
  }
}
