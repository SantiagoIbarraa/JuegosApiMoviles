
// Agar.io Profesional - Processing
// Versión corregida y optimizada - COMPLETA

// ================================
// CONFIGURACIÓN GLOBAL
// ================================
final int WORLD_WIDTH = 4000;
final int WORLD_HEIGHT = 4000;
final int FOOD_COUNT = 500;
final int BOT_COUNT = 24;
final float MIN_MASS = 10;
final float MAX_MASS = 2000; // Aumentado para una partida más larga
final float EAT_RATIO = 1.2;
final float MASS_GAIN_FACTOR = 0.8;
final int GRID_SIZE = 50;
final float CAMERA_LERP_SPEED = 0.08;

// Variables de debug
boolean DEBUG_MODE = false;
boolean SHOW_VISION_RANGE = false;

// ================================
// VARIABLES GLOBALES
// ================================
GameManager gameManager;
Renderer renderer;
boolean gameRunning = true;
SoundManager soundManager;
ParticleSystem particleSystem;

// ================================
// SETUP Y DRAW PRINCIPALES
// ================================
void setup() {
  size(1362, 675);
  
  // Inicializar sistemas
  gameManager = new GameManager();
  renderer = new Renderer();
  soundManager = new SoundManager();
  particleSystem = new ParticleSystem();
  
  println("Agar.io Professional - Iniciado correctamente");
  println("Mundo: " + WORLD_WIDTH + "x" + WORLD_HEIGHT);
  println("Bots: " + BOT_COUNT + ", Comida: " + FOOD_COUNT);
  println("Controles: P=Pausa, R=Reiniciar, D=Debug, V=Visión");
}

void draw() {
  if (!gameRunning) {
    drawPauseScreen();
    return;
  }
  
  // Actualizar juego
  gameManager.update();
  
  // Actualizar partículas
  particleSystem.update();
  
  // Renderizar
  renderer.render(gameManager);
  
  // Renderizar UI (encima de todo)
  gameManager.ui.display(gameManager.player, gameManager.bots);

  // Debug info
  if (DEBUG_MODE) {
    renderer.renderDebugInfo(gameManager);
  }
  
  // Mostrar mensaje de muerte si es necesario
  if (gameManager.showDeathMessage) {
    drawDeathScreen();
  }
}

void drawPauseScreen() {
  // Renderizar el juego en pausa
  renderer.render(gameManager);
  
  // Overlay de pausa
  fill(0, 150);
  rect(0, 0, width, height);
  
  // Texto de pausa
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("PAUSA", width/2, height/2 - 50);
  
  textSize(24);
  text("Presiona P para continuar", width/2, height/2 + 20);
  text("R para reiniciar", width/2, height/2 + 50);
}

void drawDeathScreen() {
  fill(255, 0, 0, 150);
  rect(0, 0, width, height);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(48);
  text("¡GAME OVER!", width/2, height/2 - 50);
  
  textSize(24);
  text("Masa final: " + int(gameManager.player.mass), width/2, height/2);
  text("Ranking: #" + gameManager.ui.calculatePlayerRank(gameManager.player, gameManager.bots), width/2, height/2 + 30);
  text("Presiona R para reiniciar", width/2, height/2 + 80);
  
  // Auto-reinicio después de 3 segundos
  if (millis() - gameManager.deathTime > 3000) {
    gameManager.resetGame();
  }
}

// ================================
// MANEJO DE TECLADO
// ================================
void keyPressed() {
    if (key == 'p' || key == 'P') {
        gameRunning = !gameRunning;
    }
    if (key == 'r' || key == 'R') {
        gameManager.resetGame();
        gameRunning = true;
    }
    if (key == 'd' || key == 'D') {
        DEBUG_MODE = !DEBUG_MODE;
    }
    if (key == 'v' || key == 'V') {
        SHOW_VISION_RANGE = !SHOW_VISION_RANGE;
    }
}


// ================================
// GAME MANAGER
// ================================
class GameManager {
  Player player;
  ArrayList<Bot> bots;
  ArrayList<Food> foods;
  Camera camera;
  UI ui;
  CollisionManager collisionManager;
  boolean showDeathMessage = false;
  int deathTime = 0;
  
  GameManager() {
    initialize();
  }
  
  void initialize() {
    // Inicializar sistemas
    camera = new Camera();
    ui = new UI();
    collisionManager = new CollisionManager();
    
    // Crear jugador en posición segura
    player = new Player(WORLD_WIDTH/2, WORLD_HEIGHT/2);
    
    // Inicializar entidades
    initializeBots();
    initializeFood();
    
    // Reset death message
    showDeathMessage = false;
    deathTime = 0;
    
    println("GameManager inicializado");
  }
  
  void update() {
    // Actualizar cámara
    camera.update(player);
    
    // Actualizar jugador
    player.update();
    
    // Actualizar bots
    updateBots();
    
    // Procesar colisiones
    collisionManager.processCollisions(player, bots, foods);
    
    // Mantener cantidad de comida
    maintainFoodCount();
    
    // Verificar condiciones de victoria
    checkWinCondition();
  }
  
  void checkWinCondition() {
    // Victoria si el jugador alcanza la masa máxima
    if (player.mass >= MAX_MASS * 0.95) {
      println("¡VICTORIA! Masa máxima alcanzada");
      showVictoryMessage();
    }
  }
  
  void showVictoryMessage() {
    fill(0, 255, 0, 150);
    rect(0, 0, width, height);
    
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(48);
    text("¡VICTORIA!", width/2, height/2 - 50);
    
    textSize(24);
    text("¡Dominaste el mundo!", width/2, height/2 + 20);
    text("Presiona R para jugar de nuevo", width/2, height/2 + 50);
  }
  
  void initializeBots() {
    bots = new ArrayList<Bot>();
    
    // Crear bots con posiciones distribuidas uniformemente
    for (int i = 0; i < BOT_COUNT; i++) {
      PVector spawnPos = generateSafeBotSpawn();
      BotType type = getBotTypeByIndex(i);
      Bot bot = new Bot(spawnPos.x, spawnPos.y, type);
      bot.setName("Bot " + (i + 1));
      bots.add(bot);
    }
    
    println("Bots inicializados: " + bots.size());
  }
  
  PVector generateSafeBotSpawn() {
    // Crear zonas de spawn alejadas del centro
    float minDistFromCenter = 300;
    float maxDistFromCenter = 1500;
    
    PVector center = new PVector(WORLD_WIDTH/2, WORLD_HEIGHT/2);
    PVector spawnPos;
    int attempts = 0;
    
    do {
      float x = random(200, WORLD_WIDTH - 200);
      float y = random(200, WORLD_HEIGHT - 200);
      spawnPos = new PVector(x, y);
      attempts++;
      
      // Evitar spawn infinito
      if (attempts > 50) {
        // Forzar spawn en esquinas
        float angle = random(TWO_PI);
        float dist = random(minDistFromCenter, maxDistFromCenter);
        spawnPos.x = center.x + cos(angle) * dist;
        spawnPos.y = center.y + sin(angle) * dist;
        
        // Asegurar límites
        spawnPos.x = constrain(spawnPos.x, 200, WORLD_WIDTH - 200);
        spawnPos.y = constrain(spawnPos.y, 200, WORLD_HEIGHT - 200);
        break;
      }
    } while (PVector.dist(spawnPos, center) < minDistFromCenter);
    
    return spawnPos;
  }
  
  BotType getBotTypeByIndex(int index) {
    if (index < 8) return BotType.EASY;
    if (index < 16) return BotType.MEDIUM;
    return BotType.HARD;
  }
  
  void updateBots() {
    for (int i = bots.size() - 1; i >= 0; i--) {
      Bot bot = bots.get(i);
      bot.update(player, bots, foods);
      
      // Verificar si el bot está atascado
      if (bot.isStuck()) {
        bot.forceNewTarget();
      }
    }
  }
  
  void initializeFood() {
    foods = new ArrayList<Food>();
    for (int i = 0; i < FOOD_COUNT; i++) {
      foods.add(new Food());
    }
    println("Comida inicializada: " + foods.size());
  }
  
  void maintainFoodCount() {
    while (foods.size() < FOOD_COUNT) {
      foods.add(new Food());
    }
  }
  
  void respawnBot(int index) {
    if (index >= 0 && index < bots.size()) {
      Bot oldBot = bots.get(index);
      PVector newPos = generateSafeBotSpawn();
      Bot newBot = new Bot(newPos.x, newPos.y, oldBot.type);
      newBot.setName(oldBot.botName);
      bots.set(index, newBot);
      
      // Efecto de partículas
      particleSystem.addExplosion(oldBot.pos.x, oldBot.pos.y, oldBot.col);
      
      if (DEBUG_MODE) {
        println("Bot respawned at: " + newPos.x + ", " + newPos.y);
      }
    }
  }
  
  void playerDied() {
    showDeathMessage = true;
    deathTime = millis();
    
    // Efecto de partículas
    particleSystem.addExplosion(player.pos.x, player.pos.y, player.col);
    
    println("Jugador murió - Masa final: " + int(player.mass));
  }
  
  void resetGame() {
    println("Reiniciando juego...");
    initialize();
  }
}

// ================================
// COLLISION MANAGER
// ================================
class CollisionManager {
  
  void processCollisions(Player player, ArrayList<Bot> bots, ArrayList<Food> foods) {
    // Colisiones con comida
    processFoodCollisions(player, bots, foods);
    
    // Colisiones entre jugador y bots
    processPlayerBotCollisions(player, bots);
    
    // Colisiones entre bots
    processBotCollisions(bots);
  }
  
  void processFoodCollisions(Player player, ArrayList<Bot> bots, ArrayList<Food> foods) {
    for (int i = foods.size() - 1; i >= 0; i--) {
      Food food = foods.get(i);
      boolean foodEaten = false;
      
      // Colisión con jugador
      if (player.collidesWith(food)) {
        player.eat(food);
        particleSystem.addFoodEaten(food.pos.x, food.pos.y, food.col);
        foods.remove(i);
        foodEaten = true;
      }
      
      // Colisión con bots (solo si no fue comida por el jugador)
      if (!foodEaten) {
        for (Bot bot : bots) {
          if (bot.collidesWith(food)) {
            bot.eat(food);
            particleSystem.addFoodEaten(food.pos.x, food.pos.y, food.col);
            foods.remove(i);
            break;
          }
        }
      }
    }
  }
  
  void processPlayerBotCollisions(Player player, ArrayList<Bot> bots) {
    for (int i = bots.size() - 1; i >= 0; i--) {
      Bot bot = bots.get(i);
      
      if (player.collidesWith(bot)) {
        if(player.canEat(bot)) {
            player.eat(bot);
            gameManager.respawnBot(i);
            soundManager.playEatSound();
        }
      } else if(bot.collidesWith(player)){
         if (bot.canEat(player)) {
            gameManager.playerDied();
            soundManager.playDeathSound();
            break;
        }
      }
    }
  }
  
  void processBotCollisions(ArrayList<Bot> bots) {
    for (int i = 0; i < bots.size(); i++) {
      for (int j = i + 1; j < bots.size(); j++) {
        Bot bot1 = bots.get(i);
        Bot bot2 = bots.get(j);

        if (bot1.collidesWith(bot2)) {
          if (bot1.canEat(bot2)) {
            bot1.eat(bot2);
            gameManager.respawnBot(j);
          } else if (bot2.canEat(bot1)) {
            bot2.eat(bot1);
            gameManager.respawnBot(i);
            break; // Salir del bucle interno ya que bot1 fue eliminado
          }
        }
      }
    }
  }
}

// ================================
// PLAYER CLASS
// ================================
class Player extends GameObject {
  String playerName;
  PVector velocity;
  float boostCooldown = 0;
  
  Player(float x, float y) {
    super(x, y);
    mass = 20;
    col = color(100, 200, 255);
    playerName = "Jugador";
    velocity = new PVector(0, 0);
  }
  
  void update() {
    // Actualizar cooldown de boost
    if (boostCooldown > 0) {
      boostCooldown--;
    }
    
    // Movimiento suave hacia el mouse
    PVector mousePos = new PVector(mouseX - gameManager.camera.offset.x, mouseY - gameManager.camera.offset.y);
    PVector direction = PVector.sub(mousePos, pos);
    
    // Evitar movimiento si está muy cerca del mouse
    if (direction.mag() > 5) {
      direction.normalize();
      float speed = map(mass, MIN_MASS, MAX_MASS, 5, 1.5);
      
      // Boost si se mantiene presionado el botón
      if (mousePressed && boostCooldown <= 0 && mass > 15) {
        speed *= 2;
        mass -= 0.1; // Costo del boost
        boostCooldown = 5;
        
        // Partículas de boost
        particleSystem.addBoost(pos.x, pos.y, direction);
      }
      
      velocity.lerp(direction.mult(speed), 0.1);
    } else {
      velocity.mult(0.95); // Fricción
    }
    
    pos.add(velocity);
    
    // Mantener dentro de límites
    pos.x = constrain(pos.x, getRadius(), WORLD_WIDTH - getRadius());
    pos.y = constrain(pos.y, getRadius(), WORLD_HEIGHT - getRadius());
  }
  
  @Override
  void display() {
    pushStyle();
    
    // Efecto de boost
    if (mousePressed && boostCooldown <= 0 && mass > 15) {
      // Aura de boost
      fill(col, 50);
      noStroke();
      ellipse(pos.x, pos.y, getRadius() * 2.5, getRadius() * 2.5);
    }
    
    // Sombra
    fill(0, 50);
    noStroke();
    ellipse(pos.x + 3, pos.y + 3, getRadius() * 2, getRadius() * 2);
    
    // Cuerpo principal
    fill(col);
    stroke(255, 100);
    strokeWeight(2);
    ellipse(pos.x, pos.y, getRadius() * 2, getRadius() * 2);
    
    // Brillo
    fill(255, 150);
    noStroke();
    ellipse(pos.x - getRadius()/3, pos.y - getRadius()/3, getRadius()/2, getRadius()/2);
    
    // Nombre
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(max(8, getRadius()/3));
    text(playerName, pos.x, pos.y);
    
    popStyle();
  }
}

// ================================
// BOT CLASSES
// ================================
enum BotType {
  EASY, MEDIUM, HARD
}

class Bot extends GameObject {
  BotType type;
  PVector target;
  PVector velocity;
  float aggressiveness;
  float visionRange;
  float changeDirectionTimer;
  float maxChangeTimer;
  String botName;
  
  // Anti-stuck system
  PVector lastPos;
  float stuckTimer;
  float stuckThreshold = 3.0; // pixels
  
  Bot(float x, float y, BotType t) {
    super(x, y);
    type = t;
    velocity = new PVector(0, 0);
    lastPos = new PVector(x, y);
    stuckTimer = 0;
    botName = "Bot";
    
    initializeByType();
    generateNewTarget();
  }
  
  void setName(String name) {
    botName = name;
  }
  
  void initializeByType() {
    if (type == BotType.EASY) {
      mass = random(15, 25);
      col = color(random(100, 150), random(150, 200), random(100, 150));
      aggressiveness = 0.3;
      visionRange = 100;
      maxChangeTimer = 180;
    } else if (type == BotType.MEDIUM) {
      mass = random(20, 35);
      col = color(random(150, 200), random(100, 150), random(150, 200));
      aggressiveness = 0.6;
      visionRange = 150;
      maxChangeTimer = 150;
    } else { // HARD
      mass = random(25, 45);
      col = color(random(200, 255), random(50, 100), random(50, 100));
      aggressiveness = 0.9;
      visionRange = 200;
      maxChangeTimer = 120;
    }
  }
  
  void update(Player player, ArrayList<Bot> otherBots, ArrayList<Food> foods) {
    // Anti-stuck system
    updateStuckDetection();
    
    // Actualizar timer de cambio de dirección
    changeDirectionTimer--;
    
    // Calcular movimiento
    PVector movement = calculateMovement(player, otherBots, foods);
    
    // Aplicar movimiento con suavizado
    float speed = map(mass, MIN_MASS, MAX_MASS, 4, 0.5);
    velocity.lerp(movement.mult(speed), 0.2);
    pos.add(velocity);
    
    // Mantener dentro de límites del mundo
    constrainToWorld();
    
    // Cambiar objetivo si es necesario
    if (changeDirectionTimer <= 0 || shouldChangeTarget()) {
      generateNewTarget();
    }
  }
  
  void updateStuckDetection() {
    float distanceMoved = PVector.dist(pos, lastPos);
    
    if (distanceMoved < stuckThreshold) {
      stuckTimer++;
    } else {
      stuckTimer = 0;
    }
    
    lastPos = pos.copy();
  }
  
  boolean isStuck() {
    return stuckTimer > 60; // 1 segundo a 60 FPS
  }
  
  void forceNewTarget() {
    generateNewTarget();
    stuckTimer = 0;
    
    // Añadir impulso aleatorio para salir del atasco
    PVector escapeVelocity = PVector.random2D();
    escapeVelocity.mult(5);
    velocity.add(escapeVelocity);
    
    if (DEBUG_MODE) {
      println("Bot forced new target - was stuck");
    }
  }
  
  PVector calculateMovement(Player player, ArrayList<Bot> otherBots, ArrayList<Food> foods) {
    PVector movement = new PVector(0, 0);
    
    // 1. Buscar comida cercana
    addFoodSeeking(movement, foods);
    
    // 2. Comportamiento hacia el jugador
    addPlayerInteraction(movement, player);
    
    // 3. Evitar/cazar otros bots
    addBotInteraction(movement, otherBots);
    
    // 4. Movimiento hacia objetivo aleatorio
    addRandomMovement(movement);
    
    // 5. Evitar bordes del mundo
    addBoundaryAvoidance(movement);
    
    return movement.normalize();
  }
  
  void addFoodSeeking(PVector movement, ArrayList<Food> foods) {
    Food nearestFood = findNearestFood(foods);
    if (nearestFood != null) {
      PVector foodDir = PVector.sub(nearestFood.pos, pos);
      movement.add(foodDir.setMag(0.5));
    }
  }
  
  void addPlayerInteraction(PVector movement, Player player) {
    float distToPlayer = PVector.dist(pos, player.pos);
    
    if (distToPlayer < visionRange) {
      if (canEat(player) && random(1) < aggressiveness) {
        // Perseguir al jugador
        PVector chaseDir = PVector.sub(player.pos, pos);
        movement.add(chaseDir.setMag(1.5));
      } else if (player.canEat(this)) {
        // Huir del jugador
        PVector fleeDir = PVector.sub(pos, player.pos);
        movement.add(fleeDir.setMag(2.0));
      }
    }
  }
  
  void addBotInteraction(PVector movement, ArrayList<Bot> otherBots) {
    for (Bot other : otherBots) {
      if (other == this) continue;
      
      float dist = PVector.dist(pos, other.pos);
      if (dist < visionRange) {
        if (canEat(other) && random(1) < aggressiveness) {
          // Cazar bot más pequeño
          PVector huntDir = PVector.sub(other.pos, pos);
          movement.add(huntDir.setMag(1.0));
        } else if (other.canEat(this)) {
          // Evitar bot más grande
          PVector avoidDir = PVector.sub(pos, other.pos);
          movement.add(avoidDir.setMag(1.5));
        }
      }
    }
  }
  
  void addRandomMovement(PVector movement) {
    PVector randomDir = PVector.sub(target, pos);
    movement.add(randomDir.setMag(0.3));
  }
  
  void addBoundaryAvoidance(PVector movement) {
    float boundary = 200;
    PVector avoidanceForce = new PVector();
    
    if (pos.x < boundary) avoidanceForce.x = 1;
    else if (pos.x > WORLD_WIDTH - boundary) avoidanceForce.x = -1;
    
    if (pos.y < boundary) avoidanceForce.y = 1;
    else if (pos.y > WORLD_HEIGHT - boundary) avoidanceForce.y = -1;
    
    movement.add(avoidanceForce.setMag(1.0));
  }
  
  void generateNewTarget() {
    target = new PVector(random(200, WORLD_WIDTH - 200), random(200, WORLD_HEIGHT - 200));
    changeDirectionTimer = random(60, maxChangeTimer);
  }
  
  boolean shouldChangeTarget() {
    return PVector.dist(pos, target) < 50;
  }
  
  void constrainToWorld() {
    pos.x = constrain(pos.x, getRadius(), WORLD_WIDTH - getRadius());
    pos.y = constrain(pos.y, getRadius(), WORLD_HEIGHT - getRadius());
  }
  
  Food findNearestFood(ArrayList<Food> foods) {
    Food nearest = null;
    float minDist = Float.MAX_VALUE;
    
    for (Food food : foods) {
      float dist = PVector.dist(pos, food.pos);
      if (dist < visionRange && dist < minDist) {
        nearest = food;
        minDist = dist;
      }
    }
    return nearest;
  }
  
  @Override
  void display() {
    super.display();
    
    // Mostrar nombre del bot
    if (getRadius() > 15) {
      fill(255, 200);
      textAlign(CENTER, CENTER);
      textSize(max(6, getRadius()/4));
      text(botName, pos.x, pos.y);
    }
    
    // Debug: mostrar rango de visión
    if (SHOW_VISION_RANGE) {
      pushStyle();
      noFill();
      stroke(255, 50);
      strokeWeight(1);
      ellipse(pos.x, pos.y, visionRange * 2, visionRange * 2);
      popStyle();
    }
  }
}

// ================================
// GAME OBJECT BASE CLASS
// ================================
class GameObject {
  PVector pos;
  float mass;
  color col;
  
  GameObject(float x, float y) {
    pos = new PVector(x, y);
    mass = MIN_MASS;
    col = color(255);
  }
  
  void display() {
    pushStyle();
    
    // Sombra
    fill(0, 30);
    noStroke();
    ellipse(pos.x + 2, pos.y + 2, getRadius() * 2, getRadius() * 2);
    
    // Cuerpo
    fill(col);
    stroke(255, 80);
    strokeWeight(1);
    ellipse(pos.x, pos.y, getRadius() * 2, getRadius() * 2);
    
    // Brillo
    fill(255, 100);
    noStroke();
    ellipse(pos.x - getRadius()/4, pos.y - getRadius()/4, getRadius()/3, getRadius()/3);
    
    popStyle();
  }
  
  float getRadius() {
    return sqrt(mass) * 2;
  }
  
  boolean canEat(GameObject other) {
    // Para comer, debe ser más grande por un cierto factor
    return this.mass > other.mass * EAT_RATIO;
  }
  
  boolean collidesWith(GameObject other) {
    // La colisión ocurre si la distancia es menor que el radio del objeto más grande.
    // Esto permite que el más grande "absorba" al más chico.
    float distance = PVector.dist(pos, other.pos);
    return distance < this.getRadius();
  }
  
  void eat(GameObject other) {
    mass += other.mass * MASS_GAIN_FACTOR;
    mass = constrain(mass, MIN_MASS, MAX_MASS);
  }
}

// ================================
// FOOD CLASS
// ================================
class Food extends GameObject {
  float pulseTimer;
  
  Food() {
    super(random(50, WORLD_WIDTH - 50), random(50, WORLD_HEIGHT - 50));
    mass = random(2, 5);
    col = color(random(100, 255), random(100, 255), random(100, 255));
    pulseTimer = random(TWO_PI);
  }
  
  @Override
  void display() {
    pushStyle();
    
    // Efecto de pulso
    pulseTimer += 0.05;
    float pulse = 1 + sin(pulseTimer) * 0.1;
    
    fill(col);
    stroke(255, 150);
    strokeWeight(1);
    ellipse(pos.x, pos.y, getRadius() * 2 * pulse, getRadius() * 2 * pulse);
    
    // Pequeño brillo
    fill(255, 200);
    noStroke();
    ellipse(pos.x - 1, pos.y - 1, 3, 3);
    
    popStyle();
  }
  
  @Override
  float getRadius() {
    return sqrt(mass) * 1.5;
  }
}

// ================================
// CAMERA CLASS
// ================================
class Camera {
  PVector offset;
  PVector target;
  
  Camera() {
    offset = new PVector(0, 0);
    target = new PVector(0, 0);
  }
  
  void update(Player player) {
    // Calcular posición objetivo
    target.x = width/2 - player.pos.x;
    target.y = height/2 - player.pos.y;
    
    // Suavizar movimiento
    offset.lerp(target, CAMERA_LERP_SPEED);
    
    // Limitar a bordes del mundo
    offset.x = constrain(offset.x, -(WORLD_WIDTH - width), 0);
    offset.y = constrain(offset.y, -(WORLD_HEIGHT - height), 0);
  }
}

// ================================
// RENDERER CLASS
// ================================
class Renderer {
  Grid grid;
  
  Renderer() {
    grid = new Grid();
  }
  
  void render(GameManager game) {
    background(25, 25, 35);
    
    pushMatrix();
    translate(game.camera.offset.x, game.camera.offset.y);
    
    // Renderizar mundo
    grid.display();
    
    // Renderizar entidades
    renderFood(game.foods);
    renderBots(game.bots);
    game.player.display();
    
    // Renderizar partículas en el espacio del mundo
    particleSystem.display();
    
    popMatrix();
  }
  
  void renderFood(ArrayList<Food> foods) {
      for (Food f : foods) {
          f.display();
      }
  }

  void renderBots(ArrayList<Bot> bots) {
      for (Bot b : bots) {
          b.display();
      }
  }
  
  void renderDebugInfo(GameManager game) {
      fill(255);
      textSize(12);
      textAlign(LEFT, TOP);
      text("FPS: " + int(frameRate), 10, 10);
      text("Player Pos: " + int(game.player.pos.x) + ", " + int(game.player.pos.y), 10, 25);
      text("Player Mass: " + int(game.player.mass), 10, 40);
      text("Bots: " + game.bots.size(), 10, 55);
      text("Food: " + game.foods.size(), 10, 70);
      text("Particles: " + particleSystem.particles.size(), 10, 85);
  }
}

// ================================
// GRID CLASS (COMPLETADA)
// ================================
class Grid {
    void display() {
        stroke(100, 100, 120, 80);
        strokeWeight(1);
        for (int x = 0; x <= WORLD_WIDTH; x += GRID_SIZE) {
            line(x, 0, x, WORLD_HEIGHT);
        }
        for (int y = 0; y <= WORLD_HEIGHT; y += GRID_SIZE) {
            line(0, y, WORLD_WIDTH, y);
        }
    }
}

// ================================
// UI CLASS (COMPLETADA)
// ================================
class UI {
    void display(Player player, ArrayList<Bot> bots) {
        displayLeaderboard(player, bots);
        displayPlayerMass(player);
    }

    void displayLeaderboard(Player player, ArrayList<Bot> bots) {
        ArrayList<GameObject> allCells = new ArrayList<GameObject>();
        allCells.add(player);
        allCells.addAll(bots);

        // Ordenar por masa (descendente)
        allCells.sort((a, b) -> Float.compare(b.mass, a.mass));

        pushStyle();
        fill(0, 80);
        noStroke();
        rectMode(CORNER);
        rect(width - 210, 10, 200, 200);

        fill(255);
        textSize(16);
        textAlign(CENTER, TOP);
        text("Leaderboard", width - 110, 20);

        textAlign(LEFT, TOP);
        textSize(12);
        for (int i = 0; i < min(allCells.size(), 10); i++) {
            GameObject cell = allCells.get(i);
            String name = "Desconocido";
            if (cell instanceof Player) {
                name = ((Player) cell).playerName;
                fill(150, 220, 255); // Color especial para el jugador
            } else if (cell instanceof Bot) {
                name = ((Bot) cell).botName;
                fill(255);
            }
            
            text("#" + (i + 1) + " " + name + " (" + int(cell.mass) + ")", width - 200, 50 + i * 15);
        }
        popStyle();
    }

    void displayPlayerMass(Player player) {
        pushStyle();
        fill(255);
        textSize(20);
        textAlign(CENTER, CENTER);
        text("Masa: " + int(player.mass), width / 2, height - 30);
        popStyle();
    }

    int calculatePlayerRank(Player player, ArrayList<Bot> bots) {
        int rank = 1;
        for (Bot bot : bots) {
            if (bot.mass > player.mass) {
                rank++;
            }
        }
        return rank;
    }
}

// ================================
// SOUND MANAGER (COMPLETADO)
// ================================
class SoundManager {
    // Nota: Para que el sonido real funcione, necesitarías la librería de sonido
    // de Processing y archivos de audio (ej: "eat.wav") en la carpeta "data" del sketch.
    // Esta es una implementación simulada para que el código no dé errores.
    
    SoundManager() {
        println("SoundManager inicializado (simulado).");
    }

    void playEatSound() {
        // Aquí iría el código para reproducir sonido al comer.
    }

    void playDeathSound() {
        // Aquí iría el código para reproducir sonido al morir.
    }
}

// ================================
// PARTICLE SYSTEM (COMPLETADO)
// ================================
class Particle {
    PVector pos, vel, acc;
    float lifespan;
    color col;
    float size;

    Particle(float x, float y, color c) {
        pos = new PVector(x, y);
        vel = PVector.random2D();
        vel.mult(random(1, 5));
        acc = new PVector(0, 0);
        lifespan = 255;
        col = c;
        size = random(2, 6);
    }
    
    void update() {
        vel.add(acc);
        pos.add(vel);
        vel.mult(0.96); // Fricción
        lifespan -= 5.0;
    }

    void display() {
        pushStyle();
        noStroke();
        fill(red(col), green(col), blue(col), lifespan);
        ellipse(pos.x, pos.y, size, size);
        popStyle();
    }

    boolean isDead() {
        return lifespan < 0;
    }
}

class ParticleSystem {
    ArrayList<Particle> particles;

    ParticleSystem() {
        particles = new ArrayList<Particle>();
    }

    void addExplosion(float x, float y, color c) {
        int numParticles = int(constrain(sqrt(gameManager.player.mass), 10, 70));
        for (int i = 0; i < numParticles; i++) {
            particles.add(new Particle(x, y, c));
        }
    }

    void addFoodEaten(float x, float y, color c) {
        for (int i = 0; i < 5; i++) {
            particles.add(new Particle(x, y, c));
        }
    }

    void addBoost(float x, float y, PVector dir) {
        Particle p = new Particle(x, y, color(255, 255, 100, 150));
        p.vel = dir.copy().mult(-2); // Partícula hacia atrás
        particles.add(p);
    }

    void update() {
        for (int i = particles.size() - 1; i >= 0; i--) {
            Particle p = particles.get(i);
            p.update();
            if (p.isDead()) {
                particles.remove(i);
            }
        }
    }

    void display() {
        for (Particle p : particles) {
            p.display();
        }
    }
}
