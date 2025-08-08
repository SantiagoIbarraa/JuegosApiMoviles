// ===== ARCHIVO TANQUE.PDE CORREGIDO =====

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
  int muertes = 0;
  
  TipoEnemigo tipoEnemigo;
  
  // Variables para movimiento del jugador
  boolean moviendoArriba, moviendoAbajo, moviendoIzquierda, moviendoDerecha;

  // Variables para IA Enemiga
  PVector direccionAleatoria;
  int temporizadorDisparo;
  
  // Variables específicas para enemigos especializados
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

  // Variables para perks y elementos activos
  TipoPerk perkActivo = TipoPerk.NINGUNO;
  boolean tieneOneshot = false;
  int tiempoOneshot = 0;

  // Variables para monitoreo de ángulos (DEBUG)
  float anguloAnterior = 0;
  int contadorCambiosAngulo = 0;
  int frameUltimoCambio = 0;

  // Constructor con 3 parámetros (para compatibilidad)
  Tanque(float x, float y, boolean esJugador) {
    this(x, y, esJugador, TipoEnemigo.NORMAL);
  }

  // Constructor principal con 4 parámetros
  Tanque(float x, float y, boolean esJugador, TipoEnemigo tipo) {
    this.posicion = new PVector(x, y);
    this.velocidad = new PVector(0, 0);
    this.angulo = 0; // Inicializar ángulo en 0
    this.anguloAnterior = 0; // Inicializar para monitoreo
    this.esJugador = esJugador;
    this.vida = this.vidaMaxima;
    this.muertes = 0;
    this.tipoEnemigo = tipo;
    
    // Inicializar variables de perks
    this.perkActivo = TipoPerk.NINGUNO;
    this.tieneOneshot = false;
    this.tiempoOneshot = 0;

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
      
      // NUEVO: Validación inicial del ángulo para enemigos
      validarAngulo();
      println("DEBUG: Enemigo " + tipo + " creado en posición (" + x + ", " + y + ") con ángulo: " + angulo);
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

  void actualizar() { // Para el Jugador - CORREGIDO
    if (!esJugador) return;
    
    // Actualizar temporizadores de elementos activos
    if (tieneOneshot && tiempoOneshot > 0) {
      tiempoOneshot--;
      if (tiempoOneshot <= 0) {
        tieneOneshot = false;
      }
    }
    
    // CORREGIDO: Velocidad con bonus de Speed Cola
    float velocidadBase = 3.0;
    
    // Aplicar bonus de Speed Cola
    if (perkActivo == TipoPerk.SPEEDCOLA) {
      velocidadBase = 4.5; // 50% más velocidad
    }
    
    // La velocidad se reduce por muertes pero se mejora con Speed Cola
    float velocidadActual = max(1, velocidadBase - (this.muertes * 0.2));
    
    // Actualizar velocidad basada en teclas presionadas
    velocidad.set(0, 0);
    if (moviendoArriba) velocidad.y = -velocidadActual;
    if (moviendoAbajo) velocidad.y = velocidadActual;
    if (moviendoIzquierda) velocidad.x = -velocidadActual;
    if (moviendoDerecha) velocidad.x = velocidadActual;

    posicion.add(velocidad);
    limitarAPantalla();
    
    // SOLUCIONADO: Apuntar hacia el centro del mapa con validación mejorada
    actualizarAnguloJugador();
  }
  
  // NUEVA: Función específica para actualizar ángulo del jugador
  void actualizarAnguloJugador() {
    PVector centro = new PVector(width / 2.0, height / 2.0);
    float distanciaAlCentro = dist(posicion.x, posicion.y, centro.x, centro.y);
    
    // Si está muy cerca del centro, mantener el ángulo actual
    if (distanciaAlCentro < 5) {
      validarAngulo(); // Solo validar, no cambiar
      return;
    }
    
    // Calcular nuevo ángulo de manera más segura
    try {
      float deltaX = centro.x - posicion.x;
      float deltaY = centro.y - posicion.y;
      
      // Verificar que los deltas no sean cero o muy pequeños
      if (abs(deltaX) < 0.001 && abs(deltaY) < 0.001) {
        validarAngulo(); // Solo validar, no cambiar
        return;
      }
      
      // Usar atan2 con valores más estables
      float nuevoAngulo = atan2(deltaY, deltaX);
      
      // Validación estricta del nuevo ángulo
      if (!Float.isNaN(nuevoAngulo) && !Float.isInfinite(nuevoAngulo) && 
          nuevoAngulo >= -PI && nuevoAngulo <= PI) {
        // Solo actualizar si el cambio es significativo (evita micro-cambios)
        float diferenciaAngulo = abs(nuevoAngulo - angulo);
        if (diferenciaAngulo > 0.01 || diferenciaAngulo > PI) {
          angulo = nuevoAngulo;
        }
      } else {
        println("DEBUG: Ángulo calculado inválido para jugador: " + nuevoAngulo + " (deltaX: " + deltaX + ", deltaY: " + deltaY + ")");
        validarAngulo(); // Corregir el ángulo actual
      }
    } catch (Exception e) {
      println("DEBUG: Error calculando ángulo del jugador: " + e.getMessage());
      validarAngulo(); // Corregir el ángulo actual
    }
  }

  void actualizar(PVector objetivo) { // Para los NPCs - CORREGIDO
    if (esJugador) return;

    // CORREGIDO: Verificación de null pointer
    if (objetivo == null) return;

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
    // SOLUCIONADO: Apuntar al objetivo con validación mejorada
    actualizarAnguloEnemigo(objetivo);
    
    // CORREGIDO: Inicializar direccionAleatoria si es null
    if (direccionAleatoria == null) {
      direccionAleatoria = PVector.random2D().mult(random(1, 2.5));
    }
    
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
  
  // NUEVA: Función específica para actualizar ángulo de enemigos
  void actualizarAnguloEnemigo(PVector objetivo) {
    float distancia = dist(posicion.x, posicion.y, objetivo.x, objetivo.y);
    
    // Solo calcular ángulo si hay distancia suficiente
    if (distancia < 5) {
      validarAngulo(); // Solo validar, no cambiar
      return;
    }
    
    // Calcular nuevo ángulo de manera más segura
    try {
      float deltaX = objetivo.x - posicion.x;
      float deltaY = objetivo.y - posicion.y;
      
      // Verificar que los deltas no sean cero o muy pequeños
      if (abs(deltaX) < 0.001 && abs(deltaY) < 0.001) {
        validarAngulo(); // Solo validar, no cambiar
        return;
      }
      
      // Usar atan2 con valores más estables
      float nuevoAngulo = atan2(deltaY, deltaX);
      
      // Validación estricta del nuevo ángulo
      if (!Float.isNaN(nuevoAngulo) && !Float.isInfinite(nuevoAngulo) && 
          nuevoAngulo >= -PI && nuevoAngulo <= PI) {
        // Solo actualizar si el cambio es significativo (evita micro-cambios)
        float diferenciaAngulo = abs(nuevoAngulo - this.angulo);
        if (diferenciaAngulo > 0.01 || diferenciaAngulo > PI) {
          this.angulo = nuevoAngulo;
        }
      } else {
        println("DEBUG: Ángulo calculado inválido para enemigo " + tipoEnemigo + ": " + nuevoAngulo + " (deltaX: " + deltaX + ", deltaY: " + deltaY + ")");
        validarAngulo(); // Corregir el ángulo actual
      }
    } catch (Exception e) {
      println("DEBUG: Error calculando ángulo de enemigo " + tipoEnemigo + ": " + e.getMessage());
      validarAngulo(); // Corregir el ángulo actual
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
    // SOLUCIONADO: Apuntar al objetivo con validación mejorada
    actualizarAnguloEnemigo(objetivo);
    
    float distancia = dist(posicion.x, posicion.y, objetivo.x, objetivo.y);
    
    // CORREGIDO: Inicializar direccionAleatoria si es null
    if (direccionAleatoria == null) {
      direccionAleatoria = PVector.random2D().mult(random(0.5, 1.5));
    }
    
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
    // SOLUCIONADO: Apuntar al objetivo con validación mejorada
    actualizarAnguloEnemigo(objetivo);
    
    // CORREGIDO: Inicializar direccionAleatoria si es null
    if (direccionAleatoria == null) {
      direccionAleatoria = PVector.random2D().mult(random(2, 4));
    }
    
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
    
    // SOLUCIONADO: Apuntar al objetivo con validación mejorada
    actualizarAnguloEnemigo(objetivo);
    
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
    // CORREGIDO: Verificar que la lista enemigos no sea null
    if (enemigos == null) return null;
    
    Tanque mejorCandidato = null;
    float menorVida = Float.MAX_VALUE;
    
    for (Tanque enemigo : enemigos) {
      if (enemigo != null && enemigo != this && !enemigo.esJugador) {
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
    if (aliado != null && aliado.vida > 0) { // CORREGIDO: Verificar que esté vivo
      aliado.vida = min(aliado.vidaMaxima, aliado.vida + 15);
      // Crear efecto visual de curación
      crearEfectoCuracion(aliado.posicion.x, aliado.posicion.y);
    }
  }
  
  void invocarEnemigo() {
    // CORREGIDO: Verificar límites antes de crear enemigo
    if (enemigos != null && enemigos.size() < 15) { // Límite de enemigos
      PVector posicionInvocacion = PVector.add(posicion, PVector.random2D().mult(80));
      
      // CORREGIDO: Asegurar que la posición esté dentro de los límites
      posicionInvocacion.x = constrain(posicionInvocacion.x, 50, width - 50);
      posicionInvocacion.y = constrain(posicionInvocacion.y, 50, height - 50);
      
      crearEnemigoInvocado(posicionInvocacion);
    }
  }
  
  void explotar() {
    // CORREGIDO: Verificar que el sonido existe antes de reproducir
    if (sonidoExplosion != null && !audioMuteado) {
      sonidoExplosion.amp(volumenMaster * 0.2);
      sonidoExplosion.play();
    }
    
    // Crear efecto de explosión
    crearEfectoExplosion(posicion.x, posicion.y);

    // CORREGIDO: Verificar que el jugador existe antes de hacer daño
    if (jugador != null) {
      float distancia = dist(posicion.x, posicion.y, jugador.posicion.x, jugador.posicion.y);
      if (distancia < 80) {
        jugador.recibirDano(40);
      }
    }
    
    // Eliminar este tanque
    this.vida = 0;
  }

  // --- Métodos de Visualización ---
  void mostrar() {
    // SOLUCIONADO: Validar ángulo antes de mostrar
    validarAngulo();
    
    // NUEVO: Monitorear cambios de ángulo para detectar problemas
    monitorearCambioAngulo();
    
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
  
  // NUEVO: Función para validar y corregir ángulos
  void validarAngulo() {
    // Verificar si el ángulo es válido
    if (Float.isNaN(angulo) || Float.isInfinite(angulo)) {
      println("DEBUG: Ángulo inválido detectado en tanque " + (esJugador ? "jugador" : "enemigo " + tipoEnemigo) + ", reseteando a 0");
      angulo = 0; // Resetear a un ángulo válido
      return;
    }
    
    // Verificar valores extremos que podrían causar problemas
    if (angulo > 1000 || angulo < -1000) {
      println("DEBUG: Ángulo extremo detectado en " + (esJugador ? "jugador" : "enemigo " + tipoEnemigo) + ": " + angulo + ", reseteando a 0");
      angulo = 0;
      return;
    }
    
    // Normalizar el ángulo entre 0 y TWO_PI de manera más robusta
    // Usar operaciones más estables para evitar errores de precisión
    while (angulo >= TWO_PI) {
      angulo -= TWO_PI;
    }
    while (angulo < 0) {
      angulo += TWO_PI;
    }
    
    // Verificación final de que el ángulo está en el rango correcto
    if (angulo < 0 || angulo >= TWO_PI) {
      println("DEBUG: Ángulo fuera de rango después de normalización en " + (esJugador ? "jugador" : "enemigo " + tipoEnemigo) + ": " + angulo + ", reseteando a 0");
      angulo = 0;
    }
  }
  
  // NUEVO: Función para monitorear cambios de ángulo y detectar problemas
  void monitorearCambioAngulo() {
    float diferencia = abs(angulo - anguloAnterior);
    
    // Detectar cambios bruscos o anómalos
    if (diferencia > PI/2 && diferencia < PI*1.5) { // Cambio brusco pero no completo
      contadorCambiosAngulo++;
      frameUltimoCambio = frameCount;
      
      if (contadorCambiosAngulo > 5) { // Muchos cambios bruscos seguidos
        println("DEBUG: Muchos cambios bruscos de ángulo detectados en " + 
                (esJugador ? "jugador" : "enemigo " + tipoEnemigo) + 
                " - Oleada: " + oleadaActual + 
                " - Cambios: " + contadorCambiosAngulo);
        
        // Resetear el ángulo a un valor estable
        angulo = 0;
        contadorCambiosAngulo = 0;
      }
    } else if (diferencia < 0.01) {
      // Cambio normal, resetear contador
      contadorCambiosAngulo = 0;
    }
    
    // Resetear contador si han pasado muchos frames
    if (frameCount - frameUltimoCambio > 300) {
      contadorCambiosAngulo = 0;
    }
    
    anguloAnterior = angulo;
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
    // CORREGIDO: Usar noStroke() para evitar bordes no deseados
    noStroke();
    
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
    // CORREGIDO: Verificar que balas no sea null
    if (balas == null) return;
    
    // SOLUCIONADO: Validar ángulo antes de disparar
    validarAngulo();
    
    // NUEVO: Verificación extra antes de disparar
    if (Float.isNaN(angulo) || Float.isInfinite(angulo) || angulo > 1000 || angulo < -1000) {
      println("DEBUG: Ángulo inválido detectado antes de disparar en " + 
              (esJugador ? "jugador" : "enemigo " + tipoEnemigo) + 
              " - Oleada: " + oleadaActual + " - Ángulo: " + angulo);
      angulo = 0; // Resetear y no disparar
      return;
    }
    
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
    
    // CORREGIDO: Verificar sonido antes de reproducir
    if (sonidoDisparo != null && !audioMuteado) {
      sonidoDisparo.amp(volumenMaster * 0.1);
      sonidoDisparo.play();
    }
  }

  void recibirDano(float cantidad) {
    this.vida -= cantidad;
    this.vida = constrain(vida, 0, vidaMaxima);

    // CORREGIDO: Verificar sonido antes de reproducir
    if (this.esJugador && sonidoImpacto != null && !audioMuteado) {
      sonidoImpacto.amp(volumenMaster * 0.6);
      sonidoImpacto.play();
    }
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
