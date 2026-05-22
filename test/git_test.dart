import 'package:checks/checks.dart';
import 'package:puro/src/git.dart';
import 'package:puro/src/provider.dart';
import 'package:test/test.dart';

void main() {
  group('GitTagVersion', () {
    group('parse', () {
      test('stable tag 3.10.0', () {
        final v = GitTagVersion.parse('3.10.0');
        check(v.x).equals(3);
        check(v.y).equals(10);
        check(v.z).equals(0);
        check(v.commits).equals(0);
        check(v.isUnknown).isFalse();
      });

      test('dev version 3.10.0-4.5.pre', () {
        final v = GitTagVersion.parse('3.10.0-4.5.pre');
        check(v.devVersion).equals(4);
        check(v.devPatch).equals(5);
        check(v.commits).equals(0);
        check(v.isUnknown).isFalse();
      });

      test('describe output with dev tag', () {
        final v = GitTagVersion.parse('3.10.0-4.5.pre-6-gabc123');
        check(v.x).equals(3);
        check(v.y).equals(10);
        check(v.z).equals(0);
        check(v.devVersion).equals(4);
        check(v.devPatch).equals(5);
        check(v.commits).equals(6);
        check(v.hash).equals('abc123');
        check(v.isUnknown).isFalse();
      });

      test('unknown version returns unknown', () {
        final v = GitTagVersion.parse('not-a-version');
        check(v.isUnknown).isTrue();
      });
    });

    group('toSemver', () {
      test('stable tag returns matching semver', () {
        final v = GitTagVersion.parse('3.10.0').toSemver();
        check(v.major).equals(3);
        check(v.minor).equals(10);
        check(v.patch).equals(0);
        check(v.isPreRelease).isFalse();
      });

      test('dev tag returns matching pre-release', () {
        final v = GitTagVersion.parse('3.10.0-4.5.pre').toSemver();
        check(v.major).equals(3);
        check(v.minor).equals(10);
        check(v.patch).equals(0);
        // gitTag = '3.10.0-4.5.pre', commits == 0 -> Version.parse('3.10.0-4.5.pre')
        // pub_semver stores numeric pre-release identifiers as int
        check(v.preRelease[0]).equals(4);
        check(v.preRelease[1]).equals(5);
        check(v.preRelease[2]).equals('pre');
      });

      test('describe with dev tag increments minor', () {
        final v = GitTagVersion.parse('3.10.0-4.5.pre-6-gabc123').toSemver();
        // commits > 0, has devVersion/devPatch -> y+1, pre: 0.0.pre.6
        check(v.major).equals(3);
        check(v.minor).equals(11);
        check(v.patch).equals(0);
        check(v.preRelease[0]).equals(0);
        check(v.preRelease[1]).equals(0);
        check(v.preRelease[2]).equals('pre');
        check(v.preRelease[3]).equals(6);
      });

      test('describe with stable tag increments patch', () {
        final v = GitTagVersion.parse('3.10.0-6-gabc123').toSemver();
        // commits > 0, no devVersion/devPatch -> z+1, pre: 0.0.pre.6
        check(v.major).equals(3);
        check(v.minor).equals(10);
        check(v.patch).equals(1);
        check(v.preRelease[0]).equals(0);
        check(v.preRelease[1]).equals(0);
        check(v.preRelease[2]).equals('pre');
        check(v.preRelease[3]).equals(6);
      });
    });

    group('toString', () {
      test('returns semver string', () {
        check(GitTagVersion.parse('3.10.0').toString()).equals('3.10.0');
      });
    });
  });

  group('GitRemoteUrls', () {
    test('equality', () {
      const url = 'https://github.com/user/repo.git';
      const a = GitRemoteUrls(fetch: url, push: {url});
      const b = GitRemoteUrls(fetch: url, push: {url});
      check(a).equals(b);
      check(a.hashCode).equals(b.hashCode);
    });

    test('inequality with different fetch', () {
      const a = GitRemoteUrls(
        fetch: 'https://github.com/user/a.git',
        push: {'https://github.com/user/a.git'},
      );
      const b = GitRemoteUrls(
        fetch: 'https://github.com/user/b.git',
        push: {'https://github.com/user/b.git'},
      );
      check(a == b).isFalse();
    });

    test('single constructor sets both fetch and push', () {
      const url = 'https://github.com/user/repo.git';
      final r = GitRemoteUrls.single(url);
      check(r.fetch).equals(url);
      check(r.push.length).equals(1);
      check(r.push.first).equals(url);
    });
  });

  group('GitClient', () {
    test('of returns registered instance', () {
      final scope = RootScope();
      final client = GitClient(scope: scope);
      scope.add(GitClient.provider, client);
      check(GitClient.of(scope)).isNotNull();
    });
  });

  group('GitCloneStep', () {
    test('values contains the expected steps', () {
      check(GitCloneStep.values).deepEquals([
        GitCloneStep.receivingObjects,
        GitCloneStep.resolvingDeltas,
      ]);
    });
  });
}
