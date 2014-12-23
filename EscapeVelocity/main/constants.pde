public static class Global
{
  // debug flags
  static boolean SHOW_FPS           = false;
  static boolean SHOW_GRAPH         = false;
  static boolean DEMO_MODE          = false;
  static boolean RANDOMIZE_REPAIRED = false;
  
  // basic processing globals
  static final int APP_WIDTH        = 1000;
  static final int APP_HEIGHT       = 700;
  static final int TARGET_FRAMERATE = 60;
  
  // game states
  static short GAME_STATE_title    = 0x0001;
  static short GAME_STATE_ingame   = 0x0002;
  static short GAME_STATE_gameover = 0x0004;
  
  // boundaries
  static float EDGE_PADDING           = 32; // define the amount of padding there exists between the closest room and the edges of the screen
  static float PLAYER_SIZE            = 8;
  static float WORLD_WALL_EDGE_OFFSET = 4; // actual thickness of the walls are 20 (found using world.left.getWidth())
  static float DEPOSIT_SIZE           = 32;
  static float REPAIR_SIZE            = 40;
  
  // timer constants
  static int GAME_LENGTH       = 60000*10; // 1 minute x 5 = 5 minutes
//  static int GAME_LENGTH       = 60000/60; // one second game
  static int RESOURCE_REPLISH  = 60000/3; // every 20 seconds gain 5% of stored resources
  
  // resource growth rate for the storage
  static float RESOURCE_GROWTH_RATE = 0.05; // need to balance this
  
  // ai director
  static float DEFAULT_GRAPH_DENSITY   = 72;
  static float DEFAULT_IN_TARGET_RANGE = PLAYER_SIZE/2;
  
  // ui constants
  static boolean NO_STROKE = true; // determines whether or not our objects in FWorld are drawn with a stroke
  
  static float HUD_HEIGHT = 300;
  static float SPACESHIP_W = 100;
  static float SPACESHIP_H = 50;
  
  static float LAUNCH_ANGLE = 45;
  static float LAUNCH_INC = 0.50;
}
