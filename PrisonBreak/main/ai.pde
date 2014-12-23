/**
Current just encapsulates a large and dense waypoint graph.

Possible addtions:
- Implement swarm type behaviour by making each monster aware of each other
wrt to the waypoint graph. States of the monster can then be set directly.
**/


public class AIDirector
{
  float min_x, min_y, max_x, max_y; // bounds of our waypoint graph
  Graph graph; // TODO: use a list when implementing multiple floors
  GraphSearch_Astar pathfinder;
  
  float density;
  
  public AIDirector(float d)
  {
    graph = new Graph();
    pathfinder = null;
    density = d;
    
    min_x = Global.WORLD_WALL_EDGE_OFFSET+Global.PLAYER_SIZE;
    min_y = Global.WORLD_WALL_EDGE_OFFSET+Global.PLAYER_SIZE;
    max_x = width - Global.WORLD_WALL_EDGE_OFFSET;
    max_y = height - Global.WORLD_WALL_EDGE_OFFSET;
  }
  
  // given a floor, build a large and dense waypoint graph
  void buildGraph(Floor f)
  {
    float diagonal_len = sqrt((max_x - min_x)*(max_x - min_x) + (max_y - min_y)*(max_y - min_y)); 
    float size = diagonal_len / density;
    
    int id = 0;
    int numOfNodeW = (int)((max_x - min_x)/size) + 1;
    int numOfNodeH = (int)((max_y - min_y)/size) + 1;
    int totalNumOfNode = numOfNodeW * numOfNodeH;
    float x = min_x;
    float y = min_y;
    
    float grid_max_x = x;
    float grid_max_y = y;
    
    // first create a grid-graph using 4-neighbourhood, density controls the square size
    while (x < max_x)
    {
      while(y <= max_y)
      {
        graph.addNode(new GraphNode(id, x, y));
        
        int above = id - 1;
        int below = id + 1;
        int left = id - numOfNodeH;
        int right = id + numOfNodeH;
        
        // 4 neighbourhood
        if (above >= 0 && above <= totalNumOfNode && (above % numOfNodeH) != numOfNodeH-1) graph.addEdge(id, above, size); // do not link top level nodes to bottom level nodes on another strip
        if (below >= 0 && below <= totalNumOfNode && (below % numOfNodeH) != 0) graph.addEdge(id, below, size);
        if (left >= 0 && left <= totalNumOfNode) graph.addEdge(id, left, size);
        if (right >= 0 && right <= totalNumOfNode) graph.addEdge(id, right, size);
        
        id++;
        grid_max_y = max(grid_max_y, y);
        y += size;
      }
      y = min_y;
      grid_max_x = max(grid_max_x, x);
      x += size;
    }
    
    // now add in the center nodes inside each square and link the corner square nodes to it
    int center_id = id+1;
    id = 0;
    x = min_x;
    y = min_y;
    float diagonal_weight = sqrt(2*(size/2)*(size/2));
    while (x < max_x)
    {
      while(y <= max_y)
      {
        float cx = x + size/2;
        float cy = y + size/2;
        
        // ensure the center nodes are inside the grid
        if (cx <= grid_max_x && cy <= grid_max_y)
        {
          graph.addNode(new GraphNode(center_id, cx, cy));

          // add new edges that connect the center node with the square corner nodes          
          int below = id + 1;
          int right = id + numOfNodeH;
          int below_right = id + 1 + numOfNodeH;

          graph.addEdge(id, center_id, diagonal_weight);
          graph.addEdge(center_id, id, diagonal_weight);
          
          graph.addEdge(below, center_id, diagonal_weight);
          graph.addEdge(center_id, below, diagonal_weight);
          
          graph.addEdge(right, center_id, diagonal_weight);
          graph.addEdge(center_id, right, diagonal_weight);
          
          graph.addEdge(below_right, center_id, diagonal_weight);
          graph.addEdge(center_id, below_right, diagonal_weight);
          
          center_id++;
        }
        id++;
        y += size;
      }
      y = min_y;
      x += size;
    }

    // next eliminate all the nodes that are "too close" to the walls
    ArrayList<Integer> badNodes = new ArrayList<Integer>();
    for (GraphNode n : graph.getNodeArray())
      for (WallBlock wb : floor.obstacles)
        if (wb.outer.contains(n.xf(), n.yf()))
          badNodes.add(n.id());

    for (Integer bad : badNodes) graph.removeNode(bad);
    graph.compact();
    
    // finally delete the nodes which now have no edges linked to it
    badNodes.clear();
    for (GraphNode n : graph.getNodeArray())
      if (graph.getEdgeList(n.id()).size() == 0)
        badNodes.add(n.id());
    for (Integer bad : badNodes) graph.removeNode(bad);
    graph.compact();
    
    pathfinder = new GraphSearch_Astar(graph);
    
    println("Waypoint Graph Created:");
    println("===============================");
    println("Nodes: " + graph.getNbrNodes()  + "    Edges: " + graph.getAllEdgeArray().length);
  }
  
  // find the node which is closest to the given x and y
  GraphNode closestNode(float x, float y)
  {
    float mindist = MAX_FLOAT;
    GraphNode ret = null;
    for (GraphNode n : graph.getNodeArray())
    {
      float dx = n.xf() - x;
      float dy = n.yf() - y;
      float dist = dx*dx + dy*dy; // use squared distance since we do not care about numerical accuarcy, only relative
      if (dist < mindist)
      {
        mindist = dist;
        ret = n;
      }
    }
    return ret;
  }
  
  GraphNode randomNode()
  {
    int index = (int)random(0, graph.getNbrNodes());
    return graph.getNodeArray()[index];
  }
  
  float minimumGraphDistance(Entity e1, Entity e2)
  {
    GraphNode gn1 = closestNode(e1.x(), e1.y());
    GraphNode gn2 = closestNode(e2.x(), e2.y());
    if (gn1.id() == gn2.id()) return 0;
    
    pathfinder.search(gn1.id(), gn2.id());
    GraphNode[] path = pathfinder.getRoute();
    
    float total_dist = 0;
    
    GraphNode prev = null;
    GraphNode cur = null;
    for (int i = 0; i < path.length; i++)
    {
      if (prev == null)
      {
        prev = path[i];
      }
      else
      {
        cur = path[i];
        float dx = prev.xf() - cur.xf();
        float dy = prev.yf() - cur.yf();
        total_dist += sqrt(dx*dx + dy*dy);
      }
    }
    return total_dist;
  }
  
  // randomly place the monsters such that they are not inside obstacles and not too close to the player
  void spawnMonsters(Floor f, Entity player)
  {
    int nMonster = (int)random(Global.MIN_MONSTER, Global.MAX_MONSTER);

    for (int i = 1; i <= nMonster; i++)
    {
      float posx = random(min_x, max_x);
      float posy = random(min_y, max_y);
      
      while (true)
      {
        // never spawn monsters inside rooms (for now...)
        boolean inNoObstacle = true;
        for (WallBlock wb : f.obstacles)
        {
          if (wb.outer.contains(posx, posy))
            inNoObstacle = false;
        }
        
        boolean closeToPlayer = true;
        float dx = player.x() - posx;
        float dy = player.y() - posy;
        float dist = sqrt(dx*dx + dy*dy);
        if (dist > sqrt(width*width + height*height)/10) closeToPlayer = false;
        
        
        if (inNoObstacle && closeToPlayer == false) break;
        else
        {
          posx = random(min_x, max_x);
          posy = random(min_y, max_y);
        }
      }
      Monster m = new Monster(posx, posy, Global.PLAYER_SIZE);
      m.stats.STR = 4;
      f.monsters.add(m);
    }
  }
  
  void displayGraph()
  {
    for (GraphEdge e : graph.getAllEdgeArray()) line(e.from().xf(), e.from().yf(), e.to().xf(), e.to().yf());
    for (GraphNode n : graph.getNodeArray())
    {
      text(""+n.id(), n.xf(), n.yf());
      ellipse(n.xf(), n.yf(), 3, 3);
    }
  }
}
