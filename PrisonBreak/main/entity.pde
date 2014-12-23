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
    boolean bLowStamina = stats.STAMINA <= 0.1*stats.STAMINA_MAX; 
    float running = (bShift && bLowStamina == false) ? Global.DEFAULT_SPRINT_MULTIPLIER : 1.0f;
    addImpulse(dx * stats.MOV_SPD() * running, dy * stats.MOV_SPD()*running);
    
    // less than 10% of max stamina, disable running
    if (bShift == false) stats.STAMINA += (stats.STAMINA_MAX*0.015);
    else if (bShift && bLowStamina == false) stats.STAMINA -= (stats.STAMINA_MAX*0.01);
    
    if (stats.STAMINA > stats.STAMINA_MAX) stats.STAMINA = stats.STAMINA_MAX;
    if (stats.STAMINA < 0) stats.STAMINA = 0;
  }
  
  void push(float x, float y)
  {
    addForce(-x * Global.DEFAULT_MELEE_PUSHBACK, -y * Global.DEFAULT_MELEE_PUSHBACK);
  }
  
  // reduce incoming damage using the approriate defensive stats, apply whatever is left to hp
  Damage takeDamage(float damage, short type)
  {
    float dmg = damage;
    if (type == Damage.DMG_Physical)
    {
      dmg -= stats.PDEF();
      if (dmg > 0) stats.HP -= dmg;
    }
    
    if (type == Damage.DMG_Magical)
    {
      dmg -= stats.MDEF();
      if (dmg > 0) stats.HP -= dmg;
    }
    return new Damage(type, damage, new PVector());
  }
  
  // assume that the direction is already normalized, return a particle
  Particle shoot(PVector dir, Floor f)
  {
    dir.mult(getSize()/2 + 2); // divide by two since we would like the radius not the diameter, addtional pixel is to ensure that the particle is far enough away from the player
    PVector pos = new PVector(x(), y());
    pos.add(dir);
    
    boolean notBlocked = true;
    for (WallBlock wb : f.obstacles)
      if (wb.particle_check.contains(pos.x, pos.y))
        notBlocked = false;
    
    if (notBlocked)
    {
      Particle  p = new Particle(pos.x, pos.y, Global.DEFAULT_PARTICLE_TIMEOUT);
      p.damage = 0;
      p.launch(dir.x, dir.y, Global.DEFAULT_PARTICLE_SPD);
      return p;
    }
    return null;
  }
  
  // check if we are within range to melee the input entity and if we should apply any forces
  // return the actual amount of damage take (for purposes such as displaying floating damage text
  Damage melee(Entity e)
  {
    float dx = x() - e.x();
    float dy = y() - e.y();
    float dist = sqrt(dx*dx + dy*dy);
    boolean inRange = dist <= range_melee();
    
    Damage dmg;
    if (inRange)
    {
      dmg = e.takeDamage(stats.PATK(), Damage.DMG_Physical);
      dmg.force.x = dx;
      dmg.force.y = dy;
    }
    else dmg = new Damage();
    return dmg;
  }
  float range_melee() { return Global.DEFAULT_MELEE_RANGE + extra_range; } // TODO: replace this with the currently equipped weapon range
    
  void displayHPBar()
  {
    float len = 12 * (stats.HP/stats.HP_MAX);
    fill(255, 0, 0);
    rect(x() - len/2, y() + getSize()/2 + 1, len, 2);
  }
}
