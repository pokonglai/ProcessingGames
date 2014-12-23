public class Damage
{
  static final short DMG_Physical = 0x0001;
  static final short DMG_Magical  = 0x0002;
  
  short type;
  float amount;
  PVector force; // direction and magnitude of the force to be applied
  
  public Damage()
  {
    type = DMG_Physical;
    amount = 0;
    force = new PVector();
  }
  
  public Damage(short t, float dmg, PVector f)
  {
    type = t;
    amount = dmg;
    force = f;
  }
}
