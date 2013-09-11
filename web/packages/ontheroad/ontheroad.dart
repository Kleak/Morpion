/*
 * OnTheRoad
 * By Kevin Segaud
 * if you find a bug please contact me at segaud.kevin@gmail.com
 */

library OnTheRoad;

import "dart:io";
import "dart:async";

class OnTheRoad {
  String            _name;
  HttpServer        _server;
  List              _getRouteString;
  List              _getRouteFunction;
  List              _postRouteString;
  List              _postRouteFunction;

  OnTheRoad(String n) {
    this._name = n;
    this._getRouteString = new List<String>();
    this._getRouteFunction = new List<Function>();
    this._postRouteString = new List<String>();
    this._postRouteFunction = new List<Function>();
  }

  get name => this._name;

  void get(String r, Function f) {
    this._getRouteString.add(r);
    this._getRouteFunction.add(f);
  }

  void post(String r, Function f) {
    this._postRouteString.add(r);
    this._postRouteFunction.add(f);
  }

  void method(HttpRequest req, List<String> route, List<Function> method, [List<int> data]) {
    Map keys = new Map<String, String>();
    bool pathExist = false;
    List tabRouteString = null;
    List tabPath = null;
    tabPath = req.uri.pathSegments;

    for (int i = 0; i < route.length; i++) {
      String routeString = route[i];
      tabRouteString = routeString.split("/");

      while (tabRouteString != null && tabRouteString[0] == '' && tabRouteString.length > 1)
        String vide = tabRouteString.removeAt(0);

      if (tabPath.length == tabRouteString.length) {
        pathExist = true;
        for (int j = 0; j < tabPath.length; j++) {
          if (tabRouteString[j].length > 1 && tabRouteString[j].substring(0, 1) == ':') {
            keys[tabRouteString[j].substring(1, tabRouteString[j].length)] = tabPath[j];
          }
          else if (tabRouteString[j] != tabPath[j]) {
            pathExist = false;
          }
        }
        if (pathExist) {
          method[i](req, keys, data != null ? data : req.uri.queryParameters);
          break;
        }
        else {
          keys = new Map<String, String>();
        }
      }
    }
    if (!pathExist) {
      method[this._getRouteFunction.length - 1](req, keys, data != null ? data : req.uri.queryParameters);
    }
  }

  void listen(String address, int port) {
    Future<HttpServer> s = HttpServer.bind(address, port);

    s.then((HttpServer s) {
      this._server = s;
      StreamController sc;
      print("Server listen ${port}");

      this._server.listen((HttpRequest req) {
        List<int> dataBody = new List<int>();

        req.response.headers.set("Access-Control-Allow-Methods", "GET, POST");
        req.response.headers.set("Access-Control-Allow-Origin", '*');

        if (req.method == 'GET') {
          this.method(req, this._getRouteString, this._getRouteFunction);
        }
        else {
          req.listen((List<int> data) => dataBody.addAll(data), onDone: () {
            print("data = ${dataBody}");
            this.method(req, this._postRouteString, this._postRouteFunction, dataBody);


            req.response.statusCode = HttpStatus.NOT_FOUND;
            req.response.close();
          }, onError: (e) {
            print("Error: ${e}");
          }, cancelOnError: true);
        }

      }, onDone: () {
        print('end');
      }, onError: (e) {
        print("Error: ${e}");
      }, cancelOnError: true);

    }, onError: (e) {
      print('Server already running !');
    });
  }
}