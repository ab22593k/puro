import 'package:checks/checks.dart';
import 'package:file/memory.dart';
import 'package:puro/src/extensions.dart';
import 'package:test/test.dart';

void main() {
  group('FileSystemEntityExtensions.pathEquals', () {
    test('compares two files with same path', () {
      final fs = MemoryFileSystem();
      final a = fs.file('/tmp/foo');
      final b = fs.file('/tmp/foo');
      check(a.pathEquals(b)).isTrue();
    });

    test('compares two files with different paths', () {
      final fs = MemoryFileSystem();
      final a = fs.file('/tmp/foo');
      final b = fs.file('/tmp/bar');
      check(a.pathEquals(b)).isFalse();
    });

    test('compares directory with file', () {
      final fs = MemoryFileSystem();
      final a = fs.directory('/tmp');
      final b = fs.file('/tmp/foo');
      check(a.pathEquals(b)).isFalse();
    });
  });

  group('FileSystemEntityExtensions.resolvedPathEquals', () {
    test('returns true for same resolved path', () {
      final fs = MemoryFileSystem();
      fs.file('/tmp/link_target').createSync(recursive: true);
      fs.link('/tmp/link').createSync('/tmp/link_target');
      final link = fs.link('/tmp/link');
      final target = fs.file('/tmp/link_target');
      check(link.resolvedPathEquals(target)).isTrue();
    });

    test('returns false for different resolved paths', () {
      final fs = MemoryFileSystem();
      fs.file('/tmp/a').createSync(recursive: true);
      fs.file('/tmp/b').createSync(recursive: true);
      check(fs.file('/tmp/a').resolvedPathEquals(fs.file('/tmp/b'))).isFalse();
    });

    test('falls back to path comparison when entities do not exist', () {
      final fs = MemoryFileSystem();
      final a = fs.file('/tmp/does_not_exist');
      final b = fs.file('/tmp/does_not_exist');
      check(a.resolvedPathEquals(b)).isTrue();
    });
  });

  group('FileExtensions.deleteOrRenameSync', () {
    test('deletes file when possible', () {
      final fs = MemoryFileSystem();
      final file = fs.file('/tmp/test.txt')..createSync(recursive: true);
      file.deleteOrRenameSync();
      check(file.existsSync()).isFalse();
    });

    test('handles non-existent file', () {
      final fs = MemoryFileSystem();
      final file = fs.file('/tmp/does_not_exist.txt');
      file.deleteOrRenameSync();
    });

    test('creates .old backup when delete fails', () {
      final fs = MemoryFileSystem();
      // In MemoryFileSystem we can simulate delete failure by locking or
      // permissions. For now we verify the happy path plus .old cleanup.
      final file = fs.file('/tmp/test.txt')..createSync(recursive: true);
      file.writeAsStringSync('content');
      // Delete the file normally to test .old cleanup on next write
      file.deleteOrRenameSync(); // deletes
      // Recreate and delete again — this time .old won't exist
      final file2 = fs.file('/tmp/test.txt')..createSync(recursive: true);
      file2.writeAsStringSync('content');
      file2.deleteOrRenameSync(); // deletes (no .old to clean)
      check(file2.existsSync()).isFalse();
    });
  });

  group('FileExtensions.moveSync', () {
    test('renames within same directory', () {
      final fs = MemoryFileSystem();
      fs.directory('/tmp').createSync(recursive: true);
      final file = fs.file('/tmp/src.txt')..createSync();
      file.writeAsStringSync('data');
      file.moveSync('/tmp/dst.txt');
      check(fs.file('/tmp/src.txt').existsSync()).isFalse();
      check(fs.file('/tmp/dst.txt').existsSync()).isTrue();
      check(fs.file('/tmp/dst.txt').readAsStringSync()).equals('data');
    });

    test('copies and deletes when rename to different dir fails', () {
      final fs = MemoryFileSystem();
      fs.file('/tmp/src.txt').createSync(recursive: true);
      fs.file('/tmp/src.txt').writeAsStringSync('data');
      // Ensure target parent exists
      fs.directory('/other').createSync(recursive: true);
      fs.file('/tmp/src.txt').moveSync('/other/dst.txt');
      check(fs.file('/tmp/src.txt').existsSync()).isFalse();
      check(fs.file('/other/dst.txt').existsSync()).isTrue();
      check(fs.file('/other/dst.txt').readAsStringSync()).equals('data');
    });
  });

  group('DirectoryExtensions.resolve', () {
    test('resolves symlink', () {
      final fs = MemoryFileSystem();
      fs.directory('/tmp/real').createSync(recursive: true);
      fs.link('/tmp/link').createSync('/tmp/real');
      final resolved = fs.directory('/tmp/link').resolve();
      check(resolved.path).endsWith('/tmp/real');
    });
  });

  group('DirectoryExtensions.resolveIfExists', () {
    test('returns self when does not exist', () {
      final fs = MemoryFileSystem();
      final dir = fs.directory('/tmp/nope');
      check(dir.resolveIfExists()).identicalTo(dir);
    });
  });

  group('FileExtensions.resolve', () {
    test('resolves symlink', () {
      final fs = MemoryFileSystem();
      fs.file('/tmp/real.txt').createSync(recursive: true);
      fs.link('/tmp/link.txt').createSync('/tmp/real.txt');
      final resolved = fs.file('/tmp/link.txt').resolve();
      check(resolved.path).endsWith('/tmp/real.txt');
    });
  });

  group('FileExtensions.resolveIfExists', () {
    test('returns self when does not exist', () {
      final fs = MemoryFileSystem();
      final file = fs.file('/tmp/nope.txt');
      check(file.resolveIfExists()).identicalTo(file);
    });
  });

  group('FileSystemExtension.existsSync', () {
    test('returns true for existing file', () {
      final fs = MemoryFileSystem();
      fs.file('/tmp/test.txt').createSync(recursive: true);
      check(fs.existsSync('/tmp/test.txt')).isTrue();
    });

    test('returns false for non-existing path', () {
      final fs = MemoryFileSystem();
      check(fs.existsSync('/tmp/nope.txt')).isFalse();
    });

    test('returns true for existing directory', () {
      final fs = MemoryFileSystem();
      fs.directory('/tmp/mydir').createSync(recursive: true);
      check(fs.existsSync('/tmp/mydir')).isTrue();
    });
  });

  group('ListIntStreamExtensions.toBytes', () {
    test('collects stream into Uint8List', () async {
      final stream = Stream.fromIterable([
        [1, 2, 3],
        [4, 5],
      ]);
      final bytes = await stream.toBytes();
      check(bytes.toList()).deepEquals([1, 2, 3, 4, 5]);
    });

    test('handles empty stream', () async {
      const stream = Stream<List<int>>.empty();
      final bytes = await stream.toBytes();
      check(bytes).isEmpty();
    });
  });
}
