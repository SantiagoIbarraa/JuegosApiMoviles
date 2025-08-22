// ===== NUEVO ARCHIVO: elementos.pde =====

class Elemento {
  PVector posicion;
  TipoElemento tipo;
  color colorElemento;
  boolean activo = true;
  float animacion = 0;
  
  Elemento(float x, float y, TipoElemento tipo) {
    this.posicion = new PVector(x, y);
    this.tipo = tipo;
    configurarElemento();
  }
  
  void configurarElemento() {
    switch (tipo) {
      case KBOOM:
        colorElemento = color(255, 50, 50); // Rojo intenso
        break;
      case ONESHOT:
        colorElemento = color(255, 255, 50); // Amarillo dorado
        break;
      case VIDA:
        colorElemento = color(50, 255, 50); // Verde vida
        break;
      case PERK_BEBIDA:
        colorElemento = color(150, 50, 255); // Púrpura mágico
        break;
    }
  }
  
  void actualizar() {
    animacion += 0.1;
  }
  
  void mostrar() {
    if (!activo) return;
    
    pushMatrix();
    translate(posicion.x, posicion.y);
    
    // Efecto de flotación
    float flotacion = sin(animacion) * 3;
    translate(0, flotacion);
    
    // Aura brillante
    fill(red(colorElemento), green(colorElemento), blue(colorElemento), 50);
    noStroke();
    ellipse(0, 0, 80 + sin(animacion * 2) * 10, 80 + sin(animacion * 2) * 10);
    
    // Cuerpo del elemento
    fill(colorElemento);
    stroke(255);
    strokeWeight(3);
    
    switch (tipo) {
      case KBOOM:
        // Bomba
        ellipse(0, 0, 40, 40);
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(20);
        text("💣", 0, 0);
        break;
        
      case ONESHOT:
        // Bala dorada
        ellipse(0, 0, 35, 35);
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(16);
        text("1", 0, 0);
        break;
        
      case VIDA:
        // Cruz médica
        rectMode(CENTER);
        rect(0, 0, 35, 35, 5);
        fill(255);
        rect(0, 0, 25, 8);
        rect(0, 0, 8, 25);
        break;
        
      case PERK_BEBIDA:
        // Botella de perk
        rectMode(CENTER);
        rect(0, -5, 20, 30, 3);
        ellipse(0, -18, 15, 10);
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(12);
        text("?", 0, -5);
        break;
    }
    
    popMatrix();
    
    // Texto descriptivo
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    
    switch (tipo) {
      case KBOOM:
        text("KBOOM", posicion.x, posicion.y + 35);
        break;
      case ONESHOT:
        text("ONE SHOT", posicion.x, posicion.y + 35);
        break;
      case VIDA:
        text("VIDA", posicion.x, posicion.y + 35);
        break;
      case PERK_BEBIDA:
        text("PERK", posicion.x, posicion.y + 35);
        break;
    }
  }
  
  boolean puedeSerRecogido(Tanque jugador) {
    if (!activo) return false;
    float distancia = dist(posicion.x, posicion.y, jugador.posicion.x, jugador.posicion.y);
    return distancia < 40; // Radio de recogida
  }
  
  void serRecogido(Tanque jugador) {
    switch (tipo) {
      case KBOOM:
        activarKboom();
        break;
      case ONESHOT:
        activarOneshot(jugador);
        break;
      case VIDA:
        activarVida(jugador);
        break;
      case PERK_BEBIDA:
        activarPerkAleatorio(jugador);
        break;
    }
    activo = false;
  }
  
  void activarKboom() {
    // Matar a todos los enemigos
    for (Tanque enemigo : enemigos) {
      enemigo.vida = 0;
    }
    
    // Efecto visual masivo
    for (int i = 0; i < 30; i++) {
      float x = random(width);
      float y = random(height);
      crearEfectoExplosion(x, y);
    }
    
    // Sonido de explosión
    if (sonidoExplosion != null && !audioMuteado) {
      sonidoExplosion.amp(volumenMaster * 0.8);
      sonidoExplosion.play();
    }
  }
  
  void activarOneshot(Tanque jugador) {
    jugador.tieneOneshot = true;
    jugador.tiempoOneshot = 600; // 10 segundos
  }
  
  void activarVida(Tanque jugador) {
    jugador.vida = jugador.vidaMaxima;
    
    // Efecto visual de curación
    crearEfectoCuracion(jugador.posicion.x, jugador.posicion.y);
  }
  
  void activarPerkAleatorio(Tanque jugador) {
    // Elegir un perk aleatorio
    TipoPerk[] perksDisponibles = {TipoPerk.DOUBLETAP, TipoPerk.SPEEDCOLA};
    TipoPerk perkElegido = perksDisponibles[int(random(perksDisponibles.length))];
    
    jugador.perkActivo = perkElegido;
    
    // Mensaje de perk obtenido
    switch (perkElegido) {
      case DOUBLETAP:
        mostrarMensajePerk("DOUBLE TAP!", color(255, 100, 100));
        break;
      case SPEEDCOLA:
        mostrarMensajePerk("SPEED COLA!", color(100, 255, 100));
        break;
    }
  }
}
