import 'dart:async';

import 'package:faro_dart/faro_dart.dart';
import 'package:faro_dart/src/faro_remote_collector.dart';
import 'package:faro_dart/src/model/exception.dart';
import 'package:faro_dart/src/model/payload.dart';
import 'package:faro_dart/src/model/trace.dart';
import 'package:faro_dart/src/model/view.dart';
import 'package:meta/meta.dart';
import 'package:synchronized/synchronized.dart';

import 'model/log.dart';

typedef SettingsConfiguration = FutureOr<void> Function(FaroSettings);

typedef AppRunner = FutureOr<void> Function();

class Faro {
  static const String userAgent = "faro-dart/0.1";
  static const interval = Duration(milliseconds: 100);

  Lock lock = Lock();
  FaroSettings currentSettings = FaroSettings();
  Timer ticker = Timer(interval, () {});
  Payload _payload = Payload.empty();
  FaroRemoteCollector _remoteCollector = FaroRemoteCollectorImpl(userAgent: userAgent);

  static Faro? _instance;

  @visibleForTesting
  set remoteCollector(FaroRemoteCollector remoteCollector) {
    _remoteCollector = remoteCollector;
  }

  static Faro get instance {
    _instance ??= Faro._();
    return _instance!;
  }

  Faro._() {
    Faro.pushEvent(Event("session_started"));
  }

  /// Setup Faro with a remote collector. This is the recommended way to use Faro.
  /// 
  /// Only after calling this method, Faro will start sending data to the collector. 
  /// Before calling this method, Faro will not send any data remote, but collect it locally.
  /// 
  /// [collectorUrl] is the URL of the collector
  /// [apiKey] is the API key for the collector
  /// [app] is the app information
  static void setupRemoteCollection({required String collectorUrl, String? apiKey, App? app}) {
    final faroSettings = FaroSettings(collectorUrl: Uri.parse(collectorUrl), apiKey: apiKey);
    faroSettings.meta.app = app;

    instance.currentSettings = faroSettings;
    instance.ticker = Timer.periodic(interval, (Timer t) => Faro.tick());
  }

  @Deprecated('Use setupRemoteCollection instead')
  static Future<void> init(SettingsConfiguration settingsConfiguration,
      {AppRunner? appRunner, @internal FaroSettings? settings}) async {
    final faroSettings = settings ?? FaroSettings();

    try {
      final config = settingsConfiguration(faroSettings);
      if (config is Future) {
        await config;
      }
    } catch (exception) {
      // do nothing
    }

    if (faroSettings.collectorUrl == null) {
      throw ArgumentError('`faroSettings.collectorUrl` has to be set');
    }

    _init(faroSettings, appRunner);
  }

  static _init(FaroSettings settings, AppRunner? appRunner) async {
    instance.currentSettings = settings;
    instance.ticker = Timer.periodic(interval, (Timer t) => Faro.tick());
    instance._payload = Payload(instance.currentSettings.meta);

    await Faro.pushEvent(Event("session_started"));
    if (appRunner != null) {
      await appRunner();
    }
  }

  // stop ticking after one more :)
  static pause() async {
    instance.lock.synchronized(() => tick);

    instance.ticker.cancel();
  }

  static unpause() async {
    instance.ticker = Timer.periodic(interval, (Timer t) => tick);
  }

  static pushLog(String message) {
    instance._payload.logs.add(Log(message));
  }

  static pushEvent(Event event) async {
    instance._payload.events.add(event);
  }

  static pushMeasurement(String name, num value) {
    instance._payload.measurements.add(Measurement(name, value));
  }

  static pushView(String view) {
    instance.lock.synchronized(() {
      // set view for all events forthcoming
      instance.currentSettings.meta.view = View(view);
      // set view for current payload
      instance._payload.meta?.view = View(view);
      instance._payload.events.add(Event('view_changed', attributes: {
        'name': view,
      }));
    });
  }

  static drain() async {
    await Faro.tick();
  }

  @internal
  static tick() async {
    await instance.lock.synchronized(() async {
      // bail if no events
      if (instance._payload.events.isEmpty &&
          instance._payload.exceptions.isEmpty &&
          instance._payload.logs.isEmpty &&
          instance._payload.measurements.isEmpty &&
          instance._payload.traces?.traceId == null) {
        return;
      }

      try {
        final settings = instance.currentSettings;

        await instance._remoteCollector.collect(instance._payload, settings);
      } finally {
        instance._payload = Payload(instance.currentSettings.meta);
      }
    });
  }

  static void pushError(Object error, {StackTrace? stackTrace}) {
    if (error is String) {
      instance.lock.synchronized(() {
        instance._payload.exceptions.add(
            FaroException.fromString(error, incomingStackTrace: stackTrace));
      });
    }
    if (error is Exception) {
      instance.lock.synchronized(() {
        instance._payload.exceptions.add(
            FaroException.fromException(error, incomingStackTrace: stackTrace));
      });
    }
  }

  static void pushTrace(Trace trace) {
    instance.lock.synchronized(() {
      instance._payload.traces = trace;
    });
  }

  static void setUser(User user) {
    instance.lock.synchronized(() {
      instance._payload.meta ??= Meta();

      instance._payload.meta!.user = user;
    });
  }
}
