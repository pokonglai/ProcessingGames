public class Rectangle
{
  // corners of the rectangle
  // NOTE: small bug where topleft = bottomleft, just offset by the height of the rectangle, contains and overlap work so just fix this later
  PVector topleft;
  PVector bottomright;
  PVector bottomleft;
  PVector topright;
  
  public Rectangle(float x, float y, float w, float h)
  {
    topleft = new PVector(x, y);
    topright = new PVector(x + w, y);
    bottomleft = new PVector(x, y + h);
    bottomright = new PVector(x + w, y + h);
  }
  
  public Rectangle cpy()
  {
    Rectangle ret = new Rectangle(0,0,0,0);
    ret.topleft = topleft.get();
    ret.topright = topright.get();
    ret.bottomleft = bottomleft.get();
    ret.bottomright = bottomright.get();
    return ret;    
  }
  
  float width() { return topright.x - topleft.x; }
  float height() { return topleft.y - bottomleft.y; }
  float center_x() { return topleft.x + width()/2; }
  float center_y() { return topleft.y - height()/2; }
  
  boolean contains(float x, float y)
  {
    boolean inXRange = topleft.x <= x && bottomright.x >= x;
    boolean inYRange = topleft.y <= y && bottomright.y >= y;
    return inXRange && inYRange;
  }
  
  // returns if this room contains or overlaps with the input rectangle
  boolean overlap(Rectangle r)
  {
    boolean bTL = contains(r.topleft.x, r.topleft.y);
    boolean bTR = contains(r.topright.x, r.topright.y);
    boolean bBL = contains(r.bottomleft.x, r.bottomleft.y);
    boolean bBR = contains(r.bottomright.x, r.bottomright.y);
   
    // finally need to check one more special case where the rooms overlap
    // but the corners are not contained in either room
    boolean inXRange = topleft.x <= r.topleft.x && bottomright.x >= r.bottomright.x;
    boolean inYRange = topleft.y <= r.topleft.y && bottomright.y >= r.bottomright.y;
   
    boolean containsXRange = topleft.x >= r.topleft.x && bottomright.x <= r.bottomright.x;
    boolean containsYRange = topleft.y >= r.topleft.y && bottomright.y <= r.bottomright.y;
   
    boolean no_corner_overlap =  (containsXRange && inYRange) || (containsYRange && inXRange);
   
    return bTL || bTR || bBL || bBR || no_corner_overlap;
  }
  
  // return a new rectangle where each of the corners has moved away from the center
  Rectangle inflate(float amount)
  {
    Rectangle r = cpy();
    r.topleft.x -= amount;
    r.topleft.y -= amount;    
    r.topright.x += amount;
    r.topright.y -= amount;
    r.bottomleft.x -= amount;
    r.bottomleft.y += amount;
    r.bottomright.x += amount;
    r.bottomright.y += amount;
    return r;
  }
  
  String toString()
  {
    String ret = "";
    ret += "TL : " + topleft +"\n";
    ret += "TR : " + topright +"\n";
    ret += "BR : " + bottomright +"\n";
    ret += "BL : " + bottomleft +"\n";
    ret += "\n";
    return ret;
  }
}
