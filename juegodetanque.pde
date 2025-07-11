// Variables globales
Tanque jugador;
ArrayList<Bala> balas;
ArrayList<Tanque> enemigos;
int maxEnemigos = 5; // Número máximo de enemigos en pantalla
boolean juegoTerminado = false;
boolean modoReparacion = false;

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
int maxTiempoReparacion = 300; // 5 seconds at 60fps
boolean reparacionExitosa = false;

void setup() {
  size(800, 600); // Tamaño de la ventana
  frameRate(60);  // Para una animación fluida
  inicializarJuego();
}

void inicializarJuego() {
  jugador = new Tanque(width / 2, height / 2, true, TipoEnemigo.NORMAL);
  balas = new ArrayList<Bala>();
  enemigos = new ArrayList<Tanque>(); 
  juegoTerminado = false;
  modoReparacion = false;
  reparacionExitosa = false;
  
  // Iniciar el sistema de oleadas
  oleadaActual = 0;
  iniciarSiguienteOleada();
  
  // Reiniciar el loop si estaba pausado
  loop();
}

// Lógica para controlar el inicio y la composición de las oleadas
void iniciarSiguienteOleada() {
  oleadaActual++;
  iniciandoOleada = true;
  temporizadorInicioOleada = 180; // 3 segundos de pausa antes de que empiece la oleada
  
  // Limpiar enemigos y balas de la oleada anterior
  enemigos.clear();
  balas.clear();
  
  // La creación de enemigos se hará en el draw() cuando el temporizador llegue a 0
}

// Lógica para crear los enemigos de la oleada actual
void crearEnemigosDeOleada() {
  switch (oleadaActual) {
    case 1:
      // Solo enemigos normales
      crearEnemigo(3, TipoEnemigo.NORMAL);
      break;
      
    case 2:
      // Introducir Kamikazes
      crearEnemigo(2, TipoEnemigo.NORMAL);
      crearEnemigo(2, TipoEnemigo.KAMIKAZE);
      break;
      
    case 3:
      // Introducir Invocadores
      crearEnemigo(2, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      break;
      
        
case 4:
  // Introducir Disablers
  crearEnemigo(1, TipoEnemigo.NORMAL); // <--- FIXED
  crearEnemigo(2, TipoEnemigo.KAMIKAZE);
  crearEnemigo(1, TipoEnemigo.INVOCADOR);
  crearEnemigo(1, TipoEnemigo.DISABLER);
  break;
      
    case 5:
      // Introducir Artillería
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.ARTILLERIA);
      break;
      
    case 6:
      // Introducir Apoyo
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.ARTILLERIA);
      crearEnemigo(1, TipoEnemigo.APOYO);
      break;
      
    case 7:
      // Combinación intensa
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(2, TipoEnemigo.KAMIKAZE);
      crearEnemigo(2, TipoEnemigo.INVOCADOR);
      crearEnemigo(1, TipoEnemigo.DISABLER);
      crearEnemigo(1, TipoEnemigo.APOYO);
      break;
      
    case 8:
      // Oleada de artillería
      crearEnemigo(1, TipoEnemigo.NORMAL);
      crearEnemigo(1, TipoEnemigo.KAMIKAZE);
      crearEnemigo(1, TipoEnemigo.INVOCADOR);
      crearEnemigo(2, TipoEnemigo.ARTILLERIA);
      crearEnemigo(2, TipoEnemigo.APOYO);
      break;
    default: // Para oleadas posteriores, aumentar la dificultad
      crearEnemigo(oleadaActual - 2, TipoEnemigo.NORMAL);
      crearEnemigo(oleadaActual / 2, TipoEnemigo.KAMIKAZE);
      crearEnemigo(oleadaActual / 3, TipoEnemigo.INVOCADOR);
      break;
  }
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

// Esta función se usa para los Invocadores
void crearEnemigoInvocado(PVector pos) {
  // Asegurarse de que no aparezcan encima del jugador
  while (dist(pos.x, pos.y, jugador.posicion.x, jugador.posicion.y) < 100) {
    pos.x = random(width);
    pos.y = random(height);
  }
  enemigos.add(new Tanque(pos.x, pos.y, false, TipoEnemigo.NORMAL));
}

void crearEnemigoAleatorio() {
  float x = random(width);
  float y = random(height);
  // Asegurarse de que no aparezcan encima del jugador
  while (dist(x, y, jugador.posicion.x, jugador.posicion.y) < 150) {
    x = random(width);
    y = random(height);
  }
  enemigos.add(new Tanque(x, y, false));
}

void draw() {
  background(200, 230, 255); // Cielo azul claro
  
  // Dibujar una cuadrícula sutil en el fondo
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
    
    // Mostrar mensaje de nueva oleada
    fill(255, 255, 0);
    textSize(40);
    textAlign(CENTER, CENTER);
    text("OLEADA " + oleadaActual, width / 2, height / 2);
    text("Prepárate...", width / 2, height / 2 + 50);
    return;
  }

  if (modoReparacion) {
    // Mini-juego de reparación
    mostrarMiniJuegoReparacion();
  } else if (!juegoTerminado) {
    // Juego normal
    // Actualizar y mostrar jugador
    jugador.actualizar();
    jugador.mostrar();

    // --- Lógica de los Enemigos ---
    for (int i = enemigos.size() - 1; i >= 0; i--) {
      Tanque enemigo = enemigos.get(i);
      enemigo.actualizar(jugador.posicion); // La IA apunta al jugador
      enemigo.mostrar();

      // Comprobar si el enemigo ha sido destruido
      if (enemigo.estaDestruido()) {
        enemigos.remove(i);
      }
    }

    // Verificar si se completó la oleada
    if (enemigos.size() == 0 && !iniciandoOleada) {
      iniciarSiguienteOleada();
    }

    // --- Lógica de las Balas ---
    for (int i = balas.size() - 1; i >= 0; i--) {
      Bala b = balas.get(i);
      b.actualizar();
      b.mostrar();
      
      // Comprobar colisiones
      b.comprobarColision(jugador);
      for (Tanque enemigo : enemigos) {
        b.comprobarColision(enemigo);
      }

      // Eliminar la bala si está fuera de la pantalla o si ha colisionado
      if (b.estaFuera() || b.haColisionado) {
        balas.remove(i);
      }
    }
    
    // Mostrar información del juego
    mostrarUI();
    
    // --- Lógica de "muerte" del jugador ---
    if (jugador.estaDestruido() && !modoReparacion) {
      iniciarMiniJuegoReparacion();
    }
  } else {
    // Mostrar pantalla de Game Over
    mostrarGameOver();
  }
}

// --- Eventos de Teclado y Mouse ---
void mousePressed() {
  if (modoReparacion) {
    // Lógica del mini-juego
    manejarClickReparacion();
  } else if (juegoTerminado) {
    return; // No hacer nada si el juego terminó
  } else {
    jugador.disparar();
  }
}

void keyPressed() {
  if (juegoTerminado) {
    // Si el juego terminó, solo permitir reinicio
    if (key == ' ') { // Barra espaciadora
      inicializarJuego();
    }
  } else if (modoReparacion) {
    // En modo reparación, usar números para seleccionar colores
    if (key >= '1' && key <= '6') {
      int colorIndex = key - '1';
      patronJugador.add(colorIndex);
      verificarPatron();
    }
  } else {
    // Controles normales del juego
    if (key == ' ') { // Barra espaciadora para reiniciar en cualquier momento
      inicializarJuego();
    } else {
      jugador.controlarMovimiento(true);
    }
  }
}

void keyReleased() {
  if (!juegoTerminado && !modoReparacion) {
    jugador.controlarMovimiento(false);
  }
}

// --- Funciones de UI ---
void mostrarUI() {
  // Mostrar número de enemigos restantes
  fill(0);
  textSize(20);
  textAlign(LEFT, TOP);
  text("Enemigos: " + enemigos.size(), 10, 10);
  
  // Mostrar vida del jugador
  text("Vida: " + int(jugador.vida), 10, 35);
  
  // Mostrar cantidad de muertes
  text("Cantidad de muertes: " + int(jugador.muertes), 10, 60);
  
  // Mostrar oleada actual
  text("Oleada: " + oleadaActual, 10, 85);
  
  // Mostrar mensaje de reparación exitosa
  if (reparacionExitosa && frameCount % 60 < 30) { // Parpadea por 2 segundos
    fill(0, 255, 0);
    textSize(30);
    textAlign(CENTER, TOP);
    text("¡REPARACIÓN EXITOSA!", width / 2, 60);
    
    // Resetear el flag después de 2 segundos
    if (frameCount % 120 == 0) {
      reparacionExitosa = false;
    }
  }
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
  text("Presiona ESPACIO para reiniciar", width / 2, height / 2 + 40);
}

// === FUNCIONES DEL MINI-JUEGO DE REPARACIÓN ===

void iniciarMiniJuegoReparacion() {
  modoReparacion = true;
  tiempoReparacion = maxTiempoReparacion;
  reparacionExitosa = false;
  
  // Generar patrón aleatorio de 4-6 colores
  patronObjetivo = new ArrayList<Integer>();
  patronJugador = new ArrayList<Integer>();
  
  int longitudPatron = int(random(4, 7)); // Entre 4 y 6 colores
  for (int i = 0; i < longitudPatron; i++) {
    patronObjetivo.add(int(random(coloresReparacion.length)));
  }
  
  // Pausar las balas y enemigos
  for (Bala bala : balas) {
    bala.velocidad.mult(0); // Detener balas
  }
}

void mostrarMiniJuegoReparacion() {
  // Fondo semi-transparente
  fill(0, 200);
  rect(0, 0, width, height);
  
  // Título
  fill(255, 255, 100);
  textSize(40);
  textAlign(CENTER, CENTER);
  text("¡REPARACIÓN DE EMERGENCIA!", width / 2, 80);
  
  // Instrucciones
  fill(255);
  textSize(20);
  text("Reproduce el patrón de colores", width / 2, 120);
  text("Usa las teclas 1-6 o haz click", width / 2, 145);
  
  // Mostrar patrón objetivo
  fill(255);
  textSize(16);
  text("PATRÓN A REPRODUCIR:", width / 2, 180);
  
  float startX = width / 2 - (patronObjetivo.size() * 60) / 2;
  for (int i = 0; i < patronObjetivo.size(); i++) {
    fill(coloresReparacion[patronObjetivo.get(i)]);
    stroke(255);
    strokeWeight(3);
    rect(startX + i * 60, 200, 50, 50, 10);
    
    // Número del color
    fill(0);
    textAlign(CENTER, CENTER);
    text(str(patronObjetivo.get(i) + 1), startX + i * 60 + 25, 225);
  }
  
  // Mostrar patrón del jugador
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
  
  // Mostrar opciones de colores
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
  
  // Barra de tiempo
  fill(255, 0, 0);
  rect(100, 480, 600, 20, 10);
  fill(0, 255, 0);
  float tiempoRestante = map(tiempoReparacion, 0, maxTiempoReparacion, 0, 600);
  rect(100, 480, tiempoRestante, 20, 10);
  
  fill(255);
  textAlign(CENTER, CENTER);
  text("TIEMPO: " + int(tiempoReparacion / 60.0) + "s", width / 2, 520);
  
  // Actualizar tiempo
  tiempoReparacion--;
  if (tiempoReparacion <= 0) {
    // Se acabó el tiempo - Game Over
    modoReparacion = false;
    juegoTerminado = true;
  }
}

void manejarClickReparacion() {
  // Detectar click en colores disponibles
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
  // Verificar si el patrón está completo
  if (patronJugador.size() == patronObjetivo.size()) {
    boolean correcto = true;
    for (int i = 0; i < patronObjetivo.size(); i++) {
      if (!patronObjetivo.get(i).equals(patronJugador.get(i))) {
        correcto = false;
        break;
      }
    }
    
    if (correcto) {
      // ¡Reparación exitosa!
      reparacionExitosa = true;
      jugador.muertes++; // Incrementar el contador de muertes.
      jugador.vida = jugador.vidaMaxima; // Restaurar vida completa
      modoReparacion = false;
      
      // Reactivar balas
      for (Bala bala : balas) {
        bala.velocidad = PVector.fromAngle(random(TWO_PI)).mult(8);
      }
      
      // Mostrar mensaje de éxito
      // (El mensaje se mostrará en el siguiente frame)
    } else {
      // Patrón incorrecto - Game Over
      modoReparacion = false;
      juegoTerminado = true;
    }
  }
}
