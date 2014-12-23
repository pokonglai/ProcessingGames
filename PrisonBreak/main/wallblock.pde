public class WallBlock extends FBox
{
  Rectangle actual; // exact bounds of the wall block
  Rectangle outer; // bounds of the wall block offset by the player size, useful for the AIDirector
  Rectangle particle_check; // slightly larger than actual to check if particles are spawn directly in a wall
  
  WallBlock(float x, float y, float w, float h)
  {
    super(w, h);
    
    setPosition(x, y);
    setStatic(true);
    setGrabbable(false);
    
    // visual stuff
    setFill(0, 0, 255, 150);
    if (Global.NO_STROKE) setNoStroke();
    
    actual = new Rectangle(x-w/2, y-h/2, w, h);
    outer = actual.inflate(Global.PLAYER_SIZE);
    particle_check = actual.inflate(2); // TODO: there must be a better way to prevent particles from spawning in walls
  }
}
