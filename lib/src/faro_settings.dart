import 'model/meta.dart';

class FaroSettings {
  Uri? collectorUrl;
  String? apiKey;
  Meta meta = Meta();

  FaroSettings({this.collectorUrl, this.apiKey});
}
