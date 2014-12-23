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
  
  private ArrayList<String> controls;
  private ArrayList<String> instructions;
  public InstructionScreen()
  {
    super("instructions");
    font_start = createFont("Arial", 48, true);
    font_title = createFont("Arial", 32, true);
    font_text = createFont("Arial", 20, true);
    
    controls = new ArrayList<String>();
    controls.add("[ Left Mouse ] -- Fire a FLARE. Automatic reload.");
    controls.add("[ W ] -- Move UP.");
    controls.add("[ A ] -- Move LEFT.");
    controls.add("[ S ] -- Move DOWN.");
    controls.add("[ D ] -- Move RIGHT.");
    controls.add("[ SHIFT ] -- Sprint. Requires STAMINA.");
    
    instructions = new ArrayList<String>();
    instructions.add("You are an escaped convict.");
    instructions.add("Security has shutdown power to keep you locked in.");
    instructions.add("The guards are on patrol. They will attack if you are in range.");
    instructions.add("Use your trusty FLARE gun to nagivate the darkness.");
    instructions.add("Your FLARE gun can only shoot ONCE before reloading.");
    instructions.add("Turn on the emergency power by stepping on the switch.");
    instructions.add("ESCAPE through the unlocked exit door!");
  }
  
  void display()
  {
    fill(0, 0, 0, 175);
    rect(0, 0, width, height);
    
    fill(255);
    
    textFont(font_start);
    text("Press SPACEBAR to begin.", 600, height-70);
    
    float xpad = 50;
    float ypad = 50;
    textFont(font_title);
    text("How to Play", xpad, ypad);

    float control_xoffset = width/2 + xpad;
    text("Controls", control_xoffset, ypad);

    float newline = 50;
    textFont(font_text);
    for (int i = 0; i < controls.size(); i++) text(controls.get(i), control_xoffset + 25, ypad+(i+1)*newline);
    
    // explain how the game works
    float linesize = 22;
    float instruct_yoffset = ypad*2;
    for (int i = 0; i < instructions.size(); i++) text(instructions.get(i), xpad, instruct_yoffset + i*linesize);
  
    // provide instructional visualization for the game objects
    float ex_offset = instruct_yoffset + (instructions.size() + 1)*linesize;
    float ex_pad = 20;
    text("Emergency Power Switch:", xpad, ex_offset);

    fill(255);
    text("Off", xpad + 100, ex_offset + ex_pad + Global.EXIT_SIZE + linesize);
    rect(xpad + 100, ex_offset + ex_pad, Global.EXIT_SIZE, Global.EXIT_SIZE);
    fill(255, 0, 0, 64);
    rect(xpad + 100, ex_offset + ex_pad, Global.EXIT_SIZE, Global.EXIT_SIZE);
    
    fill(255);
    text("On", xpad + 252, ex_offset + ex_pad + Global.EXIT_SIZE + linesize);
    rect(xpad + 250, ex_offset + ex_pad, Global.EXIT_SIZE, Global.EXIT_SIZE);
    fill(0, 255, 0, 64);
    rect(xpad + 250, ex_offset + ex_pad, Global.EXIT_SIZE, Global.EXIT_SIZE);
    
    ex_offset = ex_offset + ex_pad + Global.EXIT_SIZE + ex_pad + 2*linesize;
    fill(255);
    text("Exit Door:", xpad, ex_offset);
    
    text("Locked", xpad + 82, ex_offset + ex_pad + Global.EXIT_SIZE + linesize);
    fill(255, 145, 0);
    rect(xpad + 100, ex_offset + linesize, Global.EXIT_SIZE, Global.EXIT_SIZE);
    
    fill(255);
    text("Unlocked", xpad + 225, ex_offset + ex_pad + Global.EXIT_SIZE + linesize);
    fill(0, 255, 255);
    rect(xpad + 250, ex_offset + linesize, Global.EXIT_SIZE, Global.EXIT_SIZE);
    
    // instructions for the HUD
    fill(255);
    strokeWeight(2);
    stroke(255);
    ellipse(40, height-40, 4, 4);
    line(40, height-40, 50, height-75);
    text("FLARE gun reload timer.", 25, height-80);
    
    ellipse(Global.HP_BAR_W + 50, height-50, 4, 4);
    line(Global.HP_BAR_W + 50, height-50, Global.HP_BAR_W + 95, height-50);
    text("HP bar.", 100 + Global.HP_BAR_W, height - 45);
    
    ellipse(Global.HP_BAR_W + 50, height-25, 4, 4);
    line(Global.HP_BAR_W + 50, height-25, Global.HP_BAR_W + 95, height-25);
    text("STAMINA bar. Automatically recharges.", 100 + Global.HP_BAR_W, height - 20);
  }
}

public class GameOverScreen extends Screen
{
  PFont font_title;
  PFont font_text;
  
  boolean winner;
  
  int time_start;
  int time_end;
  public GameOverScreen()
  {
    super("game_over");
    
    font_title = createFont("Arial", 32, true);
    font_text = createFont("Arial", 20, true);
    
    winner = false;
  }
  
  void display()
  {
    fill(0, 0, 0, 175);
    rect(0, 0, width, height);
    
    int time_elapsed = time_end - time_start;
    float seconds_elapsed = (float)time_elapsed / (float)1000;
    
    fill(255, 255, 255);
    textFont(font_title);
    if (winner)
    {
      text("Congratulations! You have escaped in " + seconds_elapsed + " seconds!", 200, 200);
      text("Press SPACEBAR to play again.", 390, height*5/6);
    }
    else
    {
      text("Game Over... You survived for " + seconds_elapsed + " seconds.", 310, 200);
      text("Press SPACEBAR to play again.", 390, height*5/6);
    }
    
    // this is really just to reset the fps counter string after a game over
    // TODO: give the FPS text it's own font
    textFont(font_text); 
  }
}
