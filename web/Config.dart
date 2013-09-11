library Config;

class Config {
  static final Config _singleton = new Config._internal();
  bool  isMyRound;
  
  factory Config() {
    return _singleton;
  }
  Config._internal() {
    this.isMyRound = false;
  }
}