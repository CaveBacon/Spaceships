
This is simulation where Neural Networks play a Real-Time Strategy game against each other.

You can see a video of it in action here: https://youtu.be/2T_Yk-HM9xg

#How to Build:
You will need the DMD compiler, available from: https://dlang.org/download.html#dmd
and DSFML from: http://jebbs.github.io/DSFML/downloads.html

This project includes the source for Artifical Neural networks in D (AND), a neural net library which I updated to be compatible with D2.0
The original source is available here: http://dsource.org/projects/and

Put the DSFML folder in the Spaceships/ folder.
Copy the DLLs from the DSFML/lib folder into the Spaceships/ folder.
Change the %dmd% variable in build.bat to reflect the location where you downloaded DMD.


#Running the Program:
The game can be run in different modes from the command line.
There are 4 batch files included which will run the game in one of the four modes.

The first parameter indicates the game mode:
- tourney: all AIs play against each other in a round-robin fasion.
- play:    Manual Control, loops through all AI opponents.
- duel (followed by two player numbers): watch 2 AIs repreatedly play against each other (specified by the next 2 parameters)
- nemesis (followed by a player number): repeatedly play agaisnt a specific AI (specified by the next parameter)

The last parameter is the game speed.  I reccommend between 2.5 and 4.0 for manual control, and between 5.0 and 10.0 for watching.

#The Game:
Each player starts with a Mothership (large diamond) at opposing corners of the screen.
There are 12 capture points (+ symbols) on the screen.  Players gain an Income based on the number of Points they control, which determines how fast the Mothership can build new units.
Controlling more points than the opponent makes thier victory counter (bar at the top of the screen) shrink. 
A player wins by reducing thier opponent's victory counter to 0.

There are 6 types of ships in the game, each fitting into one of three roles: Anti-Light, Anti-Heavy, and Economic.  
There is a Light and Heavy ship type for each role.  A ship's "weight" is indicated by its size, and its role is indicated by its shape.

Light Ships are fast and deal higher damage for thier cost than equivalent Heavy ships. 
  - Interceptor (small triangle, Anti-Light)  
  - Destroyer   (small square,   Anti-Heavy)   
  - Miner       (small diamond,  Economic  ) 
  
Heavy Ships are slow and costly to produce, but have a significantly longer attack range than Light Ships. 
  - Cruiser     (large triangle, Anti-Light) 
  - Battleship  (large square,   Anti-Heavy) 
  - Mothership  (large diamond,  Economic  )    


Combat ships deal double damage to either Light or Heavy ships, depending on thier role.  
Economic ships are generally ineffective in combat, but deal equal damage to all targets.   
  -  Motherships build units.  Multiple Motherships increase the overall speed of unit produciton logarithmically. 
  -  Miners increases income when close to a point.  Multiple miners on the same point get diminishing returns. 
   
      

##Observer Controls:
  When watching the AI's play against each other, you can press Alt + End to start the next match if the current one is uninteresting (as many will be if the NN's haven't been training for very long)
  

##Manual Controls:
By running play_spaceships.bat, you can manually control a fleet against the Neural Net AIs.
  in this mode, press the Q, W, E, A, S, D keys to change the type of unit currently being produced.
  These keys form a grid based on the properties of the unit type:
   - The first row  (Q, W, E) produce Small Ships
   - The second row (A, S, D) produce Large Ships
    
   - The first column  (Q, A) produces units which are effective against Small Ships.
   - The second column (W, S) produces units which are effective against Large Ships.
   - The third column  (E, D) produces economic units.
    
  To control your units:
   - Right-Click to instruct any currently selected units to move to the location of your mouse pointer.
  
   - Left-Click and drag to select all units in a circle. (this will be chagned to a square after an update to the collision-detection system)
   - Press Space to select all non-economic units near your cursor.
   -Hold shift while selecting to add units to your current selection.
   
   
# The AIs
 
In the current build (as of 2017 1 26), there are 9 AIs that the game will rotate through.
 - Red, Steel-Blue, Chartruse, Coral, Dark-Violet, and Deep-Pink are Neural Net AIs
 - DarkGrey is a Neural Net AI that also learns from watching the games you manually controll.
 - Yellow-Orange is a scripted bot that picks all actions randomly
 - Dark-Teal is a scripted bot that aggressively focuses on capturing points.
