class Bala {
  PVector posicion;
  PVector velocidad;
  Tanque propietario;
  int tamano = 12;
  boolean haColisionado = false;
  
  // NUEVO: Para saber si es una bala especial
  boolean esBalaRalentizante;

  // Constructor con 4 parámetros (para balas especiales)
  Bala(PVector origen, PVector direccion, Tanque propietario, boolean esBalaEspecial) {
    this.posicion = origen.copy();
    this.velocidad = direccion.copy().mult(8);
    this.propietario = propietario;
    this.esBalaRalentizante = esBalaEspecial;
  }

  // Constructor con 3 parámetros (para balas normales)
  Bala(PVector origen, PVector direccion, Tanque propietario) {
    this(origen, direccion, propietario, false); // Por defecto no es especial
  }

  void actualizar() {
    posicion.add(velocidad);
  }

  void mostrar() {
    pushMatrix();
    translate(posicion.x, posicion.y);
    
    // Si es una bala de Disabler, cambiar su color
    if (esBalaRalentizante) {
        fill(100, 100, 255, 50); // Halo azul
        noStroke();
        ellipse(0, 0, tamano + 6, tamano + 6);
        fill(100, 100, 255);
        stroke(200, 200, 255);
        strokeWeight(2);
        ellipse(0, 0, tamano, tamano);
    } else {
        // Estilo de bala normal
        fill(255, 200, 0, 50);
        noStroke();
        ellipse(0, 0, tamano + 6, tamano + 6);
        fill(50, 50, 50);
        stroke(255, 200, 0); 
        strokeWeight(2);
        ellipse(0, 0, tamano, tamano);
    }
    popMatrix();
  }

  void comprobarColision(Tanque objetivo) {
    if (this.propietario == objetivo || this.haColisionado) {
      return;
    }
    
    float distancia = dist(this.posicion.x, this.posicion.y, objetivo.posicion.x, objetivo.posicion.y);
    if (distancia < (this.tamano / 2 + objetivo.tamano / 2)) {
      
      // NUEVO: Lógica de la bala ralentizante
      if (esBalaRalentizante && objetivo.esJugador) {
          // En lugar de aplicarRalentizacion(), simplemente hacer daño
          objetivo.recibirDano(5); // Hace poco daño, pero molesta
      } else {
          // Lógica de daño normal
          float dano;
          if (this.propietario.esJugador) {
            dano = max(10, 30 - (this.propietario.muertes * 2));
          } else {
            dano = 20;
          }
          objetivo.recibirDano(dano);
      }

      this.haColisionado = true;
      crearEfectoImpacto(objetivo.posicion.x, objetivo.posicion.y);
    }
  }

  boolean estaFuera() {
    return (posicion.x < -tamano || posicion.x > width + tamano || 
            posicion.y < -tamano || posicion.y > height + tamano);
  }
}

// Función auxiliar para efectos visuales
void crearEfectoImpacto(float x, float y) {
  // Aquí podrías agregar partículas o efectos de impacto
  // Por ahora, solo un efecto simple
  for (int i = 0; i < 6; i++) {
    float angulo = random(TWO_PI);
    float velocidad = random(2, 5);
    // Podrías crear una clase Particula para efectos más elaborados
  }
}
