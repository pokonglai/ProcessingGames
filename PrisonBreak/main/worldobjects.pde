/** Contains all the interactive objects that can be placed within a game world. **/

public class Torch
{
  PVector pos;
  int timeleft;
  boolean alive;
  public Torch(float x, float y)
  {
    pos = new PVector(x,y);
    timeleft = Global.DEFAULT_TORCH_TIMEOUT;
    alive = true;
  }
  
  float x() { return pos.x; }
  float y() { return pos.y; }
  
  void update()
  {
    if (alive) timeleft--;
    alive = timeleft > 0;
  }
  
  void display(PGraphics g)
  {
    float timeratio = (float)timeleft / (float)Global.DEFAULT_TORCH_TIMEOUT;
    g.fill(255, 255, 255, (int)(timeratio*255));
    g.ellipse(x(), y(), Global.DEFAULT_TORCH_SIZE, Global.DEFAULT_TORCH_SIZE);
  }
}

// implement when items and equipment are working
// walk up to it and press INTERACT key to open
public class Treasure extends FBox
{
  public Treasure(float x, float y, float w, float h)
  {
    super(w, h);
    setPosition(x, y);
    setStatic(true);
    setGrabbable(false);
    
    // visual stuff
    setFill(198, 104, 2, 150);
    if (Global.NO_STROKE) setNoStroke();
  }
}

// complete an exit condition, unlock the exit
public class Exit
{
  Rectangle hitbox; // location the player must move to once the condition has been completed
  boolean open;
  boolean gameover;
  
  public Exit(float x, float y)
  {
    hitbox = new Rectangle(x, y, Global.EXIT_SIZE, Global.EXIT_SIZE);
    open = false;
    gameover = false;
  }
  float x() { return hitbox.topleft.x; }
  float y() { return hitbox.topleft.y; }
  float width() { return hitbox.width(); }
  float height() { return hitbox.height(); }
  boolean contains(float x, float y) { return hitbox.contains(x,y); }

  // check if the current state of the game statisfies the winning conditions
  // if so, open the exit and let the player win if they get inside of it
  void updateGameState(Floor f, Entity player)
  {
    if (f.lightswitch.selected) open = true;
    if (open) gameover = contains(player.x(), player.y());
  }
  
  void display(PGraphics g)
  {
    if (open) g.fill(0, 255, 255);
    else g.fill(255, 145, 0);
    g.rect(hitbox.topleft.x, hitbox.topleft.y - hitbox.height(), hitbox.width(), hitbox.height());
  }
}


// generalized switch, turned on when the player steps on it
public class Switch
{
  Rectangle hitbox;
  boolean selected;
  
  public Switch(float x, float y)
  {
    hitbox = new Rectangle(x, y, Global.EXIT_SIZE, Global.EXIT_SIZE);
    selected = false; // hovered over it, turns on the switch
  }

  float x() { return hitbox.topleft.x; }
  float y() { return hitbox.topleft.y; }
  float width() { return hitbox.width(); }
  float height() { return hitbox.height(); }
  void hover(Entity player)
  {
    if (selected == false)
    {
      selected = hitbox.contains(player.x(), player.y());
    }
  }
  
  void display(PGraphics g)
  {
    if (selected) g.fill(0, 255, 0, 64);
    else g.fill(255, 0, 0, 64);
    g.rect(hitbox.topleft.x, hitbox.topleft.y - hitbox.height(), hitbox.width(), hitbox.height());
  }
}



