public class Particle extends FCircle
{
  boolean bounce;
  boolean alive;
  int timeleft;
  
  float damage;
  short type;

  public Particle(float x, float y, int timeout)
  {
    super(Global.DEFAULT_PARTICLE_SIZE);
    setRestitution(1.0);
    setPosition(x, y);
    setBullet(true);
    setGrabbable(false);
    
    // visual stuff
    setFill(0, 0, 0);
    setNoStroke();

    damage = 0;
    type = Damage.DMG_Magical;

    alive = true;
    bounce = false; // by default all particles terminate when hitting walls and entities
    timeleft = timeout;
  }

  float x() { return getX(); }
  float y() { return getY(); }
  
  void launch(float dirx, float diry, float spd)
  {
    addImpulse(dirx*spd, diry*spd);
  }
  
  void update()
  {
    if (alive) timeleft--;
    alive = timeleft > 0;
  }
  
  void accelerate(float inc)
  {
  }
}

