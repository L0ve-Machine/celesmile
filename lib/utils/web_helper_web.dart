import 'dart:js' as js;

void openUrlInNewTab(String url) {
  js.context.callMethod('open', [url, '_blank']);
}
