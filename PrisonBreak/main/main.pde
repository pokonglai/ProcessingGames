import fisica.*;
import pathfinder.*;

// ui variables
InstructionScreen instructions;
GameOverScreen gameover;

// our shining hero
Entity player;

// game world variables
FWorld world;
Floor floor; 

Particle flare;
Torch torch;

boolean flare_loaded;
int reload_timeout;

AIDirector director;

// helper variables
Controls controls;
short state;

PGraphics buffer;
PGraphics darkness_mask;
PGraphics player_death; // a nice blood splatter for a dead player

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
  frame.setTitle("Prison Break");
  
  // frame buffer
  buffer = createGraphics(width, height);
  buffer.imageMode(CENTER);
  buffer.beginDraw();
  buffer.smooth();
  buffer.noStroke();
  buffer.endDraw();

  // draw lighting objects on this
  darkness_mask = createGraphics(width, height);
  darkness_mask.imageMode(CENTER);
  darkness_mask.ellipseMode(CENTER);
  
  // a nice blood splatter for a dead convict
  player_death = createGraphics(300, 300, JAVA2D);
  player_death.beginDraw();
  player_death.smooth();
  player_death.noStroke();
  player_death.endDraw();
  
  controls = new Controls();
  frameRate(60);
}

void initGUI()
{
  instructions = new InstructionScreen();
  gameover = new GameOverScreen();
}

// create our world, fill it obstacles and monsters
void initWorld()
{
  // init Box2D world
  Fisica.init(this);
  world = new FWorld();
  world.setEdges();
  world.setGravity(0, 0);
  
  floor = new Floor(true);
  for (WallBlock wb : floor.obstacles) world.add(wb);
  
  player = new Entity(20, height - 20, Global.PLAYER_SIZE); // always start the player off at the bottom left corner
//  player.stats.VIT = 3000; // testing purposes, makes the player immune to damage
  world.add(player);
  
  // create the waypoint graph and spawn some monsters
  director = new AIDirector(Global.DEFAULT_GRAPH_DENSITY);
  director.buildGraph(floor);
  director.spawnMonsters(floor, player);
  for (Monster m : floor.monsters) world.add(m);
  
  // limit of only ONE flare on screen at a time
  // TODO: optimize so that any number of flares can be launched
  flare = null; 
  torch = null;
  flare_loaded = true;
  
  // by making the reload timer equal time travelled + fade time we can avoid 
  // having too many conditionals to ensure that only one flare is present at any given time.
  reload_timeout = Global.DEFAULT_PARTICLE_TIMEOUT + Global.DEFAULT_TORCH_TIMEOUT;
}

float offsetX() { return width/2 - player.x(); } 
float offsetY() { return height/2 - player.y(); }

// since the player is always going to be at the center of the screen, the direction
// a particle will travel is just the vector from the center to the mouse position
PVector playerFacingDir()
{
  PVector dir = new PVector(mouseX - width/2, mouseY - height/2);
  dir.normalize(); 
  return dir;
}

/**
 Collision detection handlers
------------------------------
- contactStarted will handle all the damage, deaths, pushing, etc...
- contactPresisted will handle piercing damage (ie lasers)
- contactEnded will produce animation for all the contacts
- during a draw() all dead elements will be pruned

TODO: should really use setCategoryBits so that we do not have to use expensive instanceof commands.
Casting is still required to get the object we want though since Fisica does not allow UserData.
**/
void contactStarted(FContact contact)
{
}

void contactPersisted(FContact contact)
{
}

void contactEnded(FContact contact)
{
  FBody b1 = contact.getBody1();
  FBody b2 = contact.getBody2();
  
  // flare hitting anything will cause it to explode
  if (b1 instanceof Particle && (b2 instanceof FBox || b2 instanceof Monster))
  {
    Particle p = (Particle) b1;
    if (p.bounce == false) p.timeleft = 0;
  }
  if (b2 instanceof Particle && (b1 instanceof FBox || b1 instanceof Monster))
  {
    Particle p = (Particle) b2;
    if (p.bounce == false) p.timeleft = 0;
  }
}

void mousePressed()
{  
  if (mouseButton == LEFT) controls.bMouseHeld_Left = true;
  if (mouseButton == RIGHT) controls.bMouseHeld_Right = true;
}

void mouseReleased()
{
  if (mouseButton == LEFT)
  {
    if (state == Global.GAME_STATE_ingame)
      player_shoot();
  }
}

// fire a flare if it is not on a cool down
void player_shoot()
{
  if (flare_loaded)
  {
    PVector dir = playerFacingDir();
    flare = player.shoot(dir, floor);
    if (flare != null)
    {
      world.add(flare);
      flare_loaded = false;
      reload_timeout = Global.DEFAULT_PARTICLE_TIMEOUT + Global.DEFAULT_TORCH_TIMEOUT; 
    }
  }
}

void keyPressed()
{
  controls.press_repeatkeys();
}

void keyReleased()
{
  controls.update_repeatkeys();
  boolean spacebar = key == ' '; 
  if (state == Global.GAME_STATE_title)
  {
    if (spacebar)
    {
      gameover.time_start = millis();
      state = Global.GAME_STATE_ingame;
    }
  }
  
  if (state == Global.GAME_STATE_gameover)
  {
    if (spacebar)
    {
      initWorld(); // regenerate the world
      gameover.time_start = millis();
      state = Global.GAME_STATE_ingame;
    }
  }
}

void updatePlayerMovement()
{
  int dx = 0;
  int dy = 0;
  
  if (controls.checkKey('W') || controls.checkKey('w')) dy = -1;
  if (controls.checkKey('A') || controls.checkKey('a')) dx = -1;
  if (controls.checkKey('S') || controls.checkKey('s')) dy =  1;
  if (controls.checkKey('D') || controls.checkKey('d')) dx =  1;
  player.move(dx, dy, controls.checkKey(SHIFT));
}

// move monsters, attack if player is within melee range
// no need to prune monsters since they cannot die in this game
void updateMonsters()
{
  // find new routes, update states
  for (Monster m : floor.monsters) m.search(player, director, floor);
  
  // attack the player if a monster is close enough
  ArrayList<Damage> damages = new ArrayList<Damage>();
  for (Monster m : floor.monsters)
  {
    float dx = player.x() - m.x();
    float dy = player.y() - m.y();
    float dist = sqrt(dx*dx + dy*dy);
    if (dist <= m.range_melee())
    {
      Damage dmg = m.melee(player);
      damages.add(dmg);
    }
  }

  // still alive? apply the damage forces
  if (player.alive())
  {
    // for all monsters attacked, push them back by some amount of force
    for (int i = 0; i < damages.size(); i++)
    {
      Damage d = damages.get(i);
      player.push(d.force.x, d.force.y);
    }
  }
}

// prune dead collisions, update particle timers
void updateCollisions()
{
  // update the reload timers
  if (flare_loaded == false)
  {
    reload_timeout--;
    if (reload_timeout == 0)
    {
      flare_loaded = true;
      reload_timeout = Global.DEFAULT_PARTICLE_TIMEOUT + Global.DEFAULT_TORCH_TIMEOUT; 
    }
  }
  
  // we have a flare? update it's status and prune if it is dead
  if (flare != null)
  {
    flare.update();
    if (flare.alive == false)
    {
      torch = new Torch(flare.x(), flare.y());
      world.removeBody(flare);
      flare = null;
    }
  }
  
  // we have a torch? update it's status and prune if it is dead
  if (torch != null)
  {
    torch.update();
    if (torch.alive == false) torch = null;
  }
}

// check if the player is still alive and if they have completed the winning conditions
void updateGameState()
{
  floor.updateGameState(player);
  if (player.alive() == false)
  {
    player.setDrawable(false); // just hide the player
    drawBloodSplat(player_death, player.getSize());
    
    gameover.winner = false;
    gameover.time_end = millis();
    state = Global.GAME_STATE_gameover;
  }
  else if (floor.exit.gameover)
  {
    gameover.winner = true;
    gameover.time_end = millis();
    state = Global.GAME_STATE_gameover;
  }
}

void draw()
{
  noStroke();

  if (state == Global.GAME_STATE_title)
  {
    renderFrame(true);
    drawHUD();
    instructions.display();
  }
  
  if (state == Global.GAME_STATE_ingame)
  {
    updatePlayerMovement();
    updateMonsters();
    updateCollisions();
    updateGameState();
    
    renderFrame(true);
    drawHUD();  
  }
  
  if (state == Global.GAME_STATE_gameover)
  {
    renderFrame(false);
    gameover.display();
  }
  
  fill(255);
  text(frameRate, width-70, 20);
}

void mask(PImage target, PImage mask)
{
  mask.loadPixels();
  target.loadPixels();
  if (mask.pixels.length != target.pixels.length)
  {
    println("Images are not the same size");
  }
  else
  {
    for (int i=0; i<target.pixels.length; i++) target.pixels[i] = ((mask.pixels[i] & 0xff) << 24) | (target.pixels[i] & 0xffffff);
    target.updatePixels();
  }
}

void renderFrame(boolean bApplyMask)
{
  float offX = offsetX();
  float offY = offsetY();
  PVector dir = playerFacingDir();
  
  // push the current coordinate system, translate wrt to the player 
  // to ensure that the player is always drawn at the center
  pushMatrix(); 
  translate(offX, offY);
  
  // draw all Box2D objects into the frame buffer
  buffer.beginDraw();
  buffer.background(255, 255, 255);
  floor.exit.display(buffer);
  floor.lightswitch.display(buffer);
  
  // render the last few steps the monsters have taken with the earliest step most faded away
  for (Monster m : floor.monsters)
  {
    for (int i = 0; i < m.laststeps.size(); i++)
    {
      PVector v  = m.laststeps.get(i);
      float ratio = (float)(i+1)/ 4;
      buffer.fill(255, 0, 0, ratio*255);
      buffer.ellipse(v.x, v.y, 3, 3);
    }
  }
  world.draw(buffer);
  
  // add a visualization for the emergency lights and make it lighter when the power is on 
  if (floor.lightswitch.selected) buffer.fill(215, 130, 255);
  else buffer.fill(100, 15, 255);
  for (int i = 0; i < floor.spotlights.size() - 2; i++)
  {
    PVector spot = floor.spotlights.get(i);
    buffer.ellipse(spot.x, spot.y, 6, 6);
  }
  if (player.alive() == false) buffer.image(player_death, player.x(), player.y());
  buffer.endDraw();
  
  world.step();
  
  if (bApplyMask) 
  {
    // draw the darkness mask
    darkness_mask.beginDraw();
    darkness_mask.background(0);
    darkness_mask.ellipse(player.x(), player.y(), Global.DEFAULT_FLARE_SIZE, Global.DEFAULT_FLARE_SIZE);
    darkness_mask.noStroke();
    if (flare != null)
    {
      darkness_mask.fill(255);
      darkness_mask.ellipse(flare.x(), flare.y(), Global.DEFAULT_FLARE_SIZE, Global.DEFAULT_FLARE_SIZE);
    }
    if (torch != null) torch.display(darkness_mask);
    darkness_mask.fill(255);
    if (floor.lightswitch.selected)
    {
      // render all the spotlights, ignore the last two since it will be the exit and the light switch which will be rendered seperately
      for (int i = 0; i < floor.spotlights.size()-2; i++)
      {
        PVector vec = floor.spotlights.get(i);
        darkness_mask.ellipse(vec.x, vec.y, Global.DEFAULT_FLARE_SIZE*2, Global.DEFAULT_FLARE_SIZE*2); // render a spotlights on a random corner
      }
      darkness_mask.ellipse(floor.exit.x() + floor.exit.width()/2, floor.exit.y() - floor.exit.height()/2, Global.DEFAULT_TORCH_SIZE, Global.DEFAULT_TORCH_SIZE); // render the light swtich
      darkness_mask.ellipse(floor.lightswitch.x() + floor.lightswitch.width()/2, floor.lightswitch.y() - floor.lightswitch.height()/2, Global.DEFAULT_TORCH_SIZE, Global.DEFAULT_TORCH_SIZE); // render the light swtich
    }
    darkness_mask.endDraw();
    
    // apply all the light mask to the frame buffer
    mask(buffer, darkness_mask);
  }
  background(0); // clear the background 
  image(buffer, 0, 0); // render the frame
  
  popMatrix();
}

void drawHUD()
{
  // draw the hp bar
  float hp_length = (player.stats.HP/player.stats.HP_MAX)*Global.HP_BAR_W;
  fill(255, 0, 0);
  rect(84, height-57, hp_length, Global.BAR_H, 4, 4, 4, 4);
  
  // draw the stamina bar
  float stamina_length = (player.stats.STAMINA/player.stats.STAMINA_MAX)*Global.HP_BAR_W;
  fill(255, 215, 0);
  rect(84, height-37, stamina_length, Global.BAR_H, 4, 4, 4, 4);
  
  // draw the timeout counter
  if (reload_timeout < Global.DEFAULT_RELOAD_TIME)
  {
    float reload_ratio = (float)reload_timeout / (float)Global.DEFAULT_RELOAD_TIME;
    float reload_rad = radians(360 - reload_ratio*360);
    fill(200, 0, 255);
    arc(40, height-40, 64, 64, radians(-90), reload_rad + radians(-90));
  }
  else
  {
    fill(200, 0, 255);
    ellipse(40, height-40, 64, 64);
  }
}

// draw a "splatter" on the input PGraphics to represent a dead body
void drawBloodSplat(PGraphics g, float rad)
{
  g.beginDraw();
  g.fill(255, 100, 100, 100);
  for (float i=0.4; i<rad*2; i+=.2)
  {
    float angle = random(0, TWO_PI);
    float splatX = g.width/2 + cos(angle)*2*i;
    float splatY = g.height/2 + sin(angle)*3*i;
    g.ellipse(splatX, splatY, rad-i, rad-i+1.2);
  }
  g.endDraw();
}

