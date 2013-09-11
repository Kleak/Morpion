import 'dart:html';
import 'KeyGenerator.dart';

void playClicked(MouseEvent e) {
  KeyGenerator kg = new KeyGenerator("0123456789abcdefghijklmnopqrstuvwxyz", 24);
  String key = kg.generate();
  window.location.assign("/home/duo/${key}");
//  window.location.assign("morpion.html");
}

void main() {
  document.body.style.margin = "0";
  document.body.style.padding = "0";
  document.body.style.backgroundColor = "#F8F8F8";
  query("#mainTitle").style.textAlign = "center";

  DivElement playButton = new DivElement();

  playButton.style.width = "400px";
  playButton.style.height = "200px";
  playButton.style.margin = "auto";
  playButton.style.position = "relative";
  playButton.style.backgroundColor = "white";
  playButton.style.borderRadius = "30px 30px 30px 30px";
  playButton.style.cursor = 'pointer';
  playButton.onClick.listen(playClicked);
  document.body.append(playButton);

  Element playLabel = new Element.tag("h1");

  playLabel.style.position = "relative";
  playLabel.style.fontSize = "50px";
  playLabel.style.top = "${100 - 30}px";
  playLabel.style.textAlign = "center";
  playLabel.innerHtml = "PLAY";
  playButton.append(playLabel);
 }