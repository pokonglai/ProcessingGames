public class Bot extends Entity
{  
  static final color CLR_Regular_RandomWalk  = #2CF064; // green
  static final color CLR_Regular_Chasing     = #F0980B; // orange
  static final color CLR_Regular_Searching   = #F0EA0B; // yelow
  
  static final int UNSTUCK_TIMEOUT = 120; // number of frames we wait if we find ourselves stuck when random walking

  static final short STATE_idle      = 0x0001; // do nothing
  static final short STATE_gathering = 0x0002; // gathering resources
  static final short STATE_dropoff   = 0x0004; // dropping off resources
  static final short STATE_repairing = 0x0008; // repairing the ship
  static final short STATE_walking   = 0x0016; // moving towards the intended destination
  
  float tar_x, tar_y; // move towards tar_x and tar_y 
  
  short state;
  
  // pathing
  ArrayList<PVector> cur_path;
  int path_index;
  
  // steps
  ArrayList<PVector> laststeps;
  int stepcounter;
  
  // resource management
  ResourceDeposit res_target;
  ResourceBackpack backpack;
  Rectangle repair_target;
  Rectangle dropoff_target;
  
  boolean active;
  int number;
  PVector move_location; // used for marking the location that the bot will move to
  
  public Bot(float x, float y, float radius, int n)
  {
    super(x, y, radius);
    
    name = "Drone";
    number = n;
    
    tar_x = 0;
    tar_y = 0;
    
    cur_path = new ArrayList<PVector>();
    path_index = 0;
    
    laststeps = new ArrayList<PVector>();
    stepcounter = 0;
    
    res_target = null;
    backpack = new ResourceBackpack(100, 100, 100, 100);
    repair_target = null;
    dropoff_target = null;
    
    setGroupIndex(-1); // TODO: find a way to have monsters collide with each other and not get stuck
    
    active = false;
    move_location = null;
    
    setFill(150);
    setState_Idle();
  }
  
  void setState_Idle()
  {
    state = STATE_idle;
    setVelocity(0,0);
  }
  
  void setState_Gather()
  {
    state = STATE_gathering;
    setVelocity(0,0);
  }
  
  void setState_DropOff()
  {
    state = STATE_dropoff;
  }
  
  void setState_Repair()
  {
    state = STATE_repairing;
  }
  
  void setState_Walk()
  {
    state = STATE_walking;
  }
  
  boolean isIdle() { return state == STATE_idle; }
  boolean isGathering() { return state == STATE_gathering; }
  boolean isDropping() { return state == STATE_dropoff; }
  boolean isRepairing() { return state == STATE_repairing; }
  boolean isWalking() { return state == STATE_walking; }
  
  void update()
  {  
    // got a path? move the bot    
    if (cur_path.size() > 0)
    {
      if (onTarget(Global.DEFAULT_IN_TARGET_RANGE))
      {
        PVector v = cur_path.remove(0);
        tar_x = v.x;
        tar_y = v.y;
      }
      else moveToTarget();
      if (isRepairing() == false && isDropping() == false) setState_Walk();
    }
    
    // no path? gather resources if we have a target
    else
    {
      if (res_target != null)
      {
        backpack.addResource(res_target.name, res_target.rate());
        setState_Gather();
      }
      
      else if (repair_target != null)
      {
        setState_Repair();
      }
      else if (dropoff_target != null)
      {
        setState_DropOff();
      }
      else 
      {
        setState_Idle();
      }
      move_location = null;
    }
    
    // update the last steps list
    if (stepcounter == 0)
    {
      if (laststeps.size() > 3) laststeps.remove(0);
      laststeps.add(new PVector(x(), y()));
    }
    stepcounter = (stepcounter + 1) % 5;
  }
  
  void findRandomPath(AIDirector ai)
  {
    // select a random position within the bounds
    GraphNode closest = ai.closestNode(x(), y());
    
    GraphNode[] path = null;
    while(path == null || path.length == 0)
    {
      GraphNode n = ai.randomNode();
      ai.pathfinder.search(closest.id(), n.id());
      path = ai.pathfinder.getRoute();
    }

    cur_path = new ArrayList<PVector>(path.length);
    for (int i = 0; i < path.length; i++) cur_path.add(new PVector(path[i].xf(), path[i].yf()));
    
    PVector target = cur_path.remove(0);
    tar_x = target.x;
    tar_y = target.y;
    moveToTarget();
  }
  
  void findPathTo(AIDirector ai, float x, float y)
  {
    // select a random position within the bounds
    GraphNode closest = ai.closestNode(x(), y());
    
    GraphNode[] path = null;
    while(path == null || path.length == 0)
    {
      GraphNode n = ai.closestNode(x, y);
      ai.pathfinder.search(closest.id(), n.id());
      path = ai.pathfinder.getRoute();
    }

    cur_path = new ArrayList<PVector>(path.length);
    for (int i = 0; i < path.length; i++) cur_path.add(new PVector(path[i].xf(), path[i].yf()));
    cur_path.add(new PVector(x, y));
    
    PVector target = cur_path.remove(0);
    tar_x = target.x;
    tar_y = target.y;
    moveToTarget();
  }
  
  boolean onTarget(float radius)
  {
    float dx = x() - tar_x;
    float dy = y() - tar_y;
    float dist = sqrt(dx*dx + dy*dy);
    return dist < radius;
  }
  
  // move towards tar_x, tar_y
  // determine direction vector from this to tar_x, tar_y then set the velocity
  void moveToTarget()
  {
    PVector dir = new PVector(tar_x - x(), tar_y - y());
    dir.normalize();
    setVelocity(dir.x * stats.MOV_SPD() * 150, dir.y * stats.MOV_SPD() * 150);
  }
  
  void displayCurrentPath(PGraphics g)
  {
    for (PVector v : cur_path) g.ellipse(v.x, v.y, 3, 3);
  }
  
  void displayResources(float yoff)
  {
    float xloc = width - 350;
    float yloc = height - Global.HUD_HEIGHT + 20 + yoff;
    float xspace = 80; // space for the bar or text
    text(name + " " + number + ": ", xloc, yloc);
    
    float icon_init_x = xloc+75;
    image(iron, icon_init_x, yloc - 20);
    image(crystal, icon_init_x, yloc - 20 + 32);
    
    if (backpack.isFull("Iron")) fill(0, 255, 0);
    else fill(255);
    text(" "+((int)backpack.res.iron)+"/"+((int)backpack.limits.iron), icon_init_x + 32, yloc);
    
    if (backpack.isFull("Crystal")) fill(0, 255, 0);
    else fill(255);
    text(" "+((int)backpack.res.crystal)+"/"+((int)backpack.limits.crystal), icon_init_x + 32, yloc + 32);
    
    image(gas, icon_init_x + 32 + xspace, yloc - 20);
    image(lead, icon_init_x + 32 + xspace, yloc - 20 + 32);
    
    if (backpack.isFull("Gas")) fill(0, 255, 0);
    else fill(255);
    text(" "+((int)backpack.res.gas)+"/"+((int)backpack.limits.iron), icon_init_x + 2*32 + xspace, yloc);
    
    if (backpack.isFull("Lead")) fill(0, 255, 0);
    else fill(255);
    text(" "+((int)backpack.res.lead)+"/"+((int)backpack.limits.crystal), icon_init_x + 2*32 + xspace, yloc + 32);
  }
  
  void displayOffline(float yoff)
  {
    float xloc = width - 350;
    float yloc = height - Global.HUD_HEIGHT + 20 + yoff;
    float xspace = 80; // space for the bar or text
    text(name + " " + number + " OFFLINE", xloc, yloc);
  }
}
