import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:faro_dart/faro_dart.dart';
import 'package:faro_dart/src/model/payload.dart';
import 'package:http/http.dart' as http;

abstract class FaroRemoteCollector {
  Future<void> collect(Payload payload, FaroSettings settings);
}

class FaroRemoteCollectorImpl implements FaroRemoteCollector {
  final String userAgent;

  FaroRemoteCollectorImpl({required this.userAgent});

  @override
  Future<void> collect(Payload payload, FaroSettings settings) async {
    final json = jsonEncode(payload.toJson());
    
    final response = await http.post(
      settings.collectorUrl!,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.userAgentHeader: userAgent,
        if (settings.apiKey != null) 'x-api-key': settings.apiKey!,
      },
      body: json,
    );

    if (response.statusCode != 202) {
      log('Failed to send data to Faro collector: ${response.statusCode} ${response.body}');
    }
  }
}
