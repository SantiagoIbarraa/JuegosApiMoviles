// ===== ARCHIVO PRINCIPAL: juegodetanque.pde =====
import processing.sound.*;

// Enums movidos a `tipos.pde` para evitar problemas de visibilidad entre tabs

// === VARIABLES GLOBALES ===
EstadoJuego estadoActual = EstadoJuego.MENU_PRINCIPAL;

// Variables del juego
Tanque jugador;
ArrayList<Bala> balas;
ArrayList<Tanque> enemigos;
ArrayList<Elemento> elementos;
int maxEnemigos = 5;
boolean juegoTerminado = false;
boolean modoReparacion = false;

// Variables de audio
SoundFile sonidoDisparo;
SoundFile sonidoImpacto;
SoundFile sonidoExplosion;
float volumenMaster = 0.3;
boolean audioMuteado = false;
boolean teclaVolumenPresionada = false;

// Variables del sistema de oleadas
int oleadaActual = 0;
boolean iniciandoOleada = false;
int temporizadorInicioOleada = 0;

// Variables del mini-juego de reparación
ArrayList<Integer> patronObjetivo;
ArrayList<Integer> patronJugador;
int[] coloresReparacion = {
  color(255, 100, 100), // Rojo
  color(100, 255, 100), // Verde
  color(100, 100, 255), // Azul
  color(255, 255, 100), // Amarillo
  color(255, 100, 255), // Magenta
  color(100, 255, 255)  // Cian
};
int tiempoReparacion;
int maxTiempoReparacion = 300;
boolean reparacionExitosa = false;

// Variables para elementos
int mensajePerkTiempo = 0;
String mensajePerkTexto = "";
color mensajePerkColor;

// Variable para fuente personalizada
PFont fuenteJuego;

// === FUNCIONES PRINCIPALES ===
void setup() {
  size(800, 600);
  frameRate(60);
  
  // Cargar fuente que soporte caracteres especiales
  try {
    // Intentar cargar una fuente del sistema que soporte caracteres especiales
    fuenteJuego = createFont("Arial", 16, true);
    textFont(fuenteJuego);
    println("Fuente Arial cargada correctamente");
  } catch (Exception e) {
    try {
      // Fallback a fuente del sistema
      fuenteJuego = createFont("SansSerif", 16, true);
      textFont(fuenteJuego);
      println("Fuente SansSerif cargada como fallback");
    } catch (Exception e2) {
      // Usar fuente por defecto si todo falla
      println("Usando fuente por defecto del sistema");
    }
  }
  
  // Cargar sonidos desde la carpeta data
  try {
    sonidoDisparo = new SoundFile(this, "disparo.wav");
    sonidoImpacto = new SoundFile(this, "impacto.wav");
    sonidoExplosion = new SoundFile(this, "explosion.wav");
    
    // Aplicar volumen inicial
    aplicarVolumenActual();
    
    println("Sonidos cargados correctamente");
  } catch (Exception e) {
    println("Error cargando sonidos: " + e.getMessage());
    println("Verifica que la carpeta 'data' existe y contiene los archivos:");
    println("- disparo.wav");
    println("- impacto.wav"); 
    println("- explosion.wav");
  }
  
  inicializarJuego();
}

void draw() {
  switch (estadoActual) {
    case MENU_PRINCIPAL:
      mostrarMenuPrincipal();
      break;
      
    case OPCIONES:
      estadoActual = EstadoJuego.MENU_PRINCIPAL;
      break;
      
    case JUGANDO:
      background(200, 230, 255);
      
      // Dibujar cuadrícula
      stroke(180, 210, 235);
      strokeWeight(2);
      for (int i = 0; i < width; i += 40) {
        line(i, 0, i, height);
      }
      for (int i = 0; i < height; i += 40) {
        line(0, i, width, i);
      }

      // Lógica de oleadas
      if (iniciandoOleada) {
        temporizadorInicioOleada--;
        if (temporizadorInicioOleada <= 0) {
          iniciandoOleada = false;
          crearEnemigosDeOleada();
        }
        
        fill(255, 255, 0);
        textSize(40);
        textAlign(CENTER, CENTER);
        text("OLEADA " + oleadaActual, width / 2, height / 2);
        text("Prepárate...", width / 2, height / 2 + 50);
        return;
      }

      if (modoReparacion) {
        mostrarMiniJuegoReparacion();
      } else if (!juegoTerminado) {
        jugador.actualizar();
        jugador.mostrar();

        for (int i = enemigos.size() - 1; i >= 0; i--) {
          Tanque enemigo = enemigos.get(i);
          enemigo.actualizar(jugador.posicion);
          enemigo.mostrar();
          if (enemigo.estaDestruido()) {
            enemigos.remove(i);
          }
        }

        if (enemigos.size() == 0 && !iniciandoOleada) {
          iniciarSiguienteOleada();
        }

        for (int i = balas.size() - 1; i >= 0; i--) {
          Bala b = balas.get(i);
          b.actualizar();
          b.mostrar();
          b.comprobarColision(jugador);
          for (Tanque enemigo : enemigos) {
            b.comprobarColision(enemigo);
          }
          if (b.estaFuera() || b.haColisionado) {
            balas.remove(i);
          }
        }
        
        actualizarElementos();
        mostrarElementos();
        mostrarPerksActivos();
        mostrarUI();
        
        // NUEVO: Validación periódica de ángulos cada 300 frames (5 segundos)
        if (frameCount % 300 == 0) {
          validarAngulosOleada();
        }
        
        // NUEVO: Validación más frecuente para rondas altas donde ocurre el bug
        if (oleadaActual >= 3 && frameCount % 60 == 0) { // Cada segundo en rondas altas
          validarAngulosOleada();
        }
        
        if (jugador.estaDestruido() && !modoReparacion) {
          iniciarMiniJuegoReparacion();
        }
      } else {
        estadoActual = EstadoJuego.GAME_OVER;
      }
      break;
      
    case GAME_OVER:
      mostrarGameOver();
      break;
  }
}

// === FUNCIONES DE MENÚ ===
void mostrarMenuPrincipal() {
  background(200, 230, 255);
  stroke(180, 210, 235);
  strokeWeight(2);
  for (int i = 0; i < width; i += 40) {
    line(i, 0, i, height);
  }
  for (int i = 0; i < height; i += 40) {
    line(0, i, width, i);
  }
  
  // Título del juego
  fill(50, 50, 150);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("TANK WARS", width / 2, height / 3);
  
  // Opciones del menú
  fill(255);
  stroke(50, 50, 150);
  strokeWeight(3);
  
  // Botón JUGAR
  rect(width / 2 - 100, height / 2, 200, 60, 10);
  fill(50, 50, 150);
  textSize(30);
  text("JUGAR", width / 2, height / 2 + 30);
  
  // Botón OPCIONES
  fill(255);
  rect(width / 2 - 100, height / 2 + 80, 200, 60, 10);
  fill(50, 50, 150);
  text("OPCIONES", width / 2, height / 2 + 110);
  
  // Instrucciones
  fill(100);
  textSize(16);
  text("Click en los botones o usa las teclas:", width / 2, height - 100);
  text("J = Jugar, O = Opciones", width / 2, height - 80);
}

void mostrarGameOver() {
  fill(0, 150);
  rect(0, 0, width, height);
  
  fill(255, 50, 50);
  textSize(80);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width / 2, height / 2 - 40);
  
  fill(255);
  textSize(30);
  text("Presiona R para reiniciar", width / 2, height / 2 + 40);
}

// === FUNCIONES DE INICIALIZACIÓN ===
void inicializarJuego() {
  jugador = new Tanque(width / 2, height / 2, true, TipoEnemigo.NORMAL);
  balas = new ArrayList<Bala>();
  enemigos = new ArrayList<Tanque>(); 
  elementos = new ArrayList<Elemento>();
  juegoTerminado = false;
  modoReparacion = false;
  reparacionExitosa = false;
  
  // Reiniciar variables de perks
  mensajePerkTiempo = 0;
  mensajePerkTexto = "";
  
  oleadaActual = 0;
  iniciarSiguienteOleada();
  
  loop();
}

// === FUNCIONES DE OLEADAS ===
void iniciarSiguienteOleada() {
  oleadaActual++;
  iniciandoOleada = true;
  temporizadorInicioOleada = 180;
  
  enemigos.clear();
  balas.clear();
}

void crearEnemigosDeOleada() {
  crearElementosOleada();

  switch (oleadaActual) {
    case 1:
      crearEnemigo(3, TipoEnemigo.NORMAL);
      break;
    case 2:
      crearEnemigo(2, TipoEnemigo.NORMAL);
      crearEnemigo(2, TipoEnemigo.KAMIKAZE);
      break;
    case 3:
      crearEnemigo(2, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      break;
    case 4:
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(2, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      break;
    case 5:
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.ARTILLERIA);
      break;
    case 6:
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.ARTILLERIA);
      crearEnemigo(1, TipoEnemigo.APOYO);
      break;
    case 7:
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(2, TipoEnemigo.KAMIKAZE);
      crearEnemigo(2, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.APOYO);
      break;
    case 8:
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(2, TipoEnemigo.ARTILLERIA);
      crearEnemigo(2, TipoEnemigo.APOYO);
      break;
    default:
      crearEnemigo(oleadaActual - 2, TipoEnemigo.NORMAL);
      crearEnemigo(oleadaActual / 2, TipoEnemigo.KAMIKAZE);
      crearEnemigo(oleadaActual / 3, TipoEnemigo.INVOCADOR);
      break;
  }
  
  // NUEVO: Validar ángulos de todos los tanques después de crear la oleada
  validarAngulosOleada();
}

// NUEVA: Función para validar ángulos de todos los tanques
void validarAngulosOleada() {
  // Validar ángulo del jugador
  if (jugador != null) {
    jugador.validarAngulo();
  }
  
  // Validar ángulos de todos los enemigos
  for (Tanque enemigo : enemigos) {
    if (enemigo != null) {
      enemigo.validarAngulo();
      
      // NUEVO: Validación especial para enemigos problemáticos en rondas altas
      if (oleadaActual >= 3) {
        // Verificar específicamente enemigos que pueden causar problemas
        if (enemigo.tipoEnemigo == TipoEnemigo.INVOCADOR || 
            enemigo.tipoEnemigo == TipoEnemigo.DISABLER || 
            enemigo.tipoEnemigo == TipoEnemigo.ARTILLERIA || 
            enemigo.tipoEnemigo == TipoEnemigo.APOYO) {
          
          // Validación extra para estos tipos
          if (Float.isNaN(enemigo.angulo) || Float.isInfinite(enemigo.angulo) || 
              enemigo.angulo > 1000 || enemigo.angulo < -1000) {
            println("DEBUG: Problema detectado en enemigo " + enemigo.tipoEnemigo + 
                    " en oleada " + oleadaActual + " - Ángulo: " + enemigo.angulo);
            enemigo.angulo = 0; // Resetear inmediatamente
          }
        }
      }
    }
  }
  
  println("DEBUG: Oleada " + oleadaActual + " - Ángulos validados para " + enemigos.size() + " enemigos");
}

void crearEnemigo(int cantidad, TipoEnemigo tipo) {
  for (int i = 0; i < cantidad; i++) {
    float x = random(width);
    float y = random(height);
    while (dist(x, y, jugador.posicion.x, jugador.posicion.y) < 200) {
      x = random(width);
      y = random(height);
    }
    enemigos.add(new Tanque(x, y, false, tipo));
  }
}

void crearEnemigoInvocado(PVector pos) {
  while (dist(pos.x, pos.y, jugador.posicion.x, jugador.posicion.y) < 100) {
    pos.x = random(width);
    pos.y = random(height);
  }
  enemigos.add(new Tanque(pos.x, pos.y, false, TipoEnemigo.NORMAL));
}

// === FUNCIONES DE ELEMENTOS ===
void crearElementosOleada() {
  elementos.clear();
  
  float probKboom = 0.3;
  float probOneshot = 0.4;
  float probVida = 0.15;
  float probPerk = 0.5;
  
  if (random(1) < probKboom) {
    crearElementoEnPosicionSegura(TipoElemento.KBOOM);
  }
  if (random(1) < probOneshot) {
    crearElementoEnPosicionSegura(TipoElemento.ONESHOT);
  }
  if (random(1) < probVida) {
    crearElementoEnPosicionSegura(TipoElemento.VIDA);
  }
  if (random(1) < probPerk) {
    crearElementoEnPosicionSegura(TipoElemento.PERK_BEBIDA);
  }
}

void crearElementoEnPosicionSegura(TipoElemento tipo) {
  float x = random(100, width - 100);
  float y = random(100, height - 100);
  
  while (dist(x, y, jugador.posicion.x, jugador.posicion.y) < 150) {
    x = random(100, width - 100);
    y = random(100, height - 100);
  }
  
  elementos.add(new Elemento(x, y, tipo));
}

void actualizarElementos() {
  for (int i = elementos.size() - 1; i >= 0; i--) {
    Elemento elemento = elementos.get(i);
    elemento.actualizar();
    
    if (elemento.puedeSerRecogido(jugador)) {
      elemento.serRecogido(jugador);
      elementos.remove(i);
    }
  }
}

void mostrarElementos() {
  for (Elemento elemento : elementos) {
    elemento.mostrar();
  }
  
  if (mensajePerkTiempo > 0) {
    fill(mensajePerkColor);
    textAlign(CENTER, CENTER);
    textSize(40);
    text(mensajePerkTexto, width / 2, height / 2 - 100);
    mensajePerkTiempo--;
  }
}

void mostrarMensajePerk(String texto, color colorTexto) {
  mensajePerkTexto = texto;
  mensajePerkColor = colorTexto;
  mensajePerkTiempo = 180;
}

void mostrarPerksActivos() {
  if (jugador.perkActivo != TipoPerk.NINGUNO) {
    fill(0, 150);
    rect(width - 220, 10, 200, 60, 10);
    
    fill(150, 50, 255);
    stroke(255);
    strokeWeight(2);
    rect(width - 210, 20, 40, 40, 5);
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(16);
    String perkTexto = "";
    
    switch (jugador.perkActivo) {
      case DOUBLETAP:
        perkTexto = "DOUBLE TAP\nDaño x2";
        fill(255, 100, 100);
        textAlign(CENTER, CENTER);
        textSize(12);
        text("2X", width - 190, 40);
        break;
      case SPEEDCOLA:
        perkTexto = "SPEED COLA\nVelocidad +";
        fill(100, 255, 100);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(">>", width - 190, 40);
        break;
    }
    
    fill(255);
    textAlign(LEFT, CENTER);
    textSize(14);
    text(perkTexto, width - 160, 40);
  }
  
  if (jugador.tieneOneshot && jugador.tiempoOneshot > 0) {
    fill(255, 255, 0, 200);
    rect(width - 220, 80, 200, 30, 5);
    
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("ONE SHOT: " + int(jugador.tiempoOneshot / 60) + "s", width - 120, 95);
  }
}

// === FUNCIONES DE CONTROLES ===
void mousePressed() {
  switch (estadoActual) {
    case MENU_PRINCIPAL:
      if (mouseX > width / 2 - 100 && mouseX < width / 2 + 100 &&
          mouseY > height / 2 && mouseY < height / 2 + 60) {
        estadoActual = EstadoJuego.JUGANDO;
        inicializarJuego();
      }
      if (mouseX > width / 2 - 100 && mouseX < width / 2 + 100 &&
          mouseY > height / 2 + 80 && mouseY < height / 2 + 140) {
        println("El menú de opciones no está implementado aún.");
      }
      break;
      
    case JUGANDO:
      if (modoReparacion) {
        manejarClickReparacion();
      } else if (!juegoTerminado) {
        jugador.disparar(); 
      }
      break;
      
    case GAME_OVER:
      break;
  }
}

void keyPressed() {
  switch (estadoActual) {
    case MENU_PRINCIPAL:
      if (key == 'j' || key == 'J') {
        estadoActual = EstadoJuego.JUGANDO;
        inicializarJuego();
      }
      if (key == 'o' || key == 'O') {
        println("El menú de opciones no está implementado aún.");
      }
      break;
      
    case JUGANDO:
      if (juegoTerminado) {
        if (key == 'r' || key == 'R') {
          inicializarJuego();
        }
      } else if (modoReparacion) {
        if (key >= '1' && key <= '6') {
          int colorIndex = key - '1';
          patronJugador.add(colorIndex);
          verificarPatron();
        }
      } else {
        if (key == ' ') {
          jugador.disparar();
        } else if (key == 'r' || key == 'R') {
          inicializarJuego();
        } else {
          jugador.controlarMovimiento(true);
        }
        
        if (key == 'm' || key == 'M') {
          toggleMute();
        }
        if (key == '+' || key == '=') {
          cambiarVolumen(0.1);
        }
        if (key == '-' || key == '_') {
          cambiarVolumen(-0.1);
        }
        if (key == '0') {
          volumenMaster = 0.5;
          aplicarVolumenActual();
          println("Volumen reseteado a 50%");
        }
      }
      break;
      
    case GAME_OVER:
      if (key == 'r' || key == 'R') {
        estadoActual = EstadoJuego.MENU_PRINCIPAL;
      }
      break;
  }
}

void keyReleased() {
  if (estadoActual == EstadoJuego.JUGANDO && !juegoTerminado && !modoReparacion) {
    jugador.controlarMovimiento(false);
  }
}

// === FUNCIONES DE UI ===
void mostrarUI() {
  fill(0);
  textSize(20);
  textAlign(LEFT, TOP);
  text("Enemigos: " + enemigos.size(), 10, 10);
  text("Vida: " + int(jugador.vida), 10, 35);
  text("Cantidad de muertes: " + int(jugador.muertes), 10, 60);
  text("Oleada: " + oleadaActual, 10, 85);
  
  // Mostrar controles
  textAlign(RIGHT, TOP);
  text("Controles:", width - 10, 10);
  text("WASD = Mover", width - 10, 35);
  text("ESPACIO = Disparar", width - 10, 60);
  text("R = Reiniciar", width - 10, 85);
  
  if (reparacionExitosa && frameCount % 60 < 30) {
    fill(0, 255, 0);
    textSize(30);
    textAlign(CENTER, TOP);
    text("¡REPARACIÓN EXITOSA!", width / 2, 60);
    
    if (frameCount % 120 == 0) {
      reparacionExitosa = false;
    }
  }
}

// === FUNCIONES DE REPARACIÓN ===
void iniciarMiniJuegoReparacion() {
  modoReparacion = true;
  tiempoReparacion = maxTiempoReparacion;
  reparacionExitosa = false;
  
  patronObjetivo = new ArrayList<Integer>();
  patronJugador = new ArrayList<Integer>();
  
  int longitudPatron = int(random(4, 7));
  for (int i = 0; i < longitudPatron; i++) {
    patronObjetivo.add(int(random(coloresReparacion.length)));
  }
  
  for (Bala bala : balas) {
    bala.velocidad.mult(0);
  }
}

void mostrarMiniJuegoReparacion() {
  fill(0, 200);
  rect(0, 0, width, height);
  
  fill(255, 255, 100);
  textSize(40);
  textAlign(CENTER, CENTER);
  text("¡REPARACIÓN DE EMERGENCIA!", width / 2, 80);
  
  fill(255);
  textSize(20);
  text("Reproduce el patrón de colores", width / 2, 120);
  text("Usa las teclas 1-6 o haz click", width / 2, 145);
  
  fill(255);
  textSize(16);
  text("PATRÓN A REPRODUCIR:", width / 2, 180);
  
  float startX = width / 2 - (patronObjetivo.size() * 60) / 2;
  for (int i = 0; i < patronObjetivo.size(); i++) {
    fill(coloresReparacion[patronObjetivo.get(i)]);
    stroke(255);
    strokeWeight(3);
    rect(startX + i * 60, 200, 50, 50, 10);
    
    fill(0);
    textAlign(CENTER, CENTER);
    text(str(patronObjetivo.get(i) + 1), startX + i * 60 + 25, 225);
  }
  
  fill(255);
  textSize(16);
  textAlign(CENTER, CENTER);
  text("TU PATRÓN:", width / 2, 280);
  
  startX = width / 2 - (patronObjetivo.size() * 60) / 2;
  for (int i = 0; i < patronObjetivo.size(); i++) {
    if (i < patronJugador.size()) {
      fill(coloresReparacion[patronJugador.get(i)]);
      stroke(255);
    } else {
      fill(100);
      stroke(150);
    }
    strokeWeight(3);
    rect(startX + i * 60, 300, 50, 50, 10);
    
    if (i < patronJugador.size()) {
      fill(0);
      textAlign(CENTER, CENTER);
      text(str(patronJugador.get(i) + 1), startX + i * 60 + 25, 325);
    }
  }
  
  fill(255);
  textSize(16);
  text("COLORES DISPONIBLES:", width / 2, 380);
  
  startX = width / 2 - (coloresReparacion.length * 60) / 2;
  for (int i = 0; i < coloresReparacion.length; i++) {
    fill(coloresReparacion[i]);
    stroke(255);
    strokeWeight(3);
    rect(startX + i * 60, 400, 50, 50, 10);
    
    fill(0);
    textAlign(CENTER, CENTER);
    text(str(i + 1), startX + i * 60 + 25, 425);
  }
  
  fill(255, 0, 0);
  rect(100, 480, 600, 20, 10);
  fill(0, 255, 0);
  float tiempoRestante = map(tiempoReparacion, 0, maxTiempoReparacion, 0, 600);
  rect(100, 480, tiempoRestante, 20, 10);
  
  fill(255);
  textAlign(CENTER, CENTER);
  text("TIEMPO: " + int(tiempoReparacion / 60.0) + "s", width / 2, 520);
  
  tiempoReparacion--;
  if (tiempoReparacion <= 0) {
    modoReparacion = false;
    juegoTerminado = true;
  }
}

void manejarClickReparacion() {
  float startX = width / 2 - (coloresReparacion.length * 60) / 2;
  for (int i = 0; i < coloresReparacion.length; i++) {
    float colorX = startX + i * 60;
    if (mouseX >= colorX && mouseX <= colorX + 50 && 
        mouseY >= 400 && mouseY <= 450) {
      patronJugador.add(i);
      verificarPatron();
      break;
    }
  }
}

void verificarPatron() {
  if (patronJugador.size() == patronObjetivo.size()) {
    boolean correcto = true;
    for (int i = 0; i < patronObjetivo.size(); i++) {
      if (!patronObjetivo.get(i).equals(patronJugador.get(i))) {
        correcto = false;
        break;
      }
    }
    
    if (correcto) {
      reparacionExitosa = true;
      jugador.muertes++;
      jugador.vida = jugador.vidaMaxima;
      modoReparacion = false;
      
      for (Bala bala : balas) {
        bala.velocidad = PVector.fromAngle(random(TWO_PI)).mult(8);
      }
    } else {
      modoReparacion = false;
      juegoTerminado = true;
    }
  }
}

// === FUNCIONES DE AUDIO ===
void aplicarVolumenActual() {
  if (audioMuteado) {
    if (sonidoDisparo != null) sonidoDisparo.amp(0.0);
    if (sonidoImpacto != null) sonidoImpacto.amp(0.0);
    if (sonidoExplosion != null) sonidoExplosion.amp(0.0);
  } else {
    if (sonidoDisparo != null) sonidoDisparo.amp(volumenMaster * 0.3);
    if (sonidoImpacto != null) sonidoImpacto.amp(volumenMaster * 0.6);
    if (sonidoExplosion != null) sonidoExplosion.amp(volumenMaster * 0.5);
  }
}

void cambiarVolumen(float cambio) {
  volumenMaster += cambio;
  volumenMaster = constrain(volumenMaster, 0.0, 1.0);
  if (volumenMaster > 0) {
    audioMuteado = false;
  }
  aplicarVolumenActual();
  println("Volumen: " + int(volumenMaster * 100) + "%");
}

void toggleMute() {
  audioMuteado = !audioMuteado;
  aplicarVolumenActual();
  
  if (audioMuteado) {
    println("Audio MUTEADO");
  } else {
    println("Audio ACTIVADO - Volumen: " + int(volumenMaster * 100) + "%");
  }
}

// === FUNCIONES AUXILIARES ===
void crearEfectoCuracion(float x, float y) {
  // Crear efecto visual de curación (cruz verde)
  for (int i = 0; i < 8; i++) {
    float angulo = map(i, 0, 8, 0, TWO_PI);
    // Aquí podrías crear partículas verdes
  }
}

void crearEfectoExplosion(float x, float y) {
  // Crear efecto visual de explosión
  for (int i = 0; i < 15; i++) {
    float angulo = random(TWO_PI);
    float velocidad = random(3, 8);
    // Aquí podrías crear partículas de explosión
  }
}

void crearEfectoImpacto(float x, float y) {
  // Crear efecto visual de impacto
  for (int i = 0; i < 6; i++) {
    float angulo = random(TWO_PI);
    float velocidad = random(2, 5);
    // Aquí podrías crear partículas de impacto
  }
}
