public class Floor
{
  ArrayList<PVector> spotlights; // lights for day night cycle?
  ArrayList<WallBlock> obstacles;
  
  
  // resource related
  ArrayList<ResourceDeposit> deposits;
  ArrayList<PVector> drop_off;
  
//  HashMap<Integer, Bot> drones;
  ArrayList<Bot> drones;
  
  Spaceship spaceship;
  
  public Floor(boolean autoGenerate)
  {
    init();
    
    if (autoGenerate)
    {
      generate(8);
    }
  }
  
  private void init()
  {
    spotlights = new ArrayList<PVector>();
    obstacles = new ArrayList<WallBlock>();
    
    deposits = new ArrayList<ResourceDeposit>();
    drop_off = new ArrayList<PVector>();
    
    drones = new ArrayList<Bot>();
    
    spaceship = new Spaceship();
    
    // spawn drones on the four sides of the ship
    Rectangle r = spaceship.outer;
    drones.add(new Bot(r.topleft.x, r.topleft.y, Global.PLAYER_SIZE, 1));
    drones.add(new Bot(r.topright.x, r.topright.y, Global.PLAYER_SIZE, 2));
    drones.add(new Bot(r.bottomleft.x, r.bottomleft.y, Global.PLAYER_SIZE, 3));
    drones.add(new Bot(r.bottomright.x, r.bottomright.y, Global.PLAYER_SIZE, 4));
  }
  
  void generate(int num)
  {
    // fill out the terrain with resources at a random distance from the central location
    for(int i = 0; i < num; i++)
    {
      boolean placed = false;
      while(placed == false)
      {
        float loc_x = 0;
        float loc_y = 0;
        loc_x = random(Global.EDGE_PADDING, width - Global.EDGE_PADDING);
        loc_y = random(Global.EDGE_PADDING, height - Global.HUD_HEIGHT - Global.EDGE_PADDING);
        
        int kind = (int)random(0, 5);
        
        ResourceDeposit tmp_res = new ResourceDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE);
        
        boolean addResource = true;
        for (ResourceDeposit res : deposits)
        {
          if (res.collection_range.overlap(tmp_res.collection_range) || tmp_res.collection_range.overlap(res.collection_range))
          {
            addResource = false;
            break;
          }
        }
        
        if (addResource)
        {
          // make sure not to place a deposit too close to the ship
          if (spaceship.zone_range.overlap(tmp_res.collection_range) == false && tmp_res.collection_range.overlap(spaceship.zone_range) == false)
          {
            switch(i % 4)
            {
              case 0: deposits.add(new IronDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE)); break;
              case 1: deposits.add(new CrystalDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE)); break;
              case 2: deposits.add(new GasDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE)); break;
              case 3: deposits.add(new LeadDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE)); break;
              default: deposits.add(new ResourceDeposit(loc_x, loc_y,  Global.DEPOSIT_SIZE,  Global.DEPOSIT_SIZE)); break;
            }
            placed = true;
          }
        }
      }
    }
    // always ensure there is at least two that are a certain radius away
  }
  
  // if a resource is contained in (x,y), return that resource
  ResourceDeposit findDeposit(float x, float y)
  {
    ResourceDeposit res = null;
    for (ResourceDeposit r : deposits)
    {
      if (r.contains(mouseX, mouseY))
      {
        res = r;
        break;
      }
    }
    return res;
  }
}


