import processing.serial.*; //<>// //<>// //<>//
import java.util.Iterator;

/*
Z + - go right
 Z - - go left
 Y + - go forward
 Y - - go backward
 */
/*
 Ship
 first block width = ship.SHIP_WIDTH/2;
 first block height = ship.SHIP_HEIGHT - 50;
 */

final float X_POSITIVE_THRESHOLD = 0.15;
final float Y_POSITIVE_THRESHOLD = 0.15;
final float Z_POSITIVE_THRESHOLD = 0.15;

final float X_NEGATIVE_THRESHOLD = -0.15;
final float Y_NEGATIVE_THRESHOLD = -0.15;
final float Z_NEGATIVE_THRESHOLD = -0.15;

final int MAX_ASTEROIDS = 5;
final int DEFAULT_ASTEROID_SPEED = 2;
final int DEFAULT_SHIP_SPEED = 4;

final float DEFAULT_GAME_STEP = Asteroid.ASTEROID_HEIGHT;

class Ship {
  static final float SHIP_WIDTH = 85;
  static final float SHIP_HEIGHT = 150;

  float x, y, z, speed;
  ArrayList<Block> shipBlocks;

  Ship(float x, float y, float z, float speed, ArrayList<Block> shipBlocks) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.speed = speed;
    this.shipBlocks = shipBlocks;
  }
}

class Asteroid {
  static final float ASTEROID_WIDTH = 50;
  static final float ASTEROID_HEIGHT = 50;

  float x, y, z, speed;
  Asteroid(float x, float y, float z, float speed) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.speed = speed;
  }
}

class Block {
  float leftX, rightX, upperY, lowerY;
  Block(float leftX, float rightX, float upperY, float lowerY) {
    this.leftX = leftX;
    this.rightX = rightX;
    this.upperY = upperY;
    this.lowerY = lowerY;
  }
}

enum GameState {
  RUNNING, STOPPED;
}

enum InputType {
  ACCELERATION, ORIENTATION, TAP, DOUBLETAP;
}

enum MoveType {
  NONE, FORWARD, BACKWARD, RIGHT, LEFT;
}

Serial communicationPort;
GameState gameState;
Ship ship;
ArrayList<Asteroid> asteroids;
int gameStep;
PImage shipImage;
PImage asteroidImage;

void configurePort() {
  communicationPort = new Serial(this, Serial.list()[Serial.list().length - 1], 9600);
  communicationPort.bufferUntil('\n'); //TODO may need to remove this
}

InputType determineInputType(String inputString) {
  if (inputString.contains("orientation")) {
    return InputType.ORIENTATION;
  } else {
    if ((inputString.contains("Tap")) || (inputString.contains("tap"))) {
      if ((inputString.contains("single")) || (inputString.contains("Single"))) {
        return InputType.TAP;
      } 
      if ((inputString.contains("double")) || (inputString.contains("Double"))) {
        return InputType.DOUBLETAP;
      }
    }
  }
  return InputType.ACCELERATION;
}

boolean checkInputDataIntegrity(String inputString) {
  return split(inputString, " ").length == 3;
}

float[] parseInputForAcceleration(String inputString) {
  return float(split(inputString, " "));
}

MoveType determineMoveType(float[] inputAcceleration) {
  //System.out.println(inputAcceleration[0] + " " + inputAcceleration[1] + " " + inputAcceleration[2]);
  if (inputAcceleration[1] > Y_POSITIVE_THRESHOLD) {
    return MoveType.FORWARD;
  } else {
    if (inputAcceleration[1] < Y_NEGATIVE_THRESHOLD) {
      return MoveType.BACKWARD;
    } else {
      if (inputAcceleration[2] > Z_POSITIVE_THRESHOLD) {
        return MoveType.LEFT;
      } else {
        if (inputAcceleration[2] < Z_NEGATIVE_THRESHOLD) {
          return MoveType.RIGHT;
        }
      }
    }
  }

  return MoveType.NONE;
}

boolean isShipOutOfScreen() {
  return ship.x + Ship.SHIP_WIDTH > width || ship.x < 0 || ship.y + Ship.SHIP_HEIGHT > height || ship.y < 0;
}

void calculateShipBlocks() {
  for (int i = 0; i < ship.shipBlocks.size(); i++) {
    Block block = ship.shipBlocks.get(i);
    if (i == 0) {
      block.leftX = ship.x + Ship.SHIP_WIDTH / 4;
      block.rightX = ship.x + (Ship.SHIP_WIDTH / 4) * 3;
      block.upperY = ship.y;
      block.lowerY = ship.y + Ship.SHIP_HEIGHT - 50;
    }
    if (i == 1) {
      block.leftX = ship.x;
      block.rightX = ship.x + Ship.SHIP_WIDTH;
      block.upperY = ship.y + Ship.SHIP_HEIGHT - 50;
      block.lowerY = ship.y + Ship.SHIP_HEIGHT;
    }
  }
}

void updateCurrentCoordinates(float[] inputAcceleration) {
  switch(determineMoveType(inputAcceleration)) {
  case FORWARD:
    ship.y -= ship.speed;
    if (isShipOutOfScreen() == false) {
      rect(ship.x - 1, ship.y + ship.speed - 1, Ship.SHIP_WIDTH + 1, Ship.SHIP_HEIGHT + 1);
      image(shipImage, ship.x, ship.y, Ship.SHIP_WIDTH, Ship.SHIP_HEIGHT);
      calculateShipBlocks();
    }
    break;
  case BACKWARD:
    ship.y += ship.speed;
    if (isShipOutOfScreen() == false) {
      rect(ship.x - 1, ship.y - ship.speed - 1, Ship.SHIP_WIDTH + 1, Ship.SHIP_HEIGHT + 1);
      image(shipImage, ship.x, ship.y, Ship.SHIP_WIDTH, Ship.SHIP_HEIGHT);
      calculateShipBlocks();
    } 
    break;
  case RIGHT:
    ship.x += ship.speed;
    if (isShipOutOfScreen() == false) {
      rect(ship.x - ship.speed - 1, ship.y - 1, Ship.SHIP_WIDTH + 1, Ship.SHIP_HEIGHT + 1);
      image(shipImage, ship.x, ship.y, Ship.SHIP_WIDTH, Ship.SHIP_HEIGHT);
      calculateShipBlocks();
    }
    break;
  case LEFT:
    ship.x -= ship.speed;
    if (isShipOutOfScreen() == false) {
      rect(ship.x + ship.speed - 1, ship.y - 1, Ship.SHIP_WIDTH + 1, Ship.SHIP_HEIGHT + 1);
      image(shipImage, ship.x, ship.y, Ship.SHIP_WIDTH, Ship.SHIP_HEIGHT);
      calculateShipBlocks();
    }
    break;
  case NONE:
    break;
  }
}

boolean detectCollision() {
  for (Asteroid asteroid : asteroids) {
    for (Block block : ship.shipBlocks) {
      if (block.leftX < asteroid.x + Asteroid.ASTEROID_WIDTH &&
        block.rightX > asteroid.x &&
        block.upperY < asteroid.y + Asteroid.ASTEROID_HEIGHT &&
        block.lowerY > asteroid.y) {
        return true;
      }
    }
  }
  return false;
}

void handleAcceleration(String inputString) {
  if (checkInputDataIntegrity(inputString)) {
    updateCurrentCoordinates(parseInputForAcceleration(inputString));
  }
}

void handleOrientation() {
  // do nothing
}

void handleTap() {
  ship.speed += DEFAULT_SHIP_SPEED;
}

void handleDoubleTap() {
  if (ship.speed > 0) {
    ship.speed -= DEFAULT_SHIP_SPEED;
  }
}

void readInput() {
  //String inputString = communicationPort.readStringUntil('\n');
  String inputString = communicationPort.readString();
  System.out.println(inputString);
  if (inputString != null) {
    inputString = trim(inputString);
    InputType inputType = determineInputType(inputString);
    switch(inputType) {
    case ACCELERATION:
      handleAcceleration(inputString);
      break;
    case ORIENTATION:
      handleOrientation();
      break;
    case TAP:
      handleTap();
      break;
    case DOUBLETAP:
      handleDoubleTap();
      break;
    }
  }
}

void generateAsteroid() {
  if ((gameStep % DEFAULT_GAME_STEP == 0) && (asteroids.size() < MAX_ASTEROIDS)) {
    Asteroid asteroid = new Asteroid(random(width - Asteroid.ASTEROID_WIDTH), 0, 0, DEFAULT_ASTEROID_SPEED);
    image(asteroidImage, asteroid.x, 0, Asteroid.ASTEROID_WIDTH, Asteroid.ASTEROID_HEIGHT);
    asteroids.add(asteroid);
  }
  gameStep++;
}

void updateAsteroids() {
  Iterator<Asteroid> it = asteroids.iterator();
  while (it.hasNext()) {
    Asteroid asteroid = it.next();
    rect(asteroid.x, asteroid.y, Asteroid.ASTEROID_WIDTH, Asteroid.ASTEROID_HEIGHT);
    asteroid.y += asteroid.speed;

    if (asteroid.y < height) {
      image(asteroidImage, asteroid.x, asteroid.y, Asteroid.ASTEROID_WIDTH, Asteroid.ASTEROID_HEIGHT);
    } else {
      it.remove();
    }
  }
}

void initializeShip() {
  Block upperBlock = new Block(0, 0, 0, 0);
  Block lowerBlock = new Block(0, 0, 0, 0);
  ArrayList<Block> shipBlocks = new ArrayList<Block>();
  shipBlocks.add(0, upperBlock);
  shipBlocks.add(1, lowerBlock);
  ship = new Ship(width/2 - Ship.SHIP_WIDTH/2, height - Ship.SHIP_HEIGHT, 0, DEFAULT_SHIP_SPEED, shipBlocks);
  calculateShipBlocks();
}

void setup() {
  size(800, 600);
  background(255, 255, 255);

  configurePort();
  noStroke();
  gameState = GameState.RUNNING;
  asteroidImage = loadImage("asteroid.jpg");
  shipImage = loadImage("ship.jpg");
  initializeShip();
  image(shipImage, ship.x, ship.y, Ship.SHIP_WIDTH, Ship.SHIP_HEIGHT);
  asteroids = new ArrayList<Asteroid>();
  gameStep = 0;
}

void draw() {
  if (gameState == GameState.RUNNING) {
    updateAsteroids();
    generateAsteroid();
    readInput();
    if (detectCollision() == true) {
      gameState = GameState.STOPPED;
    }
  }
  delay(50);
}