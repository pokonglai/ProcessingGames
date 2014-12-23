public class Timer
{
  int startTime; // when the timer started
  int timeLength; // length of timer
  int offset; // pause the timer
  
  public Timer(int len)
  {
    timeLength = len;
    offset = 0;
  }
  
  void pause() { offset = elapsed(); } // TODO: really flesh this out and make it more than a hack
  void begin() { startTime = millis(); offset = 0; }
  int elapsed()
  {
    if (offset > 0) return offset;
    return millis() - startTime;
  }
  boolean timeup() { return elapsed() > timeLength; }
  
  String toString() { return "Start: " + startTime + " " + timeLength + " " + elapsed(); } 
}
