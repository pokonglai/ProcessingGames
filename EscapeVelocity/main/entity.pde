public class Entity extends FCircle
{
  String name;
  Props stats;
  
  float extra_range;
  
  public Entity(float x, float y, float radius)
  {
    super(radius);
    setPosition(x, y);
    setRestitution(0);
    setDamping(10);
    setGrabbable(false);
    setRotatable(false);
    
    // visual stuff
    setFill(255, 0, 255);
    if (Global.NO_STROKE) setNoStroke();
    
    name = "Entity";
    stats = new Props();
    
  }
  
  boolean alive() { return stats.HP > 0; }
  
  float x() { return getX(); }
  float y() { return getY(); }
  
  
  // check to see if some entity is in range of this entity
  boolean checkRange(Entity e, float radius)
  {
    float dx = e.x() - x();
    float dy = e.y() - y();
    float dist = sqrt(dx*dx + dy*dy);
    return dist < radius;
  }
  
  // check if the input entity is with range of some (x,y)
  boolean checkRange(Entity e, float x, float y, float radius)
  {
    float dx = x - e.x();
    float dy = y - e.y();
    float dist = sqrt(dx*dx + dy*dy);
    return dist < radius;
  }
  
  void move(int dx, int dy, boolean bShift)
  {
    addImpulse(dx * stats.MOV_SPD(), dy * stats.MOV_SPD());
  }

  void displayHPBar()
  {
    float len = 12 * (stats.HP/stats.HP_MAX);
    fill(255, 0, 0);
    rect(x() - len/2, y() + getSize()/2 + 1, len, 2);
  }
}
