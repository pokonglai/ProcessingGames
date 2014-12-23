public class Monster extends Entity
{
  static final color CLR_Target_RandomWalk  = #9C00FF; // purple
  static final color CLR_Target_Chasing     = #B7001C; // blood red
  static final color CLR_Target_Searching   = #FFAF00; // orange
  
  static final color CLR_Regular_RandomWalk  = #2CF064; // green
  static final color CLR_Regular_Chasing     = #F0980B; // orange
  static final color CLR_Regular_Searching   = #F0EA0B; // yelow
  
  static final int UNSTUCK_TIMEOUT = 120; // number of frames we wait if we find ourselves stuck when random walking
  
  static final short TYPE_chaser    = 0x0001; // chase players when they are in range, only type implemented thus far
  static final short TYPE_suicide   = 0x0002; // extremely fast, chase players when they are in range, once close enough explode
  static final short TYPE_shooter   = 0x0004; // keeps away from the player pelting them with particles
  static final short TYPE_caster    = 0x0008; // same thing as shooter except teleports away, then stands still and shoots

  static final short STATE_chase    = 0x0001; // chase the target
  static final short STATE_search   = 0x0002; // search within the last known location
  static final short STATE_random   = 0x0004; // actually selecting a path
  
  float tar_x, tar_y; // move towards tar_x and tar_y 
  float search_radius; // maximum radius that the monster will look when targeting the player
  float found_radius; // maximum search radius that the monster will search AFTER it has lost the player
  
  int search_amt; // amount of frames the monster will search within tar_x, tar_y (searching still needs to be implemented, it just stands there atm)
  short state;
  short type;
  
  ArrayList<GraphNode> cur_path;
  int path_index;
  
  color clr_randomwalk;
  color clr_chasing;
  color clr_searching;
  
  ArrayList<PVector> laststeps;
  int stepcounter;
  
  public Monster(float x, float y, float radius)
  {
    super(x, y, radius);
    name = "Monster";
    
    clr_randomwalk = CLR_Regular_RandomWalk;
    clr_chasing    = CLR_Regular_Chasing;
    clr_searching  = CLR_Regular_Searching;
    
    type = TYPE_chaser;
    
    tar_x = 0;
    tar_y = 0;
    
    search_radius = Global.DEFAULT_RADIUS_SEARCH;
    found_radius = Global.DEFAULT_RADIUS_FOUND;
    
    search_amt = 0;
    
    cur_path = new ArrayList<GraphNode>();
    path_index = 0;
    
    laststeps = new ArrayList<PVector>();
    stepcounter = 0;
    
    setGroupIndex(-1); // TODO: find a way to have monsters collide with each other and not get stuck
    setState_RandomWalk();
  }
  
  void setState_RandomWalk()
  {
    state = STATE_random;
    setFill(red(clr_randomwalk), green(clr_randomwalk), blue(clr_randomwalk));
    search_amt = 120;
  }
  
  void setState_Chase()
  {
    state = STATE_chase;
    setFill(red(clr_chasing), green(clr_chasing), blue(clr_chasing));
    search_amt = 120;
  }
  
  void setState_Search()
  {
    state = STATE_search;
    setFill(red(clr_searching), green(clr_searching), blue(clr_searching));
    search_amt = 120; // wait for two seconds
    setVelocity(0,0); // TODO: actually search within the found_radius, for now just stay still
  }
  
  boolean isWalking() { return state == STATE_random; }
  boolean isChasing() { return state == STATE_chase; }
  boolean isSearching() { return state == STATE_search; }
  
  // if the light switch is on, all the monsters will be on perma-search mode
  // randomly select a spotlight, find the closest graph node, then move towards it
  // if the player AND the monster is within the spotlights, immediately chase them
  void search(Entity player, AIDirector ai, Floor f)
  {
    // lights are on, they can seeee you
    if (f.lightswitch.selected)
    {
      for (int i = 0; i < floor.spotlights.size(); i++)
      {
        PVector p = floor.spotlights.get(i);
        float radius = Global.DEFAULT_FLARE_SIZE;
        if (i >= floor.spotlights.size()-2) radius = Global.DEFAULT_TORCH_SIZE; // last two spotlights will always be the exit and the switch
        
        boolean mInRange = checkRange(this, p.x, p.y, radius);
        boolean pInRange = checkRange(player, p.x, p.y, radius);
        if (mInRange && pInRange)
        {
          tar_x = player.x();
          tar_y = player.y();
          setState_Chase();
          moveToTarget();
          return;
        } 
      }
    }

    // otherwise check to see if the player is within the monsters search radius
    boolean inSearchRange = checkRange(player, search_radius);
    boolean inFoundRange = checkRange(player, found_radius);
    
    // no particular target yet? search and target
    if (isWalking())
    {
      if (inSearchRange) // player is within the search radius? chase them down!
      {
        tar_x = player.x();
        tar_y = player.y();
        setState_Chase(); // use the players coordinates directly
        moveToTarget();
      }
      else
      {
        // not in range, currently in random walk mode, keep walking if we still have a path        
        if (cur_path.size() > 0)
        {
          if (onTarget(Global.DEFAULT_IN_TARGET_RANGE))
          {
            GraphNode n = cur_path.remove(0);
            tar_x = n.xf();
            tar_y = n.yf();
          }
          else moveToTarget();
        }
        else
        {
          if (f.lightswitch.selected)
          {
            int index = (int) random(0, f.spotlights.size());
            PVector spotlight = f.spotlights.get(index);
            findPathTo(ai, spotlight.x, spotlight.y);
          }
          else findRandomPath(ai);
        }
      }
    }
    
    // already chasing the player
    if (isChasing())
    {
      if (inSearchRange) // still in range? keep chasing
      {
        tar_x = player.x();
        tar_y = player.y();
        setState_Chase();
        moveToTarget();
      }
      else
      {
        if (onTarget(Global.DEFAULT_IN_TARGET_RANGE)) setState_Search();
        else moveToTarget();
      }
    }
    
    // searching around tar_x and tar_y
    if (isSearching())
    {
      if (inSearchRange)
      {
        tar_x = player.x();
        tar_y = player.y();
        setState_Chase();
        moveToTarget();
      }
      else
      {
        search_amt--;
        if (search_amt == 0)
        {
          // lights are turned on? find a random light and move towards it
          if (f.lightswitch.selected)
          {
            int index = (int) random(0, f.spotlights.size());
            PVector spotlight = f.spotlights.get(index);
            findPathTo(ai, spotlight.x, spotlight.y);
          }
          else findRandomPath(ai);
        
          
          setState_RandomWalk();
        }
      }
    }
    
    // update the last steps list
    if (stepcounter == 0)
    {
      if (laststeps.size() > 3) laststeps.remove(0);
      laststeps.add(new PVector(x(), y()));
    }
    stepcounter = (stepcounter + 1) % 20;
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

    cur_path = new ArrayList<GraphNode>(path.length);
    for (int i = 0; i < path.length; i++) cur_path.add(path[i]);
    
    GraphNode target = cur_path.remove(0);
    tar_x = target.xf();
    tar_y = target.yf();
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

    cur_path = new ArrayList<GraphNode>(path.length);
    for (int i = 0; i < path.length; i++) cur_path.add(path[i]);
    
    GraphNode target = cur_path.remove(0);
    tar_x = target.xf();
    tar_y = target.yf();
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
    setVelocity(dir.x * stats.MOV_SPD() * 75, dir.y * stats.MOV_SPD() * 75);
  }
  
  void displayCurrentPath()
  {
    for (GraphNode n : cur_path) ellipse(n.xf(), n.yf(), 3, 3);
  }
}
