public class Spaceship extends WallBlock
{
  // ship parts
  Hull hull;
  LifeSupport life;
  Thrusters thrust;
  RadiationShields shield;
  
  // bounds
  Rectangle zone_range;
  ArrayList<Rectangle> return_zones;
  Rectangle repair_hull;
  Rectangle repair_life;
  Rectangle repair_thrust;
  Rectangle repair_shield;
  
  // resources
  Resources available;
  Timer res_growth;
  
  public Spaceship()
  {
    super(width/2, height/2 - Global.HUD_HEIGHT/2, Global.SPACESHIP_W, Global.SPACESHIP_H);
    
    setFill(255, 255, 255);
    
    hull = new Hull();
    life = new LifeSupport();
    thrust = new Thrusters(); 
    shield = new RadiationShields();
    
    zone_range = actual.inflate(Global.PLAYER_SIZE*4 + 8);
    
    // repair zones
    repair_hull = new Rectangle(actual.bottomleft.x - Global.REPAIR_SIZE, actual.bottomleft.y, Global.REPAIR_SIZE, Global.REPAIR_SIZE); // bottom left
    repair_life = new Rectangle(actual.topleft.x - Global.REPAIR_SIZE, actual.topleft.y - Global.REPAIR_SIZE, Global.REPAIR_SIZE, Global.REPAIR_SIZE); // top left
    repair_thrust = new Rectangle(actual.topright.x, actual.topright.y - Global.REPAIR_SIZE, Global.REPAIR_SIZE, Global.REPAIR_SIZE); // top right
    repair_shield = new Rectangle(actual.bottomright.x, actual.bottomright.y, Global.REPAIR_SIZE, Global.REPAIR_SIZE); // bottom right
    
    return_zones = new ArrayList<Rectangle>();
    return_zones.add(new Rectangle(actual.bottomleft.x, actual.bottomleft.y, Global.SPACESHIP_W, Global.REPAIR_SIZE)); // bottom
    return_zones.add(new Rectangle(actual.topleft.x, actual.topleft.y - Global.REPAIR_SIZE, Global.SPACESHIP_W, Global.REPAIR_SIZE)); // top
    return_zones.add(new Rectangle(actual.topright.x, actual.topright.y, Global.REPAIR_SIZE, Global.SPACESHIP_H)); // right
    return_zones.add(new Rectangle(actual.topleft.x - Global.REPAIR_SIZE, actual.topright.y, Global.REPAIR_SIZE, Global.SPACESHIP_H)); // left
    
    available = new Resources();
    if (Global.DEMO_MODE)
    {
      available.iron = 20000;
      available.crystal = 20000;
      available.gas = 20000;
      available.lead = 20000;
    }
    
    // test ending states
    if (Global.RANDOMIZE_REPAIRED)
    {
      hull.level_cur = (int) random(0,4);
      life.level_cur = (int) random(0,4);
      shield.level_cur = (int) random(0,4);
      thrust.level_cur = (int) random(0,4);
    }
    
    res_growth = new Timer(Global.RESOURCE_REPLISH);
  }
  
  void grow_storage()
  {
    available.iron += available.iron * Global.RESOURCE_GROWTH_RATE;
    available.crystal += available.crystal * Global.RESOURCE_GROWTH_RATE;
    available.gas += available.gas * Global.RESOURCE_GROWTH_RATE;
    available.lead += available.lead * Global.RESOURCE_GROWTH_RATE;
  }
  
  boolean hasHull() { return hull.level_cur > 0; }
  boolean hasLifeSupport() { return life.level_cur > 0; }
  boolean hasThrusters() { return thrust.level_cur > 0; }
  boolean hasShields() { return shield.level_cur > 0; }
  
  boolean containsPart(float x, float y)
  {
    boolean inHull = repair_hull.contains(x,y);
    boolean inLife = repair_life.contains(x,y); 
    boolean inThrust = repair_thrust.contains(x,y); 
    boolean inShield = repair_shield.contains(x,y);  
    return inHull || inLife || inThrust || inShield;
  }
  
  Rectangle partRectangle(float x, float y)
  {
    boolean inHull = repair_hull.contains(x,y);
    boolean inLife = repair_life.contains(x,y); 
    boolean inThrust = repair_thrust.contains(x,y); 
    boolean inShield = repair_shield.contains(x,y);
    
    if (inHull) return repair_hull;
    if (inLife) return repair_life;
    if (inThrust) return repair_thrust;
    if (inShield) return repair_shield;
    return null;
  }
  
  // return the repair part name that contains (x,y)
  String partName(float x, float y)
  {
    if (repair_hull.contains(x, y)) return "H";
    if (repair_life.contains(x, y)) return "L";
    if (repair_shield.contains(x, y)) return "S";
    if (repair_thrust.contains(x, y)) return "T";
    return "0";
  }
  
  ShipPart getPart(float x, float y)
  {
    String name = partName(x,y);
    if (name.equals("H")) return hull;
    if (name.equals("L")) return life;
    if (name.equals("S")) return shield;
    if (name.equals("T")) return thrust;
    return null;
  }
  
  // drop off all the resources that the bots are carrying
  // iff they are within the their designated drop off zone
  void dropoff(ArrayList<Bot> drones)
  {
    for (Bot b : drones)
    {
      if (b.isDropping())
      {
        float bx = b.x();
        float by = b.y();
        if (b.dropoff_target.contains(bx, by))
        {
          available.iron += b.backpack.res.iron;
          available.crystal += b.backpack.res.crystal;
          available.gas += b.backpack.res.gas;
          available.lead += b.backpack.res.lead;
          
          b.backpack.res.iron = 0;
          b.backpack.res.crystal = 0;
          b.backpack.res.gas = 0;
          b.backpack.res.lead = 0;
        }
      }
    }
  }
  
  // check the number of bots that are contained within each pair
  // for each additional bot, the amount of resources used halves
  void repair(ArrayList<Bot> drones)
  {
    ArrayList<Bot> inHull = new ArrayList<Bot>();
    ArrayList<Bot> inLife = new ArrayList<Bot>();
    ArrayList<Bot> inThrust = new ArrayList<Bot>();
    ArrayList<Bot> inShield = new ArrayList<Bot>();
    
    for(Bot b: drones)
    {
      if (b.isRepairing())
      {
        float bx = b.x();
        float by = b.y();
        if (b.repair_target.contains(bx, by)) // make sure it is the one we are targeting
        {
          if (repair_hull.contains(bx, by)) inHull.add(b);
          if (repair_life.contains(bx, by)) inLife.add(b);
          if (repair_thrust.contains(bx, by)) inThrust.add(b);
          if (repair_shield.contains(bx, by)) inShield.add(b);
        }
      }
    }
    
    if (inHull.size() > 0)
    {
      float multi = repairMultiplier(inHull.size()-1);
      for (Bot b : inHull) hull.repair(b, available, multi); 
    }
    
    if (inLife.size() > 0)
    {
      float multi = repairMultiplier(inLife.size()-1);
      for (Bot b : inLife) life.repair(b, available, multi); 
    }
    
    if (inThrust.size() > 0)
    {
      float multi = repairMultiplier(inThrust.size()-1);
      for (Bot b : inThrust) thrust.repair(b, available, multi); 
    }
    
    if (inShield.size() > 0)
    {
      float multi = repairMultiplier(inShield.size()-1);
      for (Bot b : inShield) shield.repair(b, available, multi); 
    }
  }
  
  float repairMultiplier(int i)
  {
    switch(i)
    {
      case 0: return 1;
      case 1: return 1.10;
      case 2: return 1.25;
      case 3: return 1.50;
    }
    return pow(2, i);
  }
  
  void displayRepairZones(PGraphics g)
  {
    g.fill(220, 220, 220, 220);
    g.rect(repair_hull.bottomleft.x, repair_hull.bottomleft.y, repair_hull.width(), repair_hull.height());
    g.rect(repair_life.bottomleft.x, repair_life.bottomleft.y, repair_life.width(), repair_life.height());
    g.rect(repair_thrust.bottomleft.x, repair_thrust.bottomleft.y, repair_thrust.width(), repair_thrust.height());
    g.rect(repair_shield.bottomleft.x, repair_shield.bottomleft.y, repair_shield.width(), repair_shield.height());
  }
  
  void displayDropoffZones(PGraphics g)
  {
    g.fill(0, 0, 255, 25);
    for(Rectangle r : return_zones) g.rect(r.bottomleft.x, r.bottomleft.y, r.width(), r.height());
  }
  
  void displayResources()
  {
    image(iron, width/2 - 60, height - Global.HUD_HEIGHT + 135);
    image(crystal, width/2 + 60, height - Global.HUD_HEIGHT + 135);
    image(gas, width/2 - 60, height - Global.HUD_HEIGHT + 200);
    image(lead, width/2 + 60, height - Global.HUD_HEIGHT + 200);
    
    fill(255);
    text("Stored Resources", width/2 - 50, height-Global.HUD_HEIGHT + 120);
    text(((int)available.iron), width/2 - 60, height - Global.HUD_HEIGHT + 135 + 48);
    text(((int)available.crystal), width/2 + 60, height - Global.HUD_HEIGHT + 135 + 48);
    text(((int)available.gas), width/2 - 60, height - Global.HUD_HEIGHT + 200 + 48);
    text(((int)available.lead), width/2 + 60, height - Global.HUD_HEIGHT + 200 + 48);
  }
}


public class ShipPart
{
  String strName;

  Resources construct; // amount of resources that are currently put into this part
  ArrayList<Resources> level_limits; // the amount of resources required per level
  ArrayList<PGraphics> restored_imgs; // images of restoration at each level
  
  int level_max;
  int level_cur;
  
  public ShipPart(String s)
  {
    strName = s;

    construct = new Resources();
    level_limits = new ArrayList<Resources>();
    restored_imgs = new ArrayList<PGraphics>();
    
    level_max = 2; // completely repaired, default we have three levels
    level_cur = 0; // does not exist
  }
  
  boolean fully_repaired() { return level_cur > 2; }
  
  String condition()
  {
    if (level_cur == 1) return "Damaged";
    if (level_cur == 2) return "Fragile";
    if (level_cur > 2) return "Repaired"; 
    return "Broken";
  }
  
  // return true if the input resources were used to repair this ship part
  boolean repair(Resources r, float factor)
  {
    boolean usedResources = false;
    if (level_cur <= level_max)
    {
      Resources lim = level_limits.get(level_cur);
      
      if (lim.iron > 0 && construct.iron < lim.iron && r.iron > 0)
      {
        if (construct.iron + factor >= lim.iron) construct.iron = lim.iron;
        else construct.iron += factor;
        r.iron -= 1;
        usedResources = true;
      }
      
      if (lim.crystal > 0 && construct.crystal < lim.crystal && r.crystal > 0)
      {
        if (construct.crystal + factor >= lim.crystal) construct.crystal = lim.crystal;
        else construct.crystal += factor;
        r.crystal -= 1;
        usedResources = true;
      }
      
      if (lim.gas > 0 && construct.gas < lim.gas && r.gas > 0)
      {
        if (construct.gas + factor >= lim.gas) construct.gas = lim.gas;
        else construct.gas += factor;
        r.gas -= 1;
        usedResources = true;
      }
      
      if (lim.lead > 0 && construct.lead < lim.lead && r.lead > 0)
      {
        if (construct.lead + factor >= lim.lead) construct.lead = lim.lead;
        else construct.lead += factor;
        r.lead -= 1;
        usedResources = true;
      }
    }
    
    return usedResources;
  }
  
  // repair the ship pair using the bots resources if it has any
  // if not repair it using the input resources
  void repair(Bot b, Resources r, float factor)
  {
    boolean usedBotResources = repair(b.backpack.res, factor);
    if (usedBotResources == false) repair(r, factor); // bot had no resources? attempt to repair using the input resources
    
    // check if all conditions for leveling up are meet
    if (level_cur <= level_max)
    {
      Resources lim = level_limits.get(level_cur);
      boolean fullIron = construct.iron == lim.iron;
      boolean fullCrystal = construct.crystal == lim.crystal;
      boolean fullGas = construct.gas == lim.gas;
      boolean fullLead = construct.lead == lim.lead;
      
      if (fullIron && fullCrystal && fullGas && fullLead && level_cur <= level_max)
      {
        construct.iron = 0;
        construct.crystal = 0;
        construct.gas = 0;
        construct.lead = 0;
        level_cur++;
      }
    }
  }
  
  void displayRemaining(float xoff, float yoff)
  {
    if (level_cur <= level_max)
    {
      Resources required = level_limits.get(level_cur);
      text("["+condition()+"] " + strName, xoff, height - Global.HUD_HEIGHT + yoff);
      
      // icons
      image(iron, xoff, height - Global.HUD_HEIGHT + yoff);
      image(crystal, xoff, height - Global.HUD_HEIGHT + yoff + 32);
      image(gas, xoff, height - Global.HUD_HEIGHT + yoff + 2*32);
      image(lead, xoff, height - Global.HUD_HEIGHT + yoff  + 3*32);
      
      // countdowns?
      text(" " + ((int)construct.iron) + "/" + ((int)required.iron), xoff + 32, height - Global.HUD_HEIGHT + yoff + 24);    
      text(" " + ((int)construct.crystal) + "/" + ((int)required.crystal), xoff + 32, height - Global.HUD_HEIGHT + yoff + 32 + 24);
      text(" " + ((int)construct.gas) + "/" + ((int)required.gas), xoff + 32, height - Global.HUD_HEIGHT + yoff + 2*32 + 24);
      text(" " + ((int)construct.lead) + "/" + ((int)required.lead), xoff + 32, height - Global.HUD_HEIGHT + yoff + 3*32 + 24);
    }
    else
    {
      text("["+condition()+"] " + strName, xoff, height - Global.HUD_HEIGHT + yoff);
    }

  }
}

public class Hull extends ShipPart
{
  public Hull()
  {
    super("Hull");
    
    Resources lvl_1 = new Resources();
    lvl_1.iron    = 2000;
    lvl_1.crystal = 400;
    
    Resources lvl_2 = new Resources();
    lvl_2.iron    = 4000;
    lvl_2.crystal = 600;
    lvl_2.gas     = 400;

    Resources lvl_3 = new Resources();
    lvl_3.iron    = 8000;
    lvl_3.crystal = 800;
    lvl_3.gas     = 600;
    lvl_3.lead    = 400;
    
    level_limits.add(lvl_1);
    level_limits.add(lvl_2);
    level_limits.add(lvl_3);
  }

  void displayRemaining(float xoff, float yoff)
  {
    super.displayRemaining(xoff, yoff);
    image(hull_img2x, xoff + 120, height - Global.HUD_HEIGHT + yoff + 60);
  }
}

public class LifeSupport extends ShipPart
{
  public LifeSupport()
  {
    super("Life Support");
    
    Resources lvl_1 = new Resources();
    lvl_1.iron    = 500;
    lvl_1.crystal = 500;
    lvl_1.gas     = 500;
    lvl_1.lead    = 500;
    
    Resources lvl_2 = new Resources();
    lvl_2.iron    = 1000;
    lvl_2.crystal = 1000;
    lvl_2.gas     = 1000;
    lvl_2.lead    = 1000;

    Resources lvl_3 = new Resources();
    lvl_3.iron    = 2500;
    lvl_3.crystal = 2500;
    lvl_3.gas     = 2500;
    lvl_3.lead    = 2500;    
    
    level_limits.add(lvl_1);
    level_limits.add(lvl_2);
    level_limits.add(lvl_3);
  }
  
  void displayRemaining(float xoff, float yoff)
  {
    super.displayRemaining(xoff, yoff);
    image(life_img2x, xoff + 145, height - Global.HUD_HEIGHT + yoff + 60);
  }
}

public class Thrusters extends ShipPart
{
  public Thrusters()
  {
    super("Thrusters");
    
    Resources lvl_1 = new Resources();
    lvl_1.iron    = 500;
    lvl_1.crystal = 200;
    lvl_1.gas     = 2000;
    lvl_1.lead    = 200;
    
    Resources lvl_2 = new Resources();
    lvl_2.iron    = 1000;
    lvl_2.crystal = 400;
    lvl_2.gas     = 4000;
    lvl_2.lead    = 200;

    Resources lvl_3 = new Resources();
    lvl_3.iron    = 1500;
    lvl_3.crystal = 600;
    lvl_3.gas     = 8000;
    lvl_3.lead    = 200;
    
    level_limits.add(lvl_1);
    level_limits.add(lvl_2);
    level_limits.add(lvl_3);
  }
  
  void displayRemaining(float xoff, float yoff)
  {
    super.displayRemaining(xoff, yoff);
    image(thrust_img2x, xoff + 120, height - Global.HUD_HEIGHT + yoff + 60);
  }
}

public class RadiationShields extends ShipPart
{
  public RadiationShields()
  {
    super("Rad. Shields");
    
    Resources lvl_1 = new Resources();
    lvl_1.iron    = 1000;
    lvl_1.crystal = 200;
    lvl_1.lead    = 2000;
    
    Resources lvl_2 = new Resources();
    lvl_2.iron    = 2000;
    lvl_2.crystal = 400;
    lvl_2.lead    = 4000;

    Resources lvl_3 = new Resources();
    lvl_3.iron    = 4000;
    lvl_3.crystal = 600;
    lvl_3.lead    = 6000;
    
    level_limits.add(lvl_1);
    level_limits.add(lvl_2);
    level_limits.add(lvl_3);
  }
  
  void displayRemaining(float xoff, float yoff)
  {
    super.displayRemaining(xoff, yoff);
    image(shield_img2x, xoff + 145, height - Global.HUD_HEIGHT + yoff + 60);
  }  
}

