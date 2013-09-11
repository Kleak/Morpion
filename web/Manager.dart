library Manager;

import 'dart:html';
import 'dart:json';
import 'Circle.dart';
import 'Config.dart';

String address = "127.0.0.1";

class Manager {
  DivElement  mainContainer;
  num         mainContainerW;
  num         mainContainerH;
  num         circleW;
  num         circleH;
  num         space;
  Config      config;
  List        cList;
  WebSocket   ws;
  num         id;

  void updateMap(List lMap) {
    for (num i = 0; i < cList.length; ++i) {
      if (lMap[i] == -1)
        cList[i].circle.style.backgroundColor = 'white';
      else if (lMap[i] == id)
        cList[i].circle.style.backgroundColor = 'blue';
      else
        cList[i].circle.style.backgroundColor = 'red';
    }
  }

  void updateCircle(num pos, num rep) {
    if (rep == id)
      cList[pos].circle.style.backgroundColor = 'blue';
    else
      cList[pos].circle.style.backgroundColor = 'red';
  }

  void wsMessage(e) {
    Map newMap = parse(e.data);

    print(newMap);

    if (newMap["state"] == "dumpmap") {
      List lMap = parse(newMap["dump"]);
      id = newMap["num"];
      this.updateMap(lMap);
    }
    if (newMap["state"] == "clicked") {
      num rep = newMap["etat"];
      num pos = newMap["pos"];
      if (rep != -1)
        this.updateCircle(pos, rep);
    }
  }

  void wsOpen(e) {
    print("WebSocket opened.");
    String data = stringify({"state": "connection"});
    ws.send(data);
  }

  void wsClose(e) {
    print("WebSocker closed.");
  }

  void wsError(e) {
    print("WebSocket error.");
  }

  void initWS() {
    ws = new WebSocket('ws://${address}:8888/ws');

    if (ws != null) {
      ws.onOpen.listen(wsOpen);
      ws.onMessage.listen(wsMessage);
      ws.onClose.listen(wsClose);
      ws.onError.listen(wsError);
    }
  }

  void initCss() {
    document.body.style.fontFamily = "'Open Sans', sans-serif";
    document.body.style.backgroundColor = "#F8F8F8";

    query("#mainTitle").style.textAlign = "center";
  }

  void initMainContainer(num mainContainerW, num MAinContainerH) {
    mainContainer = query("#mainContainer");
    mainContainer.style.width = "${mainContainerW}px";
    mainContainer.style.height = "${mainContainerW}px";
    mainContainer.style.position = "relative";
    mainContainer.style.margin = "auto";
  }

  void initGrid() {

    for (num i = 0; i < 2; ++i) {
      DivElement g = new DivElement();

      g.style.width = "${(mainContainerW - (2 * space))}px";
      g.style.height = "0px";
      g.style.border = "1px solid black";
      g.style.position = "absolute";
      g.style.left = "${space}px";
      g.style.top = "${(((i + 1) * space) + ((i + 1) * circleW)) + (space / 2)}px";

      mainContainer.append(g);
    }

    for (num j = 0; j < 2; ++j) {
      DivElement g = new DivElement();

      g.style.width = "0px";
      g.style.height = "${(mainContainerH - (2 * space))}px";
      g.style.border = "1px solid black";
      g.style.position = "absolute";
      g.style.top = "${space}px";
      g.style.left = "${(((j + 1) * space) + ((j + 1) * circleW)) + (space / 2)}px";

      mainContainer.append(g);
    }

  }

  Manager() {
    num circleX;
    num circleY;

    cList = new List();
    space = 40;
    mainContainerW = 500;
    mainContainerH = 500;
    circleW = (mainContainerW / 3) - (space * ((3 + 1) / 3));
    circleH = (mainContainerH / 3) - (space * ((3 + 1) / 3));

    config = new Config();
    config.isMyRound = true;

    this.initWS();
    this.initCss();
    this.initMainContainer(mainContainerW, mainContainerH);
    this.initGrid();

    for (num i = 0; i < 3; ++i) {
      for (num j = 0; j < 3; ++j) {
        circleX = (j * (circleW + space)) + space;
        circleY = (i * (circleH + space)) + space;
        Circle c = new Circle(circleX, circleY, circleW, circleH, (j + (i * 3)), this);
        cList.add(c);
      }
    }
  }
}