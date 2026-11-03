PARCIAL 2 - PROGRAMACIÓN III - Universidad del Quindío
========================================================

EJERCICIO 2: MAPA DE REGIONES Y FLOOD FILL
--------------------------------------------

Problema: Procesar un mapa de símbolos y encontrar regiones conectadas
ortogonalmente mediante Flood Fill.

Estructuras utilizadas:
- %Color{}: simbolo, nombre, hex
- %Region{}: id, simbolo, celdas, area, perimetro, desde, hasta

Archivos de entrada:
- mapa.txt: mapa de símbolos (5x5 con símbolos A, B, C, .)
- paleta.csv: definición de colores (#RRGGBB)

Archivos de salida generados:
- regiones.csv: id;simbolo;area;perimetro;desde;hasta
- resumen_regiones.txt: resumen estadístico de regiones
- mapa_regiones.svg: representación visual (40px por celda)

Resultados para el mapa de prueba:
| Región | Símbolo | Área | Perímetro |
|--------|---------|------|-----------|
| 1 | A | 3 | 8 |
| 2 | B | 3 | 8 |
| 3 | C | 5 | 12 |
| 4 | B | 3 | 8 |

Validaciones implementadas:
- Filas de diferentes longitudes → error detectado
- Símbolos no definidos en paleta → error detectado
- Colores hexadecimales inválidos → error detectado
- Símbolos duplicados en paleta → error detectado

EJERCICIO 4: COLORACIÓN DE GRAFOS, BACKTRACKING Y STREAMS
------------------------------------------------------------

Problema: Coloración de grafos no dirigidos mediante backtracking recursivo.

Estructura del grafo:
- Nodos: A, B, C, D (con coordenadas x,y)
- Aristas: A-B, B-C, C-D, D-A, A-C (grafo con ciclo)

Resultados de coloraciones por valor de k:
| k | Coloraciones Válidas |
|---|----------------------|
| 1 | 0 |
| 2 | 0 |
| 3 | 6 |
| 4 | 48 |

Secuencia de k (main característica):
- Stream infinito k = 1, 2, 3, 4, 5, ...
- Para cada k, se cuenta el total de coloraciones válidas
- Se detiene en el primer k con soluciones (k=3 con 6 coloraciones)
- No se calculan valores posteriores

Archivos de entrada:
- nodos.csv: identificadores y coordenadas
- aristas.csv: relaciones entre nodos
- colores.txt: valores de k a evaluar (1,2,3,4)

Archivos de salida generados:
- coloraciones_k1.txt a coloraciones_k4.txt: soluciones por k
- secuencia_colores.csv: k;cantidad_coloraciones (3;6)
- validacion_red.txt: resultado de validación de la red
- verificacion_colores.txt: verificación de propuestas
- primera_coloracion_k10.svg: primera coloración válida para k=10

Validaciones implementadas:
- Nodos duplicados → red rechazada
- Aristas con nodos inexistentes → red rechazada
- Bucles (A,A) → red rechazada
- Aristas repetidas (A,B y B,A) → red rechazada
- Propuestas válidas → aceptadas
- Propuestas con errores → se reportan todos los errores (faltantes, adicionales, fuera de rango, conflictos)

Archivos ejecutables:
- elixir punto_2/MapaRegiones.exs      → Ejercicio 2
- elixir parcial_punto_4/punto4.exs     → Punto de entrada (tiene error Util2)
- elixir parcial_punto_4/generar_resultados.exs → Genera coloraciones por k
- elixir parcial_punto_4/lector.exs      → Lector de flujos de archivos
- elixir parcial_punto_4/coloraciones.exs → Backtracking de coloraciones
- elixir parcial_punto_4/validacion_red.exs → Validación de redes
- elixir parcial_punto_4/verificacion_colores.exs → Verificación de propuestas
- elixir parcial_punto_4/secuencia_colores.exs → Secuencia infinita de k (CORREGIDO)
- elixir parcial_punto_4/generar_svg.exs → Generación de SVG
- elixir parcial_punto_4/proueba_coloraciones.exs → Pruebas several
- elixir parcial_punto_4/prueba_lector.exs → Pruebas lector
- elixir parcial_punto_4/prueba_validacion.exs → Pruebas validación

INSTRUCCIONES DE EJECUCIÓN:

Ejercicio 2:
  cd parcial2_p3/punto_2
  elixir MapaRegiones.exs

Ejercicio 4:
  cd parcial2_p3/parcial_punto_4
  elixir secuencia_colores.exs     # Genera secuencia_colores.csv (3;6)
  elixir generar_resultados.exs    # Genera coloraciones_k1-4.txt
  elixir verificacion_colores.exs  # Verifica propuestas
  elixir generar_svg.exs             # Genera primera_coloracion_k10.svg

Versión de Elixir: 1.20.5
Erlang/OTP: 29