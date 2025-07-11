// Enum para tipos de enemigos - DEBE estar FUERA de la clase
enum TipoEnemigo {
  NORMAL, KAMIKAZE, INVOCADOR, DISABLER, ARTILLERIA, APOYO
}

class Tanque {
  PVector posicion;
  PVector velocidad;
  float angulo;
  color colorCuerpo;
  color colorCanon;
  int tamano = 50;
  float vidaMaxima = 100;
  float vida;
  boolean esJugador;
  int muertes = 0; // NUEVO: Contador de reparaciones.
  
  TipoEnemigo tipoEnemigo;
  
  // Variables para movimiento del jugador
  boolean moviendoArriba, moviendoAbajo, moviendoIzquierda, moviendoDerecha;

  // Variables para IA Enemiga
  PVector direccionAleatoria;
  int temporizadorDisparo;
  
  // NUEVO: Variables específicas para enemigos especializados
  int temporizadorInvocacion;
  int temporizadorKamikaze;
  boolean enModoKamikaze;
  float distanciaActivacionKamikaze = 150;
  int temporizadorCuracion;
  boolean sirenaSonando;
  int intensidadSirena;
  
  // Variables para Artillería
  boolean enPosicion;
  PVector posicionObjetivo;
  int temporizadorReposicionamiento;
  
  // Variables para Apoyo
  Tanque objetivoCuracion;
  float rangoApoyo = 200;

  // Constructor con 3 parámetros (para compatibilidad)
  Tanque(float x, float y, boolean esJugador) {
    this(x, y, esJugador, TipoEnemigo.NORMAL);
  }

  // Constructor principal con 4 parámetros
  Tanque(float x, float y, boolean esJugador, TipoEnemigo tipo) {
    this.posicion = new PVector(x, y);
    this.velocidad = new PVector(0, 0);
    this.esJugador = esJugador;
    this.vida = this.vidaMaxima;
    this.muertes = 0;
    this.tipoEnemigo = tipo;

    if (esJugador) {
      this.colorCuerpo = color(40, 120, 255); // Azul
      this.colorCanon = color(80, 80, 80);
    } else {
      this.direccionAleatoria = new PVector(0, 0);
      this.temporizadorDisparo = int(random(120));
      this.temporizadorInvocacion = int(random(300, 600));
      this.temporizadorKamikaze = 0;
      this.enModoKamikaze = false;
      this.temporizadorCuracion = int(random(180, 360));
      this.sirenaSonando = false;
      this.intensidadSirena = 0;
      this.enPosicion = false;
      this.temporizadorReposicionamiento = int(random(120, 240));
      
      // Configurar colores y propiedades según el tipo
      configurarTipoEnemigo();
    }
  }
  
  void configurarTipoEnemigo() {
    switch (tipoEnemigo) {
      case NORMAL:
        this.colorCuerpo = color(255, 80, 80);
        this.colorCanon = color(80, 80, 80);
        break;
        
      case KAMIKAZE:
        this.colorCuerpo = color(255, 150, 0); // Naranja
        this.colorCanon = color(80, 80, 80);
        this.vidaMaxima = 60;
        this.vida = this.vidaMaxima;
        this.tamano = 40; // Más pequeño
        break;
        
      case INVOCADOR:
        this.colorCuerpo = color(150, 0, 255); // Púrpura
        this.colorCanon = color(80, 80, 80);
        this.vidaMaxima = 150;
        this.vida = this.vidaMaxima;
        this.tamano = 60; // Más grande
        break;
        
      case DISABLER:
        this.colorCuerpo = color(0, 150, 255); // Azul claro
        this.colorCanon = color(80, 80, 80);
        this.vidaMaxima = 80;
        this.vida = this.vidaMaxima;
        break;
        
      case ARTILLERIA:
        this.colorCuerpo = color(100, 100, 100); // Gris
        this.colorCanon = color(40, 40, 40);
        this.vidaMaxima = 120;
        this.vida = this.vidaMaxima;
        this.tamano = 55;
        break;
        
      case APOYO:
        this.colorCuerpo = color(0, 255, 150); // Verde claro
        this.colorCanon = color(80, 80, 80);
        this.vidaMaxima = 70;
        this.vida = this.vidaMaxima;
        this.tamano = 45;
        break;
    }
  }

  void actualizar() { // Para el Jugador
    if (!esJugador) return;
    // --- MODIFICADO: Penalización de velocidad ---
    // La velocidad base es 3. Se reduce en 0.2 por cada muerte, con un mínimo de 1.
    float velocidadActual = max(1, 3.0 - (this.muertes * 0.2));
    
    // Actualizar velocidad basada en teclas presionadas
    velocidad.set(0, 0);
    if (moviendoArriba) velocidad.y = -velocidadActual;
    if (moviendoAbajo) velocidad.y = velocidadActual;
    if (moviendoIzquierda) velocidad.x = -velocidadActual;
    if (moviendoDerecha) velocidad.x = velocidadActual;

    posicion.add(velocidad);
    limitarAPantalla();
    
    // Apuntar hacia el mouse
    this.angulo = atan2(mouseY - posicion.y, mouseX - posicion.x);
  }

  void actualizar(PVector objetivo) { // Para los NPCs
    if (esJugador) return;

    // Comportamiento específico según el tipo de enemigo
    switch (tipoEnemigo) {
      case NORMAL:
        comportamientoNormal(objetivo);
        break;
      case KAMIKAZE:
        comportamientoKamikaze(objetivo);
        break;
      case INVOCADOR:
        comportamientoInvocador(objetivo);
        break;
      case DISABLER:
        comportamientoDisabler(objetivo);
        break;
      case ARTILLERIA:
        comportamientoArtilleria(objetivo);
        break;
      case APOYO:
        comportamientoApoyo(objetivo);
        break;
    }
    
    limitarAPantalla();
  }
  
  void comportamientoNormal(PVector objetivo) {
    // Apuntar al objetivo
    this.angulo = atan2(objetivo.y - posicion.y, objetivo.x - posicion.x);
    
    // Movimiento semi-aleatorio
    if (frameCount % 90 == 0) {
      direccionAleatoria = PVector.random2D().mult(random(1, 2.5));
    }
    posicion.add(direccionAleatoria);
    
    // Disparar periódicamente
    temporizadorDisparo++;
    if (temporizadorDisparo > 90) {
      disparar();
      temporizadorDisparo = 0;
    }
  }
  
  void comportamientoKamikaze(PVector objetivo) {
    float distancia = dist(posicion.x, posicion.y, objetivo.x, objetivo.y);
    
    if (distancia < distanciaActivacionKamikaze && !enModoKamikaze) {
      enModoKamikaze = true;
      sirenaSonando = true;
    }
    
    if (enModoKamikaze) {
      // Movimiento directo hacia el jugador
      PVector direccion = PVector.sub(objetivo, posicion);
      direccion.normalize();
      direccion.mult(4); // Velocidad alta
      posicion.add(direccion);
      
      // Efectos visuales de alarma
      intensidadSirena = (intensidadSirena + 5) % 255;
      
      // Explotar si está muy cerca
      if (distancia < 30) {
        explotar();
      }
    } else {
      // Comportamiento normal hasta activarse
      comportamientoNormal(objetivo);
    }
  }
  
  void comportamientoInvocador(PVector objetivo) {
    // Apuntar al objetivo pero mantenerse a distancia
    this.angulo = atan2(objetivo.y - posicion.y, objetivo.x - posicion.x);
    
    float distancia = dist(posicion.x, posicion.y, objetivo.x, objetivo.y);
    
    // Si está muy cerca, alejarse
    if (distancia < 150) {
      PVector escapar = PVector.sub(posicion, objetivo);
      escapar.normalize();
      escapar.mult(1.5);
      posicion.add(escapar);
    } else {
      // Movimiento aleatorio suave
      if (frameCount % 120 == 0) {
        direccionAleatoria = PVector.random2D().mult(random(0.5, 1.5));
      }
      posicion.add(direccionAleatoria);
    }
    
    // Invocar nuevos enemigos
    temporizadorInvocacion++;
    if (temporizadorInvocacion > 300) { // Cada 5 segundos
      invocarEnemigo();
      temporizadorInvocacion = 0;
    }
  }
  
  void comportamientoDisabler(PVector objetivo) {
    // Apuntar al objetivo
    this.angulo = atan2(objetivo.y - posicion.y, objetivo.x - posicion.x);
    
    // Movimiento errático para ser difícil de seguir
    if (frameCount % 60 == 0) {
      direccionAleatoria = PVector.random2D().mult(random(2, 4));
    }
    posicion.add(direccionAleatoria);
    
    // Disparar balas ralentizantes más frecuentemente
    temporizadorDisparo++;
    if (temporizadorDisparo > 60) { // Más rápido que los normales
      disparar();
      temporizadorDisparo = 0;
    }
  }
  
  void comportamientoArtilleria(PVector objetivo) {
    // Intentar posicionarse en el borde de la pantalla
    if (!enPosicion) {
      buscarPosicionArtilleria();
    }
    
    // Apuntar al objetivo
    this.angulo = atan2(objetivo.y - posicion.y, objetivo.x - posicion.x);
    
    // Disparar proyectiles lentos pero potentes
    temporizadorDisparo++;
    if (temporizadorDisparo > 150) { // Dispara menos frecuentemente
      disparar();
      temporizadorDisparo = 0;
    }
    
    // Reposicionarse ocasionalmente
    temporizadorReposicionamiento++;
    if (temporizadorReposicionamiento > 600) { // Cada 10 segundos
      enPosicion = false;
      temporizadorReposicionamiento = 0;
    }
  }
  
  void comportamientoApoyo(PVector objetivo) {
    // Buscar aliados para curar
    objetivoCuracion = buscarAliadoParaCurar();
    
    if (objetivoCuracion != null) {
      // Acercarse al aliado que necesita curación
      PVector direccion = PVector.sub(objetivoCuracion.posicion, posicion);
      float distancia = direccion.mag();
      
      if (distancia > 80) { // Acercarse si está lejos
        direccion.normalize();
        direccion.mult(2);
        posicion.add(direccion);
      }
      
      // Curar al aliado
      temporizadorCuracion++;
      if (temporizadorCuracion > 120) { // Cada 2 segundos
        curarAliado(objetivoCuracion);
        temporizadorCuracion = 0;
      }
    } else {
      // Comportamiento normal si no hay aliados que curar
      comportamientoNormal(objetivo);
    }
  }
  
  void buscarPosicionArtilleria() {
    // Intentar ir a los bordes de la pantalla
    float margen = 50;
    
    if (posicion.x < margen || posicion.x > width - margen || 
        posicion.y < margen || posicion.y > height - margen) {
      enPosicion = true;
    } else {
      // Moverse hacia el borde más cercano
      PVector direccion = new PVector(0, 0);
      if (posicion.x < width / 2) {
        direccion.x = -1;
      } else {
        direccion.x = 1;
      }
      if (posicion.y < height / 2) {
        direccion.y = -1;
      } else {
        direccion.y = 1;
      }
      direccion.normalize();
      direccion.mult(2);
      posicion.add(direccion);
    }
  }
  
  Tanque buscarAliadoParaCurar() {
    Tanque mejorCandidato = null;
    float menorVida = Float.MAX_VALUE;
    
    for (Tanque enemigo : enemigos) {
      if (enemigo != this && !enemigo.esJugador) {
        float distancia = dist(posicion.x, posicion.y, enemigo.posicion.x, enemigo.posicion.y);
        if (distancia < rangoApoyo && enemigo.vida < enemigo.vidaMaxima) {
          float porcentajeVida = enemigo.vida / enemigo.vidaMaxima;
          if (porcentajeVida < menorVida) {
            menorVida = porcentajeVida;
            mejorCandidato = enemigo;
          }
        }
      }
    }
    
    return mejorCandidato;
  }
  
  void curarAliado(Tanque aliado) {
    if (aliado != null) {
      aliado.vida = min(aliado.vidaMaxima, aliado.vida + 15);
      // Crear efecto visual de curación
      crearEfectoCuracion(aliado.posicion.x, aliado.posicion.y);
    }
  }
  
  void invocarEnemigo() {
    // Crear un nuevo enemigo normal cerca del invocador
    PVector posicionInvocacion = PVector.add(posicion, PVector.random2D().mult(80));
    crearEnemigoInvocado(posicionInvocacion);
  }
  
  void explotar() {
    // Crear efecto de explosión
    crearEfectoExplosion(posicion.x, posicion.y);
    
    // Hacer daño al jugador si está cerca
    float distancia = dist(posicion.x, posicion.y, jugador.posicion.x, jugador.posicion.y);
    if (distancia < 80) {
      jugador.recibirDano(40);
    }
    
    // Eliminar este tanque
    this.vida = 0;
  }

  // --- Métodos de Visualización ---
  void mostrar() {
    pushMatrix();
    translate(posicion.x, posicion.y);

    // Efectos especiales según el tipo
    mostrarEfectosEspeciales();

    // Sombra caricaturesca
    noStroke();
    fill(0, 30);
    ellipse(3, 3, tamano, tamano);

    // Cuerpo del tanque
    stroke(50, 50, 50);
    strokeWeight(4);
    fill(colorCuerpo);
    ellipse(0, 0, tamano, tamano);
    
    // Efectos adicionales según el tipo
    mostrarDetallesTipo();
    
    // Reflejo en el cuerpo
    fill(255, 255, 255, 100);
    noStroke();
    ellipse(0, 0, tamano * 0.5, tamano * 0.5);

    // Cañón
    rotate(angulo);
    stroke(50, 50, 50);
    strokeWeight(4);
    fill(colorCanon);
    
    // Cañón diferente para artillería
    if (tipoEnemigo == TipoEnemigo.ARTILLERIA) {
      rect(0, -10, tamano * 0.9, 20, 5); // Cañón más largo y grueso
    } else {
      rect(0, -7, tamano * 0.75, 14, 5);
    }

    popMatrix();

    // Barra de vida
    mostrarBarraDeVida();
  }
  
  void mostrarEfectosEspeciales() {
    // Efecto de sirena para Kamikaze
    if (tipoEnemigo == TipoEnemigo.KAMIKAZE && sirenaSonando) {
      fill(255, 0, 0, intensidadSirena);
      noStroke();
      ellipse(0, 0, tamano + 20, tamano + 20);
    }
    
    // Aura de invocación
    if (tipoEnemigo == TipoEnemigo.INVOCADOR) {
      fill(150, 0, 255, 30);
      noStroke();
      ellipse(0, 0, tamano + 30, tamano + 30);
    }
    
    // Aura de curación para Apoyo
    if (tipoEnemigo == TipoEnemigo.APOYO) {
      fill(0, 255, 150, 20);
      noStroke();
      ellipse(0, 0, rangoApoyo, rangoApoyo);
    }
  }
  
  void mostrarDetallesTipo() {
    // Marcas especiales según el tipo
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(12);
    
    switch (tipoEnemigo) {
      case KAMIKAZE:
        text("!", 0, 0);
        break;
      case INVOCADOR:
        text("S", 0, 0);
        break;
      case DISABLER:
        text("D", 0, 0);
        break;
      case ARTILLERIA:
        text("A", 0, 0);
        break;
      case APOYO:
        text("+", 0, 0);
        break;
    }
  }

  void mostrarBarraDeVida() {
    // Fondo rojo de la barra
    fill(200, 0, 0, 200);
    rect(posicion.x - tamano / 2, posicion.y - tamano / 2 - 20, tamano, 10, 3);
    // Vida verde actual
    fill(0, 200, 0, 200);
    float anchoVida = map(vida, 0, vidaMaxima, 0, tamano);
    rect(posicion.x - tamano / 2, posicion.y - tamano / 2 - 20, anchoVida, 10, 3);
  }

  // --- Métodos de Interacción ---
  void disparar() {
    // La bala se crea en la punta del cañón
    float offsetX = cos(angulo) * (tamano * 0.75);
    float offsetY = sin(angulo) * (tamano * 0.75);
    PVector origenBala = new PVector(posicion.x + offsetX, posicion.y + offsetY);
    PVector direccionBala = PVector.fromAngle(angulo);
    
    // Crear bala especial según el tipo
    if (tipoEnemigo == TipoEnemigo.DISABLER) {
      balas.add(new Bala(origenBala, direccionBala, this, true)); // Bala ralentizante
    } else {
      balas.add(new Bala(origenBala, direccionBala, this));
    }
  }

  void recibirDano(float cantidad) {
    this.vida -= cantidad;
    this.vida = constrain(vida, 0, vidaMaxima);
  }

  void controlarMovimiento(boolean presionado) {
    if (key == 'w' || key == 'W') moviendoArriba = presionado;
    if (key == 's' || key == 'S') moviendoAbajo = presionado;
    if (key == 'a' || key == 'A') moviendoIzquierda = presionado;
    if (key == 'd' || key == 'D') moviendoDerecha = presionado;
  }
  
  void limitarAPantalla() {
    posicion.x = constrain(posicion.x, tamano / 2, width - tamano / 2);
    posicion.y = constrain(posicion.y, tamano / 2, height - tamano / 2);
  }

  boolean estaDestruido() {
    return vida <= 0;
  }
}

// Funciones auxiliares para efectos visuales
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
