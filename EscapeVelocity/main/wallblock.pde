public class WallBlock extends FBox
{
  Rectangle actual; // exact bounds of the wall block
  Rectangle outer; // bounds of the wall block offset by the player size, useful for the AIDirector
  
  WallBlock(float x, float y, float w, float h)
  {
    super(w, h);
    
    setPosition(x, y);
    setStatic(true);
    setGrabbable(false);
    
    // visual stuff
    setFill(108, 160, 242);
    if (Global.NO_STROKE) setNoStroke();
    
    actual = new Rectangle(x-w/2, y-h/2, w, h);
    outer = actual.inflate(Global.PLAYER_SIZE/2);
  }
}
