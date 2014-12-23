/*
Basic controls for moving the main player and controlling the rest of the game. Allows for multi-key presses.
*/

public class Controls
{
  boolean[] keys;
  boolean bMouseHeld_Left;
  boolean bMouseHeld_Right;
  
  public Controls()
  {
    keys = new boolean[526];
    bMouseHeld_Left = false;
    bMouseHeld_Right = false;
  }
  
  boolean checkKey(int k)
  {
    if (keys.length >= k) return keys[k];
    return false;
  }
  
  void press_repeatkeys()
  {
    controls.keys[keyCode] = true;
  }
  
  void update_repeatkeys()
  {
    if (key == 'W' || key == 'w') { controls.keys['W'] = false; controls.keys['w'] = false; }
    if (key == 'A' || key == 'a') { controls.keys['A'] = false; controls.keys['a'] = false; }
    if (key == 'S' || key == 's') { controls.keys['S'] = false; controls.keys['s'] = false; }
    if (key == 'D' || key == 'd') { controls.keys['D'] = false; controls.keys['d'] = false; }
    if (keyCode == SHIFT) controls.keys[SHIFT] = false;
  }
}
