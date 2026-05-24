import 'package:file/file.dart';
import 'package:http/http.dart';

import 'http.dart';
import 'logger.dart';
import 'progress.dart';
import 'provider.dart';

Future<void> downloadFile({
  required Scope scope,
  required Uri url,
  required File file,
  String? description,
  bool resume = false,
}) async {
  final log = PuroLogger.of(scope);
  final httpClient = scope.read(clientProvider);

  var partialSize = resume && file.existsSync() ? file.lengthSync() : 0;

  log.v('Downloading $url to ${file.path}');
  if (partialSize > 0) log.v('Resuming from byte $partialSize');

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = description ?? 'Downloading ${url.pathSegments.last}';

    for (var attempt = 0; attempt < 2; attempt++) {
      final request = Request('GET', url);
      if (partialSize > 0) {
        request.headers['Range'] = 'bytes=$partialSize-';
      }

      final response = await httpClient.send(request);

      if (response.statusCode == 206) {
        final sink = file.openWrite(mode: FileMode.append);
        await node.wrapHttpResponse(response).pipe(sink);
        await sink.close();
        return;
      }

      if (response.statusCode == 416) {
        file.deleteSync();
        partialSize = 0;
        continue;
      }

      HttpException.ensureSuccess(response);

      if (partialSize > 0) {
        log.v('Server does not support range, restarting from scratch');
      }
      final sink = file.openWrite();
      await node.wrapHttpResponse(response).pipe(sink);
      await sink.close();
      return;
    }
  });
}
