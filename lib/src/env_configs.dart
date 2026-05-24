import 'dart:io';

import 'package:file/file.dart';

import 'command_result.dart';

class FlutterConfig {
  FlutterConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');
  late final Directory packagesDir = sdkDir.childDirectory('packages');
  late final File flutterScript = binDir.childFile(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
  );
  late final File dartScript = binDir.childFile(
    Platform.isWindows ? 'dart.bat' : 'dart',
  );
  late final Directory binInternalDir = binDir.childDirectory('internal');
  late final Directory cacheDir = binDir.childDirectory('cache');
  late final FlutterCacheConfig cache = FlutterCacheConfig(cacheDir);
  late final File engineVersionFile = binInternalDir.childFile(
    'engine.version',
  );
  late final Directory flutterToolsDir = packagesDir.childDirectory(
    'flutter_tools',
  );
  late final File flutterToolsScriptFile = flutterToolsDir
      .childDirectory('bin')
      .childFile('flutter_tools.dart');
  late final File flutterToolsPubspecYamlFile = flutterToolsDir.childFile(
    'pubspec.yaml',
  );
  late final File flutterToolsPubspecLockFile = flutterToolsDir.childFile(
    'pubspec.lock',
  );
  late final File flutterToolsPackageConfigJsonFile = flutterToolsDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  late final File flutterToolsLegacyPackagesFile = flutterToolsDir.childFile(
    '.packages',
  );
  late final File legacyVersionFile = sdkDir.childFile('version');
  late final File updateEngineVersionScript = sdkDir
      .childDirectory('bin')
      .childFile('update_engine_version.sh');

  String? get engineVersion =>
      engineVersionFile.existsSync() ? engineVersionFile.readAsStringSync().trim() : null;

  bool get hasEngine =>
      sdkDir.childDirectory('engine').childDirectory('src').childFile('.gn').existsSync();
}

class FlutterCacheConfig {
  FlutterCacheConfig(this.cacheDir);

  final Directory cacheDir;

  late final Directory dartSdkDir = cacheDir.childDirectory('dart-sdk');
  late final DartSdkConfig dartSdk = DartSdkConfig(dartSdkDir);

  late final File flutterToolsStampFile = cacheDir.childFile(
    'flutter_tools.stamp',
  );
  late final File engineStampFile = cacheDir.childFile('engine.stamp');
  late final File engineRealmFile = cacheDir.childFile('engine.realm');
  late final File engineVersionFile = cacheDir.childFile(
    'engine-dart-sdk.stamp',
  );
  late final File versionStampFile = cacheDir.childFile('.version_stamp');
  String? get engineVersion =>
      engineVersionFile.existsSync() ? engineVersionFile.readAsStringSync().trim() : null;
  String? get flutterToolsStamp =>
      flutterToolsStampFile.existsSync() ? flutterToolsStampFile.readAsStringSync().trim() : null;
  late final File versionJsonFile = cacheDir.childFile('flutter.version.json');

  bool get exists => cacheDir.existsSync();
}

class DartSdkConfig {
  DartSdkConfig(this.sdkDir);

  final Directory sdkDir;

  late final Directory binDir = sdkDir.childDirectory('bin');

  late final File dartExecutable = binDir.childFile(
    Platform.isWindows ? 'dart.exe' : 'dart',
  );

  late final File oldPubExecutable = binDir.childFile(
    Platform.isWindows ? 'pub.bat' : 'pub',
  );

  late final Directory libDir = sdkDir.childDirectory('lib');
  late final Directory internalLibDir = libDir.childDirectory('_internal');
  late final File librariesJsonFile = libDir.childFile('libraries.json');
  late final File internalLibrariesDartFile = internalLibDir
      .childDirectory('sdk_library_metadata')
      .childDirectory('lib')
      .childFile('libraries.dart');
  late final File revisionFile = sdkDir.childFile('revision');
  late final File versionFile = sdkDir.childFile('version');
  late final File versionJsonFile = sdkDir.childFile('version.json');
  late final commitHash = revisionFile.readAsStringSync().trim();
}

class EngineConfig {
  EngineConfig(this.rootDir);

  final Directory rootDir;

  late final File gclientFile = rootDir.childFile('.gclient');
  late final Directory srcDir = rootDir.childDirectory('src');
  late final Directory engineSrcDir = srcDir.childDirectory('flutter');

  bool get exists => rootDir.existsSync();

  void ensureExists([String? message]) {
    if (!exists) {
      throw CommandError(
        message ??
            'Environment `${rootDir.parent.basename}` does not have a custom engine, '
                'use `puro engine prepare ${rootDir.parent.basename}` to create one',
      );
    }
  }
}
