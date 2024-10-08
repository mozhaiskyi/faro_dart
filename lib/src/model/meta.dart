import 'package:faro_dart/src/model/user.dart';

import 'session.dart';
import 'sdk.dart';
import 'app.dart';
import 'view.dart';
import 'browser.dart';
import 'page.dart';

class Meta {
  Session? session;
  Sdk? sdk;
  App? app;
  View? view;
  Browser? browser;
  Page? page;
  User? user;

  Meta({
    this.session,
    this.sdk,
    this.app,
    this.view,
    this.browser,
    this.page,
    this.user,
  }) {
    session = session ?? Session();
    sdk = sdk ?? Sdk("faro_dart", "0.0.1", []);
  }

  Meta.fromJson(dynamic json) {
    session =
        json['session'] != null ? Session.fromJson(json['session']) : null;
    sdk = json['sdk'] != null ? Sdk.fromJson(json['sdk']) : null;
    app = json['app'] != null ? App.fromJson(json['app']) : null;
    view = json['view'] != null ? View.fromJson(json['view']) : null;
    browser =
        json['browser'] != null ? Browser.fromJson(json['browser']) : null;
    page = json['page'] != null ? Page.fromJson(json['page']) : null;
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (session != null) {
      map['session'] = session!.toJson();
    }
    if (sdk != null) {
      map['sdk'] = sdk!.toJson();
    }
    if (app != null) {
      map['app'] = app!.toJson();
    }
    if (view != null) {
      map['view'] = view!.toJson();
    }
    if (browser != null) {
      map['browser'] = browser!.toJson();
    }
    if (page != null) {
      map['page'] = page!.toJson();
    }
    if (user != null) {
      map['user'] = user!.toJson();
    }
    return map;
  }
}
