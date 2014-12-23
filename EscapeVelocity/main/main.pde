import java.util.Collections;
import fisica.*;
import pathfinder.*;

// ui variables
InstructionScreen instructions;
GameOverScreen gameover;

// game world variables
FWorld world;
Floor floor; 

AIDirector director;

// helper variables
short state;
float ship_rotation;
PVector launch_location;

// frame buffers
PGraphics buffer;
PGraphics graph_img;

// bot selections
ArrayList<Bot> selected_bots;
PVector select_TL;
PVector select_BR;
PVector move_location; // to render a movement rectangle
ArrayList<PVector> move_locations; // for multiple bots moving at once, use the z coordinate to store the drone number

// images
PImage iron;
PImage lead;
PImage gas;
PImage crystal;

PImage hull_img;
PImage life_img;
PImage shield_img;
PImage thrust_img;

PImage hull_img2x;
PImage life_img2x;
PImage shield_img2x;
PImage thrust_img2x;

ArrayList<PImage> parts_hull;
ArrayList<PImage> parts_life;
ArrayList<PImage> parts_shield;
ArrayList<PImage> parts_thrust;

PImage hud_bg;

// bot costs
ArrayList<Resources> bot_costs; // only contains three values since the first bot is always active
int nextBotIndex; // next drone to be activated, index is wrt to the bot_costs

void setup()
{
  initProcessing();
  initGUI();
  initWorld();

  state = Global.GAME_STATE_title;
}

// initialize the processing environment and basic game variables
void initProcessing()
{
  size(Global.APP_WIDTH, Global.APP_HEIGHT);
  frame.setTitle("Escape Velocity");
  
  // frame buffer
  buffer = createGraphics(width, height);
  buffer.imageMode(CENTER);
  buffer.beginDraw();
  buffer.smooth();
  buffer.noStroke();
  buffer.textSize(18);
  buffer.endDraw();

  graph_img = createGraphics(width, height);
  graph_img.imageMode(CENTER);
  graph_img.beginDraw();
  graph_img.smooth();
  graph_img.noStroke();
  graph_img.endDraw(); 
  
  frameRate(60);
}

void initGUI()
{
  instructions = new InstructionScreen();
  gameover = new GameOverScreen();
  select_TL = null;
  select_BR = null;
  
  hud_bg = loadImage("img/hud.png");
  
  iron = loadImage("img/iron.png");
  lead = loadImage("img/lead.png");
  gas = loadImage("img/gas.png");
  crystal = loadImage("img/crystal.png");
  
  hull_img = loadImage("img/hull.png");
  life_img = loadImage("img/life.png");
  shield_img = loadImage("img/shield.png");
  thrust_img = loadImage("img/thrust.png");
  
  hull_img2x = hull_img.get();
  hull_img2x.resize(hull_img.width*2, hull_img.height*2);

  life_img2x = life_img.get();
  life_img2x.resize(life_img.width*2, life_img.height*2);
  
  shield_img2x = shield_img.get();
  shield_img2x.resize(shield_img.width*2, shield_img.height*2);
  
  thrust_img2x = thrust_img.get();
  thrust_img2x.resize(thrust_img.width*2, thrust_img.height*2);
  
  parts_hull = new ArrayList<PImage>();
  parts_hull.add(loadImage("img/part_hull_broken.png"));
  parts_hull.add(loadImage("img/part_hull_damaged.png"));
  parts_hull.add(loadImage("img/part_hull_fragile.png"));
  parts_hull.add(loadImage("img/part_hull_repaired.png"));  
  
  parts_life = new ArrayList<PImage>();
  parts_life.add(loadImage("img/part_life_broken.png"));
  parts_life.add(loadImage("img/part_life_damaged.png"));
  parts_life.add(loadImage("img/part_life_fragile.png"));
  parts_life.add(loadImage("img/part_life_repaired.png"));
  
  parts_shield = new ArrayList<PImage>();
  parts_shield.add(loadImage("img/part_shield_broken.png"));
  parts_shield.add(loadImage("img/part_shield_damaged.png"));
  parts_shield.add(loadImage("img/part_shield_fragile.png"));
  parts_shield.add(loadImage("img/part_shield_repaired.png"));
  
  parts_thrust = new ArrayList<PImage>();
  parts_thrust.add(loadImage("img/part_thrust_broken.png"));
  parts_thrust.add(loadImage("img/part_thrust_damaged.png"));
  parts_thrust.add(loadImage("img/part_thrust_fragile.png"));
  parts_thrust.add(loadImage("img/part_thrust_repaired.png"));
  
  move_location = null;
  
  cursor(CROSS);
}

// create our world, fill it obstacles and monsters
void initWorld()
{
  // init Box2D world
  Fisica.init(this);
  world = new FWorld();
  world.setEdges();
  world.setGravity(0, 0);
  
  // manually remove the bottom wall and replace it with a larger bottom
  world.remove(world.bottom);
  FBox bottom = new FBox(width, Global.HUD_HEIGHT);
  bottom.setFill(0);
  bottom.setNoStroke();
  bottom.setStatic(true);
  bottom.setGrabbable(false);
  bottom.setPosition(width/2, height - Global.HUD_HEIGHT/2);
  world.add(bottom);
  
  floor = new Floor(true);
  for (WallBlock wb : floor.obstacles) world.add(wb);
  world.add(floor.spaceship);
  for (ResourceDeposit res : floor.deposits) world.add(res);
  
  // create the waypoint graph and spawn some monsters
  director = new AIDirector(Global.DEFAULT_GRAPH_DENSITY);
  director.buildGraph(floor);
  
  // first bot is free
  floor.drones.get(0).active = true;
  selected_bots = new ArrayList<Bot>();
  for (Bot b: floor.drones)
  {
    if (b.active)
    {
      world.add(b);
      selected_bots.add(b);
    }
  }
  
  // add all the costs required for each additional drone
  bot_costs = new ArrayList<Resources>();
  Resources cost_bot2 = new Resources();
  cost_bot2.iron = 200;
  cost_bot2.crystal = 200;
  cost_bot2.gas = 200;
  cost_bot2.lead = 200;
  
  Resources cost_bot3 = new Resources();
  cost_bot3.iron = 800;
  cost_bot3.crystal = 800;
  cost_bot3.gas = 800;
  cost_bot3.lead = 800;
  
  Resources cost_bot4 = new Resources();
  cost_bot4.iron = 2000;
  cost_bot4.crystal = 2000;
  cost_bot4.gas = 2000;
  cost_bot4.lead = 2000;
  
  bot_costs.add(cost_bot2);
  bot_costs.add(cost_bot3);
  bot_costs.add(cost_bot4);
  
  nextBotIndex = 0;
  
  // ending sequence variables
  ship_rotation = 0;
  launch_location = new PVector();
  
  if (Global.SHOW_GRAPH)
  {
    graph_img.beginDraw();
    graph_img.background(255);
    director.displayGraph(graph_img);
    graph_img.endDraw();
  }
}

Rectangle selectionRect()
{
  if (select_TL != null && select_BR != null)
  {
    float min_x = min(select_TL.x, select_BR.x);
    float min_y = min(select_TL.y, select_BR.y);
    float max_x = max(select_TL.x, select_BR.x);
    float max_y = max(select_TL.y, select_BR.y);
    Rectangle r = new Rectangle(min_x, min_y, max_x - min_x, max_y - min_y);
    return r;
  }
  return null;
}


boolean canActivateBot(int n)
{
  Resources cost = bot_costs.get(n);
  boolean hasIron = cost.iron <= floor.spaceship.available.iron;
  boolean hasCrystal = cost.crystal <= floor.spaceship.available.crystal;
  boolean hasGas = cost.gas <= floor.spaceship.available.gas;
  boolean hasLead = cost.lead <= floor.spaceship.available.lead;
  return hasIron && hasCrystal && hasGas && hasLead;
}

void activateBot(int n)
{
  if (n - 2 != nextBotIndex)
  {
    return;
  }
  
  if (canActivateBot(nextBotIndex))
  {
    Resources cost = bot_costs.get(nextBotIndex);
    floor.spaceship.available.iron -= cost.iron;
    floor.spaceship.available.crystal -= cost.crystal;
    floor.spaceship.available.gas -= cost.gas;
    floor.spaceship.available.lead -= cost.lead;
    
    Bot next = floor.drones.get(nextBotIndex+1);
    next.active = true;
    world.add(next);
    nextBotIndex++;
  }
}

/**
 Collision detection handlers
------------------------------
Not really used for this particular game. Possiblity for physics based enemies and obstacles in the future.
**/
void contactStarted(FContact contact) { }
void contactPersisted(FContact contact) { }
void contactEnded(FContact contact) { }

void mouseDragged()
{
  if (mouseButton == LEFT)
  {
    if (select_TL == null) select_TL = new PVector(mouseX, mouseY);
    else if (select_BR == null) select_BR = new PVector(mouseX, mouseY);
    else
    {
      select_BR.x = mouseX;
      select_BR.y = mouseY;
      
      // clamp it so that it remains within the actual playing area
      if (select_BR.x < 5) select_BR.x = 5;
      if (select_BR.x > width-5) select_BR.x = width-5;
      if (select_BR.y < 5) select_BR.y = 5;
      if (select_BR.y > height-Global.HUD_HEIGHT) select_BR.y = height-Global.HUD_HEIGHT;
    }
  }
}

void mousePressed() { }
void mouseReleased()
{
  // select bots
  // TODO: selection box goes out of bounds
  if (mouseButton == LEFT)
  {
    selected_bots.clear();
    Rectangle selection = selectionRect();
    if (selection != null)
    {
      for(Bot b : floor.drones)
      {
        if (b.active)
        {
          if (selection.contains(b.x(), b.y()))
          {
            selected_bots.add(b);
          }
        }
      }
    }

    select_TL = null;
    select_BR = null;
  }
  
  
  // perform context related actions (move, repair, deposit)
  if (mouseButton == RIGHT)
  {
    if (state == Global.GAME_STATE_ingame)
    {
      for (Bot b : selected_bots)
      {
        b.res_target = floor.findDeposit(mouseX, mouseY); // if the cursor is ontop of some resources, set the bots to collection mode
        
        // randomize the movement location
        // TODO: ensure that all locations are sufficiently sparse
        float randx = random(mouseX-10, mouseX+10);
        float randy = random(mouseY-10, mouseY+10);
        b.findPathTo(director, randx, randy); // move the currently selected unit to the target
        
        b.move_location = new PVector(randx, randy);
        move_location = new PVector(mouseX, mouseY);
        
        // first check if we are ready to repair with what we have
        Rectangle repair = floor.spaceship.partRectangle(mouseX, mouseY);
        if (repair != null)
        {
          b.repair_target = repair;
          b.setState_Repair(); 
        }
        else
        {
          b.repair_target = null;
          b.setState_Walk();
        }
        
        // next check if we are in any of the dropoff zones
        boolean bDrop = false;
        for (Rectangle dropoff : floor.spaceship.return_zones)
        {
          if (dropoff.contains(mouseX, mouseY))
          {
            bDrop = true;
            b.dropoff_target = dropoff;
            b.setState_DropOff();
            break;
          }
        }
      }
    }
  }
}


void keyPressed()
{
  
}

void keyReleased()
{
  boolean spacebar = key == ' '; 
  if (state == Global.GAME_STATE_title)
  {
    if (spacebar)
    {
      if (instructions.advanceSlide(floor))
      {
        floor.spaceship.res_growth.begin();
        gameover.countdown.begin();
        state = Global.GAME_STATE_ingame;
      }
    }
  }
  
  else if (state == Global.GAME_STATE_gameover)
  {
    if (spacebar)
    {
      initWorld(); // regenerate the world
      floor.spaceship.res_growth.begin();
      gameover.countdown.begin();
      gameover.reset();
      state = Global.GAME_STATE_ingame;
    }
  }
  
  else if (state == Global.GAME_STATE_ingame)
  {
    if (key == '1')
    {
      selected_bots.clear();
      selected_bots.add(floor.drones.get(0));
    }
    
    if (key == '2')
    {
      Bot drone2 = floor.drones.get(1);
      if (drone2.active == false) // check to see if we can activate it
      {
        activateBot(2); 
      }
      
      if (drone2.active)
      {
        selected_bots.clear();
        selected_bots.add(drone2);
      }
    }
    
    if (key == '3')
    {
      Bot drone3 = floor.drones.get(2);
      if (drone3.active == false) // check to see if we can activate it
      {
        activateBot(3); 
      }
      
      if (drone3.active)
      {
        selected_bots.clear();
        selected_bots.add(drone3);
      }
    }
    
    if (key == '4')
    {
      Bot drone4 = floor.drones.get(3);
      if (drone4.active == false) // check to see if we can activate it
      {
        activateBot(4); 
      }
      
      if (drone4.active)
      {
        selected_bots.clear();
        selected_bots.add(drone4);
      }
    }
  }
}



// move the repair bots towards their goal
// gather resources if they are at a resource deposit
// repair the spaceship if they are at the ship
void updateRepairBots()
{
  // move if they have paths
  boolean noPaths = true;
  for (Bot b : floor.drones)
  {
    b.update(); 
    if (b.cur_path.size() > 0) noPaths = false;
  }
  if (noPaths) move_location = null;
  
  floor.spaceship.repair(floor.drones);
  floor.spaceship.dropoff(floor.drones);
  
}

// check if the time is up, select the ending
void updateGameState()
{
  if (gameover.countdown.timeup())
  {
    state = Global.GAME_STATE_gameover;
    floor.spaceship.res_growth.pause();
  }

  if (state == Global.GAME_STATE_ingame)
  {
    if (floor.spaceship.res_growth.timeup())
    {
      floor.spaceship.res_growth.begin();
      floor.spaceship.grow_storage();
    }
  }  
}

void draw()
{
  noStroke();

  if (state == Global.GAME_STATE_title)
  {
    renderFrame();
    drawHUD();
    gameover.displayTime_Full();
    drawSpaceshipState();
    
    instructions.display(floor);
    
  }
  
  if (state == Global.GAME_STATE_ingame)
  {
    // update the resource reposits
    for (ResourceDeposit rd : floor.deposits)
    {
      rd.num_of_collectors = 0;
      for (Bot b : floor.drones)
      {
        if (rd.contains(b.x(), b.y()))
        {
          rd.num_of_collectors++;
        }
      }
    }
    
    updateRepairBots();
    updateGameState();
    
    renderFrame();
    drawHUD();
    
    gameover.displayCountdown();
    
    renderSelectionRect();
    drawSpaceshipState();
  }
  
  if (state == Global.GAME_STATE_gameover)
  {
    renderFrame();
    drawHUD();
    
    gameover.displayTime_Out();
    drawSpaceshipState();
    
    // first rotate the ship
    if (ship_rotation < Global.LAUNCH_ANGLE)
    {
      ship_rotation += Global.LAUNCH_INC;
      if (ship_rotation >= Global.LAUNCH_ANGLE)
      {
        launch_location = new PVector();
      }
    }
    
    // then launch it
    else if (launch_location.x >= -200 && launch_location.y >= -40)
    {
      launch_location.add(new PVector(-10,-2));
    }
    
    // once the ship has exited the screen, show the results
    else
    {
      gameover.computeResults(floor.spaceship);
      gameover.display();
    }
  }
  
  if (Global.SHOW_FPS)
  {
    fill(0);
    text(frameRate, width-70, 25);
  }

}

void renderSelectionRect()
{
  if (select_TL != null && select_BR != null)
  {
    float min_x = min(select_TL.x, select_BR.x);
    float min_y = min(select_TL.y, select_BR.y);
    float max_x = max(select_TL.x, select_BR.x);
    float max_y = max(select_TL.y, select_BR.y);
    Rectangle r = new Rectangle(min_x, min_y, max_x - min_x, max_y - min_y);
    
    fill(0, 255, 0, 100);
    rect(r.bottomleft.x, r.bottomleft.y, r.width(), r.height());
  }
}

void renderFrame()
{ 
  // draw all Box2D objects into the frame buffer
  buffer.beginDraw();
  if (Global.SHOW_GRAPH)
  {
    buffer.image(graph_img, width/2, height/2);
  }
  else
  {
    buffer.fill(255);
    buffer.rect(0, 0, width, height);
  }
  
  buffer.fill(255, 0, 0, 100);
  floor.spaceship.displayRepairZones(buffer);
  floor.spaceship.displayDropoffZones(buffer);
  
  buffer.fill(0, 255, 0, 25);
  for (ResourceDeposit res : floor.deposits)
  {
    Rectangle r = res.collection_range;
    buffer.rect(r.bottomleft.x, r.bottomleft.y, r.width(), r.height());  
  }
  
  // render the last few steps the monsters have taken with the earliest step most faded away
  for (Bot b : floor.drones)
  {
    if (b.active)
    {
      for (int i = 0; i < b.laststeps.size(); i++)
      {
        PVector v  = b.laststeps.get(i);
        float ratio = (float)(i+1)/ 4;
        buffer.fill(150, 150, 150, ratio*255);
        buffer.ellipse(v.x, v.y, 3, 3);
      }
    }
  }

  // render icons ontop of the deposit since attachImage places the image at the topleft
  for (ResourceDeposit rd : floor.deposits)
  {
    if (rd.name.equals("Iron")) buffer.image(iron, rd.getX(), rd.getY());
    if (rd.name.equals("Lead")) buffer.image(lead, rd.getX(), rd.getY());
    if (rd.name.equals("Crystal")) buffer.image(crystal, rd.getX(), rd.getY());
    if (rd.name.equals("Gas")) buffer.image(gas, rd.getX(), rd.getY());
  }
  
  // render ship part icons ontop of their repair locations
  buffer.image(hull_img, floor.spaceship.repair_hull.bottomleft.x + Global.REPAIR_SIZE/2, floor.spaceship.repair_hull.bottomleft.y - Global.REPAIR_SIZE/2);
  buffer.image(life_img, floor.spaceship.repair_life.bottomleft.x + Global.REPAIR_SIZE/2, floor.spaceship.repair_life.bottomleft.y - Global.REPAIR_SIZE/2);
  buffer.image(shield_img, floor.spaceship.repair_shield.bottomleft.x + Global.REPAIR_SIZE/2, floor.spaceship.repair_shield.bottomleft.y - Global.REPAIR_SIZE/2);
  buffer.image(thrust_img, floor.spaceship.repair_thrust.bottomleft.x + Global.REPAIR_SIZE/2, floor.spaceship.repair_thrust.bottomleft.y - Global.REPAIR_SIZE/2);

  // render selected bots as green behind the FWorld render
  buffer.fill(0, 255, 0);
  for (Bot b : selected_bots) 
  {
    if (b.active)
    {
      buffer.ellipse(b.x(), b.y(), b.getSize()+4, b.getSize()+4);
    }
  }

  world.draw(buffer);
  
  // draw repair lines
  buffer.stroke(255, 0, 255);
  buffer.strokeWeight(2);
  for (Bot b : floor.drones)
  {
    if (b.active && b.isRepairing() && b.repair_target.contains(b.x(), b.y()))
    {
      String part = floor.spaceship.partName(b.x(), b.y());
      boolean repaired = floor.spaceship.getPart(b.x(), b.y()).fully_repaired();
      if (repaired == false) // only draw the line if it is currently being repaired
      {
        if (part.equals("H")) buffer.line(b.x(), b.y(), b.repair_target.topright.x, b.repair_target.topright.y);
        if (part.equals("L")) buffer.line(b.x(), b.y(), b.repair_target.bottomright.x, b.repair_target.bottomright.y);
        if (part.equals("S")) buffer.line(b.x(), b.y(), b.repair_target.topleft.x, b.repair_target.topleft.y);
        if (part.equals("T")) buffer.line(b.x(), b.y(), b.repair_target.bottomleft.x, b.repair_target.bottomleft.y);
      }
    }
  }
  
  // draw collection lines
  buffer.stroke(0, 0, 255);
  for (Bot b : floor.drones)
  {
    if (b.active && b.isGathering() && b.res_target.contains(b.x(), b.y()))
    {
      if (b.backpack.isFull(b.res_target.name) == false)
        buffer.line(b.x(), b.y(), b.res_target.center_x(), b.res_target.center_y()); 
    }
  }
  
  buffer.noStroke();

  // movement markers
  boolean stillMoving = false;
  buffer.fill(255, 0, 0, 175);
  for (Bot b : floor.drones)
  {
    if (b.active && b.move_location != null)
    {
      buffer.ellipse(b.move_location.x, b.move_location.y, 6, 6);
      stillMoving = true;
    }
  }
  
  // movement marker range
  buffer.fill(255, 0, 0, 25);
  if (stillMoving && move_location != null)
  {
    buffer.rect(move_location.x - 10, move_location.y - 10, 20, 20);
  }
  
  // render drone numbers 
  buffer.fill(0, 0, 0);
  for (Bot b : floor.drones) 
  {
    if (b.active)
    {
      buffer.text(b.number+"", b.x() - Global.PLAYER_SIZE/2 - 2, b.y() + Global.PLAYER_SIZE/2 + 2);
    }
  }
  
  buffer.image(hud_bg, width/2, height-Global.HUD_HEIGHT/2);
  buffer.endDraw();
  
  world.step();

  background(0); // clear the background 
  image(buffer, 0, 0); // render the frame
}

void drawHUD()
{
  fill(255);
  
  // display the bots resources
  float yoff = 64;
  boolean bFirst = true; // first bot that is not active display prices
  for (int i = 0; i < floor.drones.size(); i++)
  {
    fill(255);
    Bot b = floor.drones.get(i);
    if (b.active) b.displayResources(i*yoff);
    else if (bFirst)
    {
      displayBotPrice(nextBotIndex, i*yoff);
      bFirst = false;
    }
    else
    {
      b.displayOffline(i*yoff);
    }
  }
  
  // display the current conditions for the spaceship
  fill(255);
  floor.spaceship.hull.displayRemaining(5, 20);
  floor.spaceship.life.displayRemaining(200, 20);
  floor.spaceship.thrust.displayRemaining(5, 170);
  floor.spaceship.shield.displayRemaining(200, 170);
  floor.spaceship.displayResources();
  
  // draw the timeleft for next growth rate increase
  stroke(0, 255, 0);
  fill(0, 255, 0, 50);
  float bhy = height - Global.HUD_HEIGHT + 140;
  rect(width/2 + 15, bhy, 20, 115);
  noStroke();

  float time_percent = 0.0;
  if (state == Global.GAME_STATE_ingame || state == Global.GAME_STATE_gameover) time_percent = (float)(floor.spaceship.res_growth.elapsed()) / (float)(floor.spaceship.res_growth.timeLength);
  else if (state == Global.GAME_STATE_title) time_percent = 0.6;
   
  float bar_length = time_percent*115;
  float diff = 115 - bar_length;
  
  fill(0, 255, 0);
  rect(width/2 + 15, bhy + diff, 20, bar_length);
}

void drawSpaceshipState()
{
  float x = width/2 - Global.SPACESHIP_W/2;
  float y = height/2 - Global.HUD_HEIGHT/2 - Global.SPACESHIP_H/2;
  
  float rads = radians(ship_rotation); 
  
  // offset the spaceship so that when it is being rotated it will "roughly" remain at it's current location but only tilting upwards
  float offset_x = Global.SPACESHIP_W*sin(rads);
  float offset_y = Global.SPACESHIP_H - Global.SPACESHIP_H*cos(rads);
  x += offset_x;
  y -= (offset_y*6);
  
  pushMatrix();
  translate(x,y);
  rotate(rads);
  image(parts_hull.get(floor.spaceship.hull.level_cur), launch_location.x, launch_location.y);
  image(parts_life.get(floor.spaceship.life.level_cur), launch_location.x, launch_location.y);
  image(parts_thrust.get(floor.spaceship.thrust.level_cur), launch_location.x, launch_location.y);
  image(parts_shield.get(floor.spaceship.shield.level_cur), launch_location.x, launch_location.y);
  popMatrix();
}

void displayBotPrice(int n, float yoff)
{
  Resources cost = bot_costs.get(n);
  float xloc = width - 350;
  float yloc = height - Global.HUD_HEIGHT + 20 + yoff;
  float xspace = 50; // space for the bar or text
  
  text("Press "+(n+2)+" to ACTIVATE Drone " + (n+2) + " [Cost Below]", xloc, yloc);
  yloc += 32;
  float icon_init_x = xloc;
  image(iron, icon_init_x, yloc - 20);
  image(crystal, icon_init_x + 32 + xspace, yloc - 20);
  text(" "+ ((int)cost.iron) +" ", icon_init_x + 32, yloc + 4);
  text(" "+ ((int)cost.crystal) +" ", icon_init_x + 2*32 + xspace, yloc + 4);
  
  image(gas, icon_init_x + 2*32 + 2*xspace, yloc - 20);
  image(lead, icon_init_x + 3*32 + 3*xspace, yloc - 20);
  text(" "+ ((int)cost.gas) +" ", icon_init_x + 3*32 + 2*xspace, yloc + 4);
  text(" "+ ((int)cost.lead) +" ", icon_init_x + 4*32 + 3*xspace, yloc + 4);
}

