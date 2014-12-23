EscapeVelocity
===============
## Overview
The player is scientist who has predicted the implosion of his own planet. Large shockwaves has damaged his spaceship and his invention, a resource cloning device. There are only 10 minutes until the implosion event. To successfully escape the dying planet the player must gather enough resources from deposits and perform the required repairs to the spaceship. The spaceship will attempt to launch after 10 minutes no matter what the player is doing.

The main resources available to the player are:
* Iron
* Crystal
* Gas
* Lead

and the player needs to repair the following parts:
* Hull
* Life Support
* Radiation Shields
* Thrusters

Drones are used to gather resources and repair the spaceship. Initially the player has control of one drone and up to three more can be created if the player has enough resources.

Each spaceship part requires a different amount of resources and there are multiple levels of repair. Each part initially begins at a “Broken” state. The next states in order are “Damaged”, “Fragile” and “Repaired”. The state of each part affects whether or not the player survives. Once the spaceship has launched, each part will be checked for failure. Broken parts will have the highest probability of failing while Repaired parts will have the lowest probability of failing.

The player dies if there is:

1. at least one broken part which fails
2. at least one damaged part which fails and any additional damaged, fragile or repaired parts which also fail
3. at least one fragile part which fails and at least two damaged, fragile or repaired parts which also fail
4. a freak accident and all repaired parts fail

## Controls
* **Press 1 to 4** to select Drone 1 to 4 individually if they are available (purchase will be attempted if the drone is not activated yet).
* **Left-click and Drag** to create a green selection rectangle which selects multiple drones.
* **Left-click** deselects all selected drones.
* **Right-click** on the map to set a flag. Selected drones will move towards the flag automatically.