public class Screen
{
  String name;
  public Screen() { name = "screen"; }
  public Screen(String s) { name = s; }
  void display() { }
}


// TODO: base add instructions off controls, ie: can add an instruction string per control key => key : string explaining the function
public class InstructionScreen extends Screen
{
  PFont font_title;
  PFont font_start;
  PFont font_text;
  
  private ArrayList<String> story;
  private ArrayList<String> controls;
  private ArrayList<String> instructions;
  
  int slide_cur;
  int slide_max;
  
  PGraphics hidden; // black out entire screen
  PImage cutout; // actual sem-transparent image that is rendered
  
  public InstructionScreen()
  {
    super("instructions");
    font_start = createFont("Arial", 36, true);
    font_title = createFont("Arial", 48, true);
    font_text = createFont("Arial", 18, true);
    
    story = new ArrayList<String>();
    story.add("You are a scientist in the far far future.");
    story.add(""); 
    story.add("Extreme warfare has caused the core of your planet to become unstable.");
    story.add("");
    story.add("A massive earthquake has unleashes massive shockwaves which ripple through the surface.");
    story.add("");
    story.add("The shockwaves have heavily damaged your main spaceship and your prized invention: a resouce cloning device.");
    story.add("");
    story.add("The device now operates only at 5% efficiency.");
    story.add("");
    story.add("Your readings tell you that the planet will implode in just over 10 minutes.");
    story.add("");
    story.add("Guide your drones to gather the necessary resources and repair your ship before time runs out!");
    story.add("");

    controls = new ArrayList<String>();
    controls.add(">> [ PRESS 1 to 4 ] to select Drone 1 to 4 individually if they are available.");
    controls.add(">> [ LEFT-CLICK and DRAG ] creates a green selection rectangle which selects multiple drones.");
    controls.add(">> [ LEFT-CLICK ] deselects all selected drones.");
    controls.add(">> [ RIGHT-CLICK ] on the map to set a flag. Selected drones will move towards the flag automatically.");
    
    instructions = new ArrayList<String>();
    instructions.add("[ 1 ] Gather resources by moving a drone near resource deposits");
    instructions.add("[ 2 ] Drop off resources by moving a drone to the drop off zones");
    instructions.add("[ 3 ] Additonal drones can be activated provided you have enough resources stored away");
    instructions.add("[ 4 ] Repair a specific part of the ship by moving a drone to it's respective repair zone");
    instructions.add("[ 5 ] A drone gathers resources at a rate proportional to the number of drones at that deposit");
    instructions.add("[ 6 ] It is more resource efficient to have multiple drones repairing a ship part");
    instructions.add("[ 7 ] Every 20 seconds your factory will clone 5% of the stored resources");
    instructions.add("");
    instructions.add("GOOD LUCK!");

    slide_cur = 0;
    slide_max = 4;

    hidden = createGraphics(width, height);
    hidden.imageMode(CENTER);
    hidden.beginDraw();
    hidden.smooth();
    hidden.noStroke();
    hidden.endDraw();
    
    hidden.beginDraw();
    hidden.fill(0, 0, 0, 220);
    hidden.rect(0, 0, width, height);
    hidden.endDraw();
    cutout = null;
  }
  
  // assume the pixels are already loaded, zero the alpha value of the indicated range
  void highlight(PImage img, int x, int y, int w, int h)
  {
    for (int i = x; i < x+w; i++)
    {
      for (int j = y; j < y+h; j++)
      {
        color c = color(0,0,0,0);
        cutout.pixels[i + j*cutout.width] = c;
      }
    }
  }
  
  boolean advanceSlide(Floor f)
  {
    switch(slide_cur)
    {
      // from story to explain UI elements
      // explain the ship and it's surroundings
      case 0:
        cutout = hidden.get();
        cutout.loadPixels();
        
        // highlight the spaceship
        int sx = (int)f.spaceship.zone_range.topleft.x;
        int sy = (int)f.spaceship.zone_range.topleft.y;
        int sw = (int)f.spaceship.zone_range.width();
        int sh = (int)f.spaceship.zone_range.height()*-1; // my god has the height always been negative?? such a hack
        highlight(cutout, sx, sy, sw, sh);
        cutout.updatePixels();
        break;
        
      // from basic UI elements to resource deposits
      case 1:
        cutout = hidden.get();
        cutout.loadPixels();
        
        // highlight the spaceship
        for (ResourceDeposit res: f.deposits)
        {
          Rectangle r = res.collection_range;  
          int dx = (int)r.topleft.x;
          int dy = (int)r.topleft.y;
          int dw = (int)r.width();
          int dh = (int)r.height()*-1; // my god has the height always been negative?? such a hack
          highlight(cutout, dx, dy, dw, dh);          
        }
        cutout.updatePixels();
        break;
        
      // from resource deposits to HUD UI
      case 2: 
        cutout = hidden.get();
        cutout.loadPixels();
        highlight(cutout, 0, (int)(height-Global.HUD_HEIGHT), width, (int)Global.HUD_HEIGHT);  
        cutout.updatePixels();
        break;
        
      // from HUD UI to controls and instructions
      case 3: 
        cutout = hidden.get();
        break;
        
      default: break;
    }
    
    slide_cur++;
    return slide_cur > slide_max;
  }
  
  void display_press_space()
  {    
    fill(255);
    textFont(font_start);
    if (slide_cur < slide_max) text("Press SPACE to continue.", 570, height-20);
    else  text("Press SPACE to begin.", 620, height-20);
  }
  
  void display(Floor f)
  {    
    switch(slide_cur)
    {
      case 0: display_story(); break;
      case 1: explain_basicUI(f); break;
      case 2: explain_resources(f); break;
      case 3: explain_hud(f); break;
      case 4: explain_controls(f); break;
      default: break;
    }
  }
  
  void display_story()
  {
    fill(0, 0, 0, 220);
    rect(0, 0, width, height);

    display_press_space();
    
    float xpad = 25;
    float ypad = 50;
    textFont(font_title);
    text("Escape Velocity", xpad, ypad);
    
    float newline = 50;
    textFont(font_text);
    
    // explain the story
    float linesize = 22;
    float instruct_yoffset = ypad*2;
    for (int i = 0; i < story.size(); i++) text(story.get(i), xpad, instruct_yoffset + i*linesize);
  }
  
  void explain_basicUI(Floor f)
  {
    image(cutout, 0, 0);
    
    stroke(255, 0, 0);
    strokeWeight(2);
    
    // spaceship
    float sx1 = f.spaceship.actual.center_x()+25;
    float sy1 = f.spaceship.actual.center_y();
    float sx2 = f.spaceship.actual.center_x() + 200;
    float sy2 = f.spaceship.actual.center_y();
    line(sx1, sy1, sx2, sy2);
    ellipse(sx1,sy1,4,4);
    
    // repair zones    
    float rhx1 = f.spaceship.repair_hull.center_x();
    float rhy1 = f.spaceship.repair_hull.center_y();
    float rhx2 = f.spaceship.repair_hull.center_x()-35;
    float rhy2 = f.spaceship.repair_hull.center_y()+35;
    line(rhx1, rhy1, rhx2, rhy2);
    ellipse(rhx1,rhy1,4,4);
    
    float rlx1 = f.spaceship.repair_life.center_x();
    float rly1 = f.spaceship.repair_life.center_y();
    float rlx2 = f.spaceship.repair_life.center_x()-35;
    float rly2 = f.spaceship.repair_life.center_y()-35;
    line(rlx1, rly1, rlx2, rly2);
    ellipse(rlx1,rly1,4,4);
    
    float rtx1 = f.spaceship.repair_thrust.center_x();
    float rty1 = f.spaceship.repair_thrust.center_y();
    float rtx2 = f.spaceship.repair_thrust.center_x()+35;
    float rty2 = f.spaceship.repair_thrust.center_y()-35;
    line(rtx1, rty1, rtx2, rty2);
    ellipse(rtx1,rty1,4,4);
    
    float rsx1 = f.spaceship.repair_shield.center_x();
    float rsy1 = f.spaceship.repair_shield.center_y();
    float rsx2 = f.spaceship.repair_shield.center_x()+35;
    float rsy2 = f.spaceship.repair_shield.center_y()+35;
    line(rsx1, rsy1, rsx2, rsy2);
    ellipse(rsx1,rsy1,4,4);
    
    // dropoff zones
    float dfx1 = f.spaceship.actual.center_x();
    float dfy1 = f.spaceship.actual.center_y()+Global.SPACESHIP_H;
    float dfx2 = f.spaceship.actual.center_x();
    float dfy2 = dfy1+100;
    line(dfx1, dfy1, dfx2, dfy2);
    ellipse(dfx1,dfy1,4,4);

    // put a box around the drone
    stroke(0,0,255);
    Bot drone1 = f.drones.get(0);
    float dx1 = drone1.x() - Global.PLAYER_SIZE;
    float dy1 = drone1.y() - Global.PLAYER_SIZE;
    float dx2 = dx1 - 50;
    float dy2 = dy1 + 32;
    line(dx1, (int)(dy1 + Global.PLAYER_SIZE*2), dx2, dy2);
    fill(0,0,0,0);
    rect(dx1-1, dy1-1, Global.PLAYER_SIZE*2+1, Global.PLAYER_SIZE*2+1);
    
    noStroke();
    
    display_press_space();
    
    fill(255);
    textFont(font_text);
    text("This is your broken spaceship", sx2 + 10, sy2 + 8);
    text("Hull repair zone", rhx2-100, rhy2+18);
    text("Life Support repair zone", rlx2-150, rly2-4);
    text("Thrust repair zone", rtx2 - 25, rty2-4);
    text("Rad. Shield repair zone", rsx2 - 25, rsy2+18);
    text("Resource drop off zones surround each side of the ship", dfx2 - 200, dfy2 + 20);
    text("Drone 1", dx2-70, dy2+7);
  }
  
  void explain_resources(Floor f)
  {
    image(cutout, 0, 0);
    float hudy = height-Global.HUD_HEIGHT;
    
    fill(0);
    rect(0, hudy, width, Global.HUD_HEIGHT);
    
    display_press_space();

    fill(255);
    textFont(font_text);
    text("Below are the available resources. The highlighted area indiciates the range a drone must be in to gather them.", 25, hudy + 25);
    image(iron, 32, hudy + 32);
    text("Iron", 68, hudy + 32 + 24); 
    
    image(crystal, 32, hudy + 2*32);
    text("Crystal", 68, hudy + 2*32 + 24);
    
    image(gas, 32, hudy + 3*32);
    text("Gas", 68, hudy + 3*32 + 24);
    
    image(lead, 32, hudy + 4*32);
    text("Lead", 68, hudy + 4*32 + 24);
  }
  
  void explain_hud(Floor f)
  {
    image(cutout, 0, 0);
    
    float hudy = height-Global.HUD_HEIGHT;
    
    
    stroke(255, 0, 0);
    strokeWeight(2);
    
    fill(0,0,0,0);
    
    // ship parts
    line(20, hudy, 20, hudy - 280);
    rect(0, hudy, 408, Global.HUD_HEIGHT);
    
    // stored resources  
    line(420, hudy + 95, 420, hudy-230);
    rect(420, hudy + 95, 205, 168);
    
    // drone status
    line(width-20, hudy, width-20, hudy-330);
    rect(638, hudy, 360, 263);
    
    // countdown timer
    line(width/2 + 25, hudy + 25, width/2 + 25, hudy-135);
    ellipse(width/2 + 25, hudy + 25, 4, 4);
    
    // resource repelish bar
    line(width/2 + 25, hudy + 220, width/2 + 160, hudy-80);
    ellipse(width/2 + 25, hudy + 220, 4, 4);
    
    noStroke();
    
    // behind the spacebar to continue message
    fill(0,0,0,220);
    rect(560, height - 60, width - 560, 110);
    
    display_press_space();

    fill(255);
    textFont(font_text);
    
    text("Countdown timer", width/2 - 40, hudy - 150);
    text("Where gathered resources go when you move a drone to the drop off zones", width/2 - 300, hudy - 250);
    text("The status of each ship part showing required resources for next level of repair", 10, hudy - 300);
    text("The status of each drone that is active showing its gathered resources", 425, hudy - 350);
    text("When the bar is filled", width/2 + 140, hudy-150);
    text("each resource is increased", width/2 + 140, hudy-125);
    text("by 5% through cloning", width/2 + 140,  hudy-100);
  }
  
  void explain_controls(Floor f)
  {
    image(cutout, 0, 0);
    
    fill(255);

    textFont(font_title);
    text("Controls", 25, 50);
    text("Instructions & Tips", 25, 250);
    
    display_press_space();
    
    float xpad = 50;
    float ypad = 75;
    float linesize = 22;
    textFont(font_text);
    for (int i = 0; i < controls.size(); i++) text(controls.get(i), xpad, ypad+(i+1)*linesize);
    
    ypad = 275;
    for (int i = 0; i < instructions.size(); i++) text(instructions.get(i), xpad, ypad+(i+1)*linesize);
  }
}

public class GameOverScreen extends Screen
{
  PFont font_title;
  PFont font_text;
  PFont font_countdown;

  Timer countdown;
  float count_x;
  float count_y;
  
  boolean resultsComputed;
  ArrayList<String> results_parts; // results for each part
  ArrayList<String> results_story; // results wrt to the story (ie: damaged hull caused X)
  
  public GameOverScreen()
  {
    super("game_over");
    
    font_countdown = createFont("Arial", 72, true);
    font_title = createFont("Arial", 36, true);
    font_text = createFont("Arial", 18, true);
    
    count_x = width/2 - 65;
    count_y = height - Global.HUD_HEIGHT + 80;
    
    countdown = new Timer(Global.GAME_LENGTH);
    reset();
  }
  
  void reset() { resultsComputed = false; }
  
  void computeResults(Spaceship s)
  {
    // no results yet? compute them and then keep them
    if (resultsComputed == false)
    {
      results_parts = new ArrayList<String>();
      results_story = new ArrayList<String>();
      
      float hull_success = part_success_prob(s.hull.level_cur);
      float life_success = part_success_prob(s.life.level_cur);
      float shield_success = part_success_prob(s.shield.level_cur);
      float thrust_success = part_success_prob(s.thrust.level_cur);
      
      // projected total success rate
      float total_success_chance = hull_success * life_success * shield_success * thrust_success;
      
      results_parts.add("Hull ... " + s.hull.condition());
      results_parts.add("Life Support ... " + s.life.condition());
      results_parts.add("Thrusters ... " + s.thrust.condition());
      results_parts.add("Radiation Shields .. " + s.shield.condition());
      results_parts.add("");
      results_parts.add("Projected chance of success: " + (total_success_chance*100) + " %");
      
      results_story = new ArrayList<String>();
      boolean hull_pass = hull_success > random(0,1);
      boolean life_pass = life_success > random(0,1);
      boolean shield_pass = shield_success > random(0,1);
      boolean thrust_pass = thrust_success > random(0,1);
      
      ArrayList<Integer> outcomes = new ArrayList<Integer>(); 
      if (hull_pass == false) outcomes.add(0);
      if (life_pass == false) outcomes.add(1);
      if (shield_pass == false) outcomes.add(2);
      if (thrust_pass == false) outcomes.add(3);
      
      // [type][outcome], type = 0 = hull, etc..., outcome = 0 = broken, etc...
      boolean[][] mat = outcome_matrix(s);
      
      // have some failures, explain them!
      if (outcomes.size() > 0)
      {
        results_story.add("Unfortunately ... ");
        results_story.add("");
        
        int broken = 0;  // any broken parts that failed mean death
        int damaged = 0; // if there exists a damaged part, any other failure means death
        int fragile = 0; // if there exists a fragile part, then it takes two other failures to mean death
        int repaired = 0;  // if a repaired part failed, it requires all other parts to fail as well
        Collections.shuffle(outcomes);
        for (Integer i : outcomes)
        {
          if (i == 0)
          {
            if (s.hull.level_cur == 0) broken++;
            if (s.hull.level_cur == 1) damaged++;
            if (s.hull.level_cur == 2) fragile++;
            if (s.hull.level_cur == 3) repaired++;
          }
          
          if (i == 1)
          {
            if (s.life.level_cur == 0) broken++;
            if (s.life.level_cur == 1) damaged++;
            if (s.life.level_cur == 2) fragile++;
            if (s.life.level_cur == 3) repaired++;
          }
          
          if (i == 2)
          {
            if (s.shield.level_cur == 0) broken++;
            if (s.shield.level_cur == 1) damaged++;
            if (s.shield.level_cur == 2) fragile++;
            if (s.shield.level_cur == 3) repaired++;
          }
          
          if (i == 3)
          {
            if (s.thrust.level_cur == 0) broken++;
            if (s.thrust.level_cur == 1) damaged++;
            if (s.thrust.level_cur == 2) fragile++;
            if (s.thrust.level_cur == 3) repaired++;
          }
        }
        
        // instant death
        if (broken > 0)
        {
          // pick a part and blame it on that
          for (Integer i : outcomes)
          {
            if (mat[i][0])
            {
              results_story.add(genBrokenFailureMessage(i));
              break;
            }
          }
          results_story.add("");
          results_story.add("You never stood a chance... ");
        }
        
        
        else if ((damaged >= 1 && damaged + fragile + repaired >= 2) || // at least one damaged part and any other damaged part = death
        (fragile >= 1 && damaged + fragile + repaired >= 3) || // at least one fragile part + two other parts = death
        (damaged + fragile + repaired >= 4) ) // every part failed even though they were not broken
        {
          for (Integer i : outcomes)
          {
            if (mat[i][1]) results_story.add(genDamagedFailureMessage(i));
            if (mat[i][2]) results_story.add(genFragileFailureMessage(i));
            if (mat[i][3]) results_story.add(genRepairedFailureMessage(i));
          }
          results_story.add("");
          results_story.add("You never stood a chance... ");
        }

        // has some damaged parts but not enough to be insta death
        else
        {
          for (Integer i : outcomes)
          {
            if (mat[i][1]) results_story.add(genDamagedFailureMessage(i));
            if (mat[i][2]) results_story.add(genFragileFailureMessage(i));
            if (mat[i][3]) results_story.add(genRepairedFailureMessage(i));
          }
          results_story.add("");
          results_story.add("However, despite the failures you survived and made it to a new planet!");
          results_story.add("");
          results_story.add("              Congratulations!");
        }
      }
      
      // congratz, passed all checks
      else
      {
        results_story.add("");
        results_story.add("Against all odds, the ship was able to escape the dying planet.");
        results_story.add("");
        results_story.add("              Congratulations! You survived and made it to a new planet!");
      }
      
      resultsComputed = true;
    }
  }
  
  String genBrokenFailureMessage(int p)
  {
    if (p == 0) return "The implosion debris smashed through the broken Hull with ease and crushed you.";
    if (p == 1) return "Without Life Support, you could not breath and suffocated before reaching the new planet.";
    if (p == 2) return "Due to the lack of Radiation Shields, you were left exposed to intense gamma rays which incinerated you instantly.";
    if (p == 3) return "Broken Thrusters could not take you to space and the ship fell back to the dying planet.";
    return "  BLARG  "; // should be impossible since the levels of each parts never go over 3
  }
  
  String genDamagedFailureMessage(int p)
  {
    if (p == 0) return "The damaged Hull could barely withstand the implosion debris.";
    if (p == 1) return "The damaged Life Support did not filter the air properly.";
    if (p == 2) return "The damaged Radiation Shields did not abosrb all the intense the gamma rays.";
    if (p == 3) return "The damaged Thrusters broke down once the ship left the star system.";
    return "  BLARG  ";
  }
  
  String genFragileFailureMessage(int p)
  {
    if (p == 0) return "The fragile Hull could not withstand prologed bombardment and eventually cracked.";
    if (p == 1) return "The fragile Life Support provided subpar medical care.";
    if (p == 2) return "Midway through the trip the fragile Shields were used up and couldn't absorb any more radiation.";
    if (p == 3) return "The fragile Thrusters gave out about midway through the trip.";
    return "  BLARG  ";
  }
 
  String genRepairedFailureMessage(int p)
  {
    if (p == 0) return "Freak accidients happen. A comet smashed into the hull undoing all repairs.";
    if (p == 1) return "Even though the Life Support systems were repaired, the software seg faulted.";
    if (p == 2) return "Even the strongest Radiation Shields fail. No one could have predicted that the ship would be hit by intense solar winds.";
    if (p == 3) return "The fully repaired Thrusters provided too much thrust and the ship flew off course.";
    return "  BLARG  ";
  }

  float part_success_prob(int lvl)
  {
    switch(lvl)
    {
      case 0: return 0.25;
      case 1: return 0.80;
      case 2: return 0.90;
      case 3: return 0.99;
      default: return 1;
    }
  }
  
  boolean[][] outcome_matrix(Spaceship s)
  {
     boolean[][] ret = new boolean[4][4];
     
     ret[0][0] = s.hull.level_cur == 0;
     ret[0][1] = s.hull.level_cur == 1;
     ret[0][2] = s.hull.level_cur == 2;
     ret[0][3] = s.hull.level_cur == 3;
     
     ret[1][0] = s.life.level_cur == 0;
     ret[1][1] = s.life.level_cur == 1;
     ret[1][2] = s.life.level_cur == 2;
     ret[1][3] = s.life.level_cur == 3;
     
     ret[2][0] = s.shield.level_cur == 0;
     ret[2][1] = s.shield.level_cur == 1;
     ret[2][2] = s.shield.level_cur == 2;
     ret[2][3] = s.shield.level_cur == 3;
     
     ret[3][0] = s.thrust.level_cur == 0;
     ret[3][1] = s.thrust.level_cur == 1;
     ret[3][2] = s.thrust.level_cur == 2;
     ret[3][3] = s.thrust.level_cur == 3;
     
     return ret;
  }
  
  void drawCountDownRect()
  {
    fill(255, 0, 0, 50);
    rect(count_x - 10, count_y - 65, 200, 75);
  }
  
  void displayTime_Full() { drawCountDownRect(); fill(255, 0, 0); textFont(font_countdown); text("10:00", count_x, count_y); textFont(font_text); }
  void displayTime_Out() { drawCountDownRect(); fill(255, 0, 0); textFont(font_countdown); text("00:00", count_x, count_y);  textFont(font_text); }
  void displayCountdown()
  {
    int elapsed = countdown.elapsed();
    float seconds_elapsed = (float)elapsed / (float)1000;
    int minutes_left = (int)((countdown.timeLength - elapsed) / (float)(60*1000));
    int second_left = (int)(60-seconds_elapsed%60); // wrt a minute
    
    drawCountDownRect();
    fill(255, 0, 0);
    textFont(font_countdown); 
    if (second_left < 10) text("0" + minutes_left + ":0" + second_left, count_x, count_y);
    else text("0" + minutes_left + ":" + second_left, count_x, count_y);
    textFont(font_text);   
  }
  
  void display()
  {
    fill(0, 0, 0, 220);
    rect(0, 0, width, height);
    
    fill(255, 255, 255);

    textFont(font_text);
    
    // display the ending
    float yoff = 25; // y-offset for the each line
    float poff = 100; // offset for the parts
    float soff = 200; // offset for the story
    for (int i = 0; i < results_parts.size(); i++)
    {
      String s = results_parts.get(i);
      text(s, 25, poff + i*yoff);
    }
    
    for (int i = 0; i < results_story.size(); i++)
    {
      String s = results_story.get(i);
      text(s, 25, soff + poff + i*yoff);
    }
    
    textFont(font_title);
    text("Press SPACE to play again.", 550, height-20);
    
    // this is really just to reset the fps counter string after a game over
    // TODO: give the FPS text it's own font
    textFont(font_text); 
  }
}
