library Circle;

import 'dart:html';
import 'dart:json';
import 'Config.dart';

class Circle {
  DivElement  circle;
  Config      config;
  var         delegate;
  num         pos;

  void initCircle(num x, num y, num w, num h) {
    circle = new DivElement();
    circle.style.width = "${w}px";
    circle.style.height = "${h}px";
    circle.style.position = "absolute";
    circle.style.left = "${x}px";
    circle.style.top = "${y}px";
    circle.style.backgroundColor = "white";
    circle.style.cursor = 'pointer';
    circle.style.borderRadius = "${(w / 2)}px ${(w / 2)}px ${(w / 2)}px ${(w / 2)}px";
    circle.onClick.listen(this.circleClicked);
  }

  Circle(num x, num y, num w, num h, this.pos, this.delegate) {
    DivElement  mainContainer;
    num         circleWidth;
    num         circleHeight;

    config = new Config();
    mainContainer = query("#mainContainer");
    this.initCircle(x, y, w, h);
    mainContainer.append(circle);
  }

  void circleClicked(MouseEvent event) {
    if (config.isMyRound == true) {
      this.delegate.ws.send(stringify({"state": "clicked", "pos": this.pos}));
    }
  }

}