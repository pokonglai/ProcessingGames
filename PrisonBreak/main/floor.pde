public class Floor
{
  ArrayList<WallBlock> obstacles;
  ArrayList<Monster> monsters;
  
  Exit exit;
  Switch lightswitch;
  ArrayList<PVector> spotlights; // lights attached to the obstacles
  
  PGraphics darkness; // image area to dark regions

  public Floor(boolean autoGenerate)
  {
    init();
    
    if (autoGenerate)
    {
      generate((int)random(Global.MIN_BLOCK, Global.MAX_BLOCK));
    }
    
    placeExit();
    placeSwitch();
    
    // add spotlights to exit and switch
    spotlights.add(new PVector(exit.x() + exit.width()/2, exit.y() - exit.height()/2));
    spotlights.add(new PVector(lightswitch.x() + lightswitch.width()/2, lightswitch.y() - lightswitch.height()/2));
  }
  
  private void init()
  {
    obstacles = new ArrayList<WallBlock>();
    monsters = new ArrayList<Monster>();
    spotlights = new ArrayList<PVector>();
  }
  
  void generate(int nObstacles)
  {
    // generate all the obstacles
    for (int i = 1; i <= nObstacles; i++)
    {
      boolean found_space = false;
      while(found_space == false)
      {
        int n = (int)random(Global.MIN_BLOCK_WIDTH, Global.MAX_BLOCK_WIDTH);
        int m = (int)random(Global.MIN_BLOCK_WIDTH, Global.MAX_BLOCK_HEIGHT);
        
        float max_width = n * Global.WALL_THICKNESS;
        float max_height = m * Global.WALL_THICKNESS;
        
        float loc_x = random(Global.EDGE_PADDING + max_width, width - Global.EDGE_PADDING - max_width);
        float loc_y = random(Global.EDGE_PADDING + max_height, height - Global.EDGE_PADDING - max_height);
        
        WallBlock candidate = new WallBlock(loc_x, loc_y, max_width, max_height);
        
        boolean addBlock = true;
        for(WallBlock wb : obstacles)
        {
          if (wb.outer.overlap(candidate.outer) || candidate.outer.overlap(wb.outer))
          {
            addBlock = false;
            break;
          }
        }
        
        if (addBlock)
        {
          obstacles.add(candidate);
          found_space = true;
        }
      }
    }
    
    // attach a spotlight to each obstacle
    for (WallBlock wb : obstacles)
    {
      // flip a coin, if true, place a spotlight
//      if (random(1) < 0.5)
      if (random(1) <= 1)
      { 
        // select a random corner
        int corner = (int)random(0, 4);
        PVector loc = new PVector();
        switch (corner)
        {
          case 0: loc = wb.actual.topleft; break;
          case 1: loc = wb.actual.bottomright; break;
          case 2: loc = wb.actual.bottomleft; break;
          case 3: loc = wb.actual.topright; break;
          default: break;
        }
        spotlights.add(loc);
      }
    }
  }
  
  void updateGameState(Entity player)
  {
    exit.updateGameState(this, player);
    lightswitch.hover(player);
  }
  
  // always place the exit at the middle right
  void placeExit()
  {
    float loc_x = 0;
    float loc_y = 0;
    boolean placed = false;
    exit = new Exit(width-Global.EXIT_SIZE, 0);
  }
  
  // place a switch at a random location such that it does not overlap with rectangles
  void placeSwitch()
  {
    float loc_x = 0;
    float loc_y = 0;
    boolean placed = false;
    while(placed == false)
    {
      loc_x = random(Global.EDGE_PADDING, width - Global.EDGE_PADDING);
      loc_y = random(Global.EDGE_PADDING, height - Global.EDGE_PADDING);
      Rectangle tmp = new Rectangle(loc_x, loc_y, Global.EXIT_SIZE, Global.EXIT_SIZE);
      boolean noOverlap = true;
      for(WallBlock wb : obstacles) noOverlap = noOverlap && (wb.outer.overlap(tmp) == false);
      if (noOverlap)
      {
        placed = true;
        break;
      }
    }
    lightswitch = new Switch(loc_x, loc_y);
  }
}


