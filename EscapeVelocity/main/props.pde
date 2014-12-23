public class Props
{
  float HP_MAX;
  float HP;
  float MP_MAX;
  float MP;
  float STAMINA_MAX;
  float STAMINA;
  
  float STR; // physical attack
  float STR_ORI;
  
  float VIT; // physical defence
  float VIT_ORI;
  
  float INT; // magical attack
  float INT_ORI;
  
  float SPR; // magical defence
  float SPR_ORI;
  
  float AGI; // affects movement speed of entities
  float AGI_ORI;
  
  float LUK; // affects drop rates and other random bonuses??
  float LUK_ORI;
  
  public Props()
  {
    HP = HP_MAX = 10;
    MP = MP_MAX = 10;
    STAMINA_MAX = STAMINA = 100;
    
    STR = STR_ORI = 3;
    VIT = VIT_ORI = 2;
    INT = INT_ORI = 1;
    SPR = SPR_ORI = 1;
    AGI = AGI_ORI = 1;
  }
  
  // this needs to be balanced
  float PATK() { return STR + STR/5 + VIT/10 + AGI/10 + LUK/10; }
  float PDEF() { return VIT + VIT/5 + STR/10 + AGI/20 + LUK/20; }
  float MATK() { return INT + INT/2 + SPR/2 + LUK/20; }
  float MDEF() { return SPR + SPR/2 + INT/2 + LUK/20; }
  float MOV_SPD() { return 1 + AGI/10; };
}
