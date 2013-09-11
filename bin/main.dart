import "dart:io";
import "dart:async";
import "dart:json";

import "packages/ontheroad/ontheroad.dart";

String address = InternetAddress.LOOPBACK_IP_V4.address;

void soloGame(HttpRequest req, Map keys, String params) {
  if (req.session["serverRestart"] != null) {
    req.session["channel"] = keys["channel"];
    req.session["mode"] = "solo";
    req.response.write("in on finish !\n${keys}\n${params}");
    req.response.close();
  }
  else {
    req.response.headers.set("Refresh", "0; url=/home");
    req.response.close();
  }
}

void duoGame(HttpRequest req, Map keys, String params) {
  req.session["channel"] = keys["channel"];
  req.session["mode"] = "duo";
  req.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/html; charset=UTF-8");
  File file = new File('./web/morpion.html');
  file.openRead().pipe(req.response).catchError((e) { print('error pipe!'); });
}

void home(HttpRequest req, Map keys, String params) {
  req.session["serverRestart"] = false;
  req.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/html; charset=UTF-8");
  File file = new File('./web/menu.html');
  file.openRead().pipe(req.response).catchError((e) { print('error pipe!'); });
}

void redirHome(HttpRequest req, Map keys, String params) {
  req.response.headers.set("Refresh", "0; url=/home");
  req.response.close();
}

void dart(HttpRequest req, Map keys, String params) {
  req.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/javascript; charset=UTF-8");
  File file = new File('./web/browser/dart.js');
  file.openRead().pipe(req.response).catchError((e) { print('error pipe!'); });
}

void menuDartJs(HttpRequest req, Map keys, String params) {
  req.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/javascript; charset=UTF-8");
  File file = new File('./web/menu.dart.js');
  file.openRead().pipe(req.response).catchError((e) { print('error pipe!'); });
}

void morpionDuoJs(HttpRequest req, Map keys, String params) {
  req.response.headers.set(HttpHeaders.CONTENT_TYPE, "text/javascript; charset=UTF-8");
  File file = new File('./web/morpion.dart.js');
  file.openRead().pipe(req.response).catchError((e) { print('error pipe!'); });
}

void fav(HttpRequest req, Map keys, String params) {
  req.response.write("fav\n${keys}\n${params}");
  req.response.close();
}

void ws(HttpRequest req, Map keys, String params) {
  WebSocketTransformer.upgrade(req).then((WebSocket ws) {
    handleWebSocket(ws, req);
  });
}

class Player {
  WebSocket       ws;
  String          id;
  bool            isMyTurn;
  int             num;

  Player(this.ws, this.id, this.isMyTurn, this.num);
}

class Channel {
  String          name;
  List            players;
  List            map;
  bool            isFinish;

  Channel(this.name) {
    this.players = new List<Player>();
    this.map = new List<int>.filled(9, -1);
    this.isFinish = false;
  }
}

List channels = new List<Channel>();

void handleWebSocket(WebSocket conn, HttpRequest req) {
  conn.listen((String e) {
    try {
      Map info = parse(e);
      if (info["state"] == "connection") {
        Channel playerChannel;
        Player currentPlayer;
        bool channelExist = false;
        bool playerExist = false;
        for (int i = 0; i < channels.length; i++) {
          Channel channel = channels[i];
          if (channel.name == req.session["channel"]) {
            channelExist = true;
            playerChannel = channel;
            break;
          }
        }
        if (!channelExist) {
          playerChannel = new Channel(req.session["channel"]);
          channels.add(playerChannel);
        }
        for (int i = 0; i < playerChannel.players.length; i++) {
          Player player = playerChannel.players[i];
          if (player.id == req.session.id) {
            playerExist = true;
            currentPlayer = player;
            player.ws = conn;
            break;
          }
        }
        if (!playerExist) {
          Player adverse;
          bool myTurn = false;
          for (int i = 0; i < playerChannel.players.length && i < 2; i++) {
            Player tmp = playerChannel.players[i];
            if (tmp != currentPlayer){
              adverse = tmp;
              break;
            }
          }
          if (playerChannel.players.length == 0) {
            myTurn = true;
          }
          if (adverse != null && !adverse.isMyTurn) {
            myTurn = true;
          }
          currentPlayer = new Player(conn, req.session.id, myTurn, playerChannel.players.length);
          playerChannel.players.add(currentPlayer);
        }
        String data = stringify({ "state": "dumpmap", "dump": playerChannel.map.toString(), "num": currentPlayer.num });
        currentPlayer.ws.add(data);
        data = stringify({ "state": "tour", "me": currentPlayer.isMyTurn });
        currentPlayer.ws.add(data);
      }
      else if (info["state"] == "clicked") {
        Channel playerChannel;
        Player currentPlayer;

        for (int i = 0; i < channels.length; i++) {
          Channel channel = channels[i];
          if (channel.name == req.session["channel"]) {
            playerChannel = channel;
            break;
          }
        }
        for ( int i = 0; i < playerChannel.players.length; i++) {
          Player player = playerChannel.players[i];
          if (player.id == req.session.id) {
            currentPlayer = player;
            break;
          };
        }
        if (!playerChannel.isFinish) {
          if (currentPlayer.num < 2) {
            if (currentPlayer.isMyTurn) {
              if (playerChannel.map[info["pos"]] == -1) {
                currentPlayer.isMyTurn = currentPlayer.isMyTurn ? false : true;
                for (int i = 0; i < playerChannel.players.length; i++) {
                  Player player = playerChannel.players[i];
                  String data = stringify({ "state": "clicked", "etat": currentPlayer.num, "pos": info["pos"] });
                  player.ws.add(data);
                  if (player == currentPlayer) {
                    data = stringify({ "state": "tour", "me": currentPlayer.isMyTurn });
                    currentPlayer.ws.add(data);
                  }
                  else if ((player != currentPlayer) && (player.num == 0 || player.num == 1)) {
                    player.isMyTurn = player.isMyTurn ? false : true;
                    data = stringify({ "state": "tour", "me": player.isMyTurn });
                    player.ws.add(data);
                  }
                }
                playerChannel.map[info["pos"]] = currentPlayer.num;

                int case1 = info["pos"];
                int case2 = (info["pos"] + 1) % 9;
                int case3 = (info["pos"] + 2) % 9;
                int case4 = (info["pos"] + 3) % 9;
                int case5 = (info["pos"] + 4) % 9;
                int case6 = (info["pos"] + 5) % 9;
                int case7 = (info["pos"] + 6) % 9;
                int case8 = (info["pos"] + 7) % 9;
                int case9 = (info["pos"] + 8) % 9;

                if ((playerChannel.map[case1] == currentPlayer.num &&
                    playerChannel.map[case2] == currentPlayer.num &&
                    playerChannel.map[case3] == currentPlayer.num) ||
                    (playerChannel.map[case1] == currentPlayer.num &&
                    playerChannel.map[case4] == currentPlayer.num &&
                    playerChannel.map[case7] == currentPlayer.num) ||
                    (playerChannel.map[case1] == currentPlayer.num &&
                    playerChannel.map[case5] == currentPlayer.num &&
                    playerChannel.map[case9] == currentPlayer.num) ||
                    (playerChannel.map[case1] == currentPlayer.num &&
                    playerChannel.map[case3] == currentPlayer.num &&
                    playerChannel.map[case5] == currentPlayer.num)) {
                  for (int i = 0; i < playerChannel.players.length; i++) {
                    Player player = playerChannel.players[i];
                    player.isMyTurn = false;
                    String data = stringify({ "state": "tour", "me": player.isMyTurn });
                    player.ws.add(data);
                    data = stringify({ "state": "finish", "gagnant": currentPlayer });
                    player.ws.add(data);
                    playerChannel.isFinish = true;
                  }
                }
              }
              else {
                String data = stringify({ "state": "clicked", "etat": -1, "message": "Une Piece est deja ici !" });
                currentPlayer.ws.add(data);
              }
            }
            else {
              Player adverse;
              for (int i = 0; i < playerChannel.players.length && i < 2; i++) {
                Player tmp = playerChannel.players[i];
                if (tmp != currentPlayer){
                  adverse = tmp;
                  break;
                }
              }
              if (adverse != null && !adverse.isMyTurn) {
                String data = stringify({ "state": "tour", "me": currentPlayer.isMyTurn });
                currentPlayer.ws.add(data);
              }
              else {
                String data = stringify({ "state": "error", "message": "Ce n'est pas votre tour !" });
                currentPlayer.ws.add(data);
              }
            }
          }
        }
        else {
          String data = stringify({ "state": "error", "message": "La parti est fini !" });
          currentPlayer.ws.add(data);
        }
      }
    }
    catch (error) {
      print("Erreur parse json: ${error}");
    }
  }, onDone: () {
    print("Un client c'est deconnecte");
  }, onError: (e) {
    print("Une erreur c'est produite sur un client");
  });
}

void main() {
  OnTheRoad app = new OnTheRoad('test');

  app.get('/home', home);
  app.get('/home/solo/:channel', soloGame);
  app.get('/home/duo/:channel', duoGame);
  app.get('/packages/browser/dart.js', dart);
  app.get('/menu.dart.js', menuDartJs);
  app.get('/morpion.dart.js', morpionDuoJs);
  app.get('/ws', ws);
  app.get('/favicon.ico', fav);
  app.get('*', redirHome);

  app.listen("${address}", 8888);
}
