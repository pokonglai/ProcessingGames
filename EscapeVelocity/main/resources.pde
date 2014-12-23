// generic resources
public class Resources
{
  float iron; // hull
  float crystal; // energy for life support and alot of other tasks like repairing
  float gas; // fuel
  float lead; // radiation shields
  
  public Resources()
  {
    iron = 0;
    crystal = 0;
    gas = 0;
    lead = 0;
  }
  
  String toString() { return "Iron(" + iron + ")  Crystal(" + crystal + ")  Gas(" + gas + ")  Lead(" + lead + ")";   }
}

public class ResourceBackpack
{
  Resources res;
  Resources limits; // maximum amount before it will move back to the spaceship
  
  public ResourceBackpack(float lim_i, float lim_c, float lim_g, float lim_l)
  {
    res = new Resources();
    limits = new Resources();
    limits.iron    = lim_i;
    limits.crystal = lim_c;
    limits.gas     = lim_g;
    limits.lead    = lim_l;
  }
  
  void addResource(String name, float amt)
  {
    if (name.equals("Iron"))
    {
      if (res.iron + amt > limits.iron) res.iron = limits.iron;
      else res.iron += amt;
    }
    if (name.equals("Crystal"))
    {
      if (res.crystal + amt > limits.crystal) res.crystal = limits.crystal;
      else res.crystal += amt;
    }
    if (name.equals("Gas"))
    {
      if (res.gas + amt > limits.gas) res.gas = limits.gas;
      else res.gas += amt;
    }
    if (name.equals("Lead"))
    {
      if (res.lead + amt > limits.lead) res.lead = limits.lead;
      else res.lead += amt;
    }
  }
  
  boolean isFull(String name)
  {
    if (name.equals("Iron")) return res.iron >= limits.iron;
    if (name.equals("Crystal")) return res.crystal >= limits.crystal;
    if (name.equals("Gas")) return res.gas >= limits.gas;
    if (name.equals("Lead")) return res.lead >= limits.lead;
    return false;
  }
}

public class ResourceDeposit extends WallBlock
{
  String name;
  
  Rectangle collection_range;
  float collection_rate;
  
  int num_of_collectors; // number of drones at this particular resource deposit, the more the faster the collection rate
  
  public ResourceDeposit(float x, float y, float w, float h)
  {
    super(x, y, w, h);
    
    name = "Resource";
    collection_range = actual.inflate(Global.PLAYER_SIZE*2); // rectangle where the bots can collect resources
    collection_rate = 1; // one unit per frame, 60 frames per second = 60 units per second
    num_of_collectors = 0;
    
    setSensor(false);
  }
  
  boolean contains(float x, float y) { return collection_range.contains(x, y); }
  float center_x() { return collection_range.center_x(); }
  float center_y() { return collection_range.center_y(); }
  float rate() { return num_of_collectors * collection_rate; }
}

public class IronDeposit extends ResourceDeposit
{
  public IronDeposit(float x, float y, float w, float h)
  {
    super(x, y, w, h);
    setFill(100, 100, 100, 0);
    
    name = "Iron";
    collection_rate = 0.3;
  }
}

public class CrystalDeposit extends ResourceDeposit
{
  public CrystalDeposit(float x, float y, float w, float h)
  {
    super(x, y, w, h);
    setFill(100, 100, 100, 0);
    
    name = "Crystal";
    collection_rate = 0.2;
  }
}

public class GasDeposit extends ResourceDeposit
{
  public GasDeposit(float x, float y, float w, float h)
  {
    super(x, y, w, h);
    setFill(100, 100, 100, 0);
    
    name = "Gas";
    collection_rate = 0.6;
  }
}

public class LeadDeposit extends ResourceDeposit
{
  public LeadDeposit(float x, float y, float w, float h)
  {
    super(x, y, w, h);
    setFill(100, 100, 100, 0);
    
    name = "Lead";
    collection_rate = 0.4;
  }
}


