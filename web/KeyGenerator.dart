library KeyGenerator;

import 'dart:math';

class KeyGenerator {
  String  keyValues;
  num     keyValuesLen;
  num     len;
  
  String generate() {
    var     rand;
    var     randNb;
    String  res;
    
    res = "";
    rand = new Random();
    randNb = rand.nextInt(keyValuesLen);
    for (num i = 0; i < len; i++) {
      randNb = rand.nextInt(keyValuesLen);
      res = res + keyValues[randNb];
    }
    return res;
  }
  
  KeyGenerator(this.keyValues, this.len) {
    keyValuesLen = this.keyValues.length;
  }
}