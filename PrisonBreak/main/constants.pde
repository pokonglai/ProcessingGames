public static class Global
{
  // basic processing globals
  static final int APP_WIDTH        = 1200;
  static final int APP_HEIGHT       = 600;
  static final int TARGET_FRAMERATE = 60;
  
  // game states
  static short GAME_STATE_title    = 0x0001;
  static short GAME_STATE_ingame   = 0x0002;
  static short GAME_STATE_gameover = 0x0004;
  
  // boundaries
  static float EDGE_PADDING           = 32; // define the amount of padding there exists between the closest room and the edges of the screen
  static float WALL_THICKNESS         = 8;
  static float DOORWAY_LENGTH         = 40;
  static float PLAYER_SIZE            = 8;
  static float WORLD_WALL_EDGE_OFFSET = 10; // actual thickness of the walls are 20 (found using world.left.getWidth())
  static float EXIT_SIZE              = 32;
  
  // floor/level related ranges
  static int MIN_BLOCK        = 3;
  static int MAX_BLOCK        = 9;
  static int MIN_BLOCK_WIDTH  = 9; // min/max number of blocks that will make up the size of the room
  static int MAX_BLOCK_WIDTH  = 24;
  static int MIN_BLOCK_HEIGHT = 9;
  static int MAX_BLOCK_HEIGHT = 24;
  static int MIN_MONSTER     = 10;
  static int MAX_MONSTER     = 20;
  
  // particles
  static float DEFAULT_PARTICLE_SIZE = 2;
  static float DEFAULT_PARTICLE_SPD  = 25;
  
  // ai director
  static float DEFAULT_GRAPH_DENSITY   = 64;
  static float DEFAULT_RADIUS_FOUND    = PLAYER_SIZE*10; // (in pixels) maximum radius that the monster will look when targeting the player
  static float DEFAULT_RADIUS_SEARCH   = PLAYER_SIZE*5; // (in pixels) maximum search radius that the monster will search AFTER it has lost the player
  static float DEFAULT_IN_TARGET_RANGE = PLAYER_SIZE/2;
  
  // ui constants
  static float HP_BAR_W   = 250;
  static float MP_BAR_W   = 250;
  static float BAR_H      = 16;
  
  // gameplay
  static int HP_RESTORE_RATE = 600; // every 10 secs of world simulation, restore some hp, NOT IN USE
  static float DEFAULT_MELEE_RANGE = PLAYER_SIZE*2; // should make this depend on the currently equip'd weapon
  static float DEFAULT_MELEE_PUSHBACK = 500;
  static float DEFAULT_SPRINT_MULTIPLIER = 2.0f;
  
  // number of FWorld simulation steps before a particle automatically dies, assumes we are using just FWorld.step() and not FWorld.step(time)
  // since each FWorld.step() advances the world simulation by 1/60th of a second, timeleft * 1/60 = number of seconds this particle is alive for
  static int DEFAULT_PARTICLE_TIMEOUT = 60;
  static int DEFAULT_TORCH_TIMEOUT = 120;
  static int DEFAULT_RELOAD_TIME = DEFAULT_PARTICLE_TIMEOUT + DEFAULT_TORCH_TIMEOUT;  
  
  static float DEFAULT_FLARE_SIZE = DEFAULT_RADIUS_FOUND*1.25; // player gets 25% more search radius
  static float DEFAULT_TORCH_SIZE = DEFAULT_FLARE_SIZE*3;
  
  // misc 
  static boolean NO_STROKE = true; // determines whether or not our objects in FWorld are drawn with a stroke
}
