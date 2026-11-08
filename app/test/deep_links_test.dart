import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/core/deep_links.dart';

/// The manifest registers `kumpleto://` for `doc` and `bundle`; everything
/// else has to fall through to the router's normal entry point.
void main() {
  test('document and bundle links map to their routes', () {
    expect(deepLinkPath('kumpleto://doc/nbi-clearance'), '/doc/nbi-clearance');
    expect(deepLinkPath('kumpleto://bundle/job-hunt-pack'), '/bundle/job-hunt-pack');
  });

  test('the slash-before-host form is accepted too', () {
    expect(deepLinkPath('kumpleto:/doc/umid-sss'), '/doc/umid-sss');
    expect(deepLinkPath('kumpleto:/bundle/new-business'), '/bundle/new-business');
  });

  test('query strings and a trailing slash do not change the target', () {
    expect(deepLinkPath('kumpleto://doc/cedula/?from=share'), '/doc/cedula');
  });

  test('unknown schemes, kinds and ids are rejected', () {
    expect(deepLinkPath('https://example.com/doc/cedula'), isNull);
    expect(deepLinkPath('/doc/cedula'), isNull);
    expect(deepLinkPath('kumpleto://user/cedula'), isNull);
    expect(deepLinkPath('kumpleto://doc'), isNull);
    expect(deepLinkPath('kumpleto://doc/../../etc/passwd'), isNull);
    expect(deepLinkPath('kumpleto://doc/CEDULA'), isNull);
    expect(deepLinkPath(''), isNull);
    expect(deepLinkPath(null), isNull);
  });

  test('the uri form rejects a relative location', () {
    expect(deepLinkPathForUri(Uri.parse('/doc/cedula')), isNull);
  });
}
