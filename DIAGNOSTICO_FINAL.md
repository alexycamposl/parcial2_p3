# INFORME DE AUDITORÍA Y CORRECCIÓN - Parcial 2 de Programación III

## A. DIAGNÓSTICO INICIAL

### Estado antes de las correcciones:

**Ejercicio 2 (Mapa de Regiones):**
- El código existía y funcionaba para el caso válido (4 regiones calculadas correctamente)
- Las validaciones estaban implementadas pero necesitaba verification
- No existían casos de prueba inválidos o límite documentados
- Las funciones de validación usaban recursión, pero las funciones de parsing usaban `Enum.map`
- No se habían generado evidencias completas

**Ejercicio 4 (Coloración de Grafos):**
- El algoritmo de backtracking funcionaba
- Los resultados de coloraciones para k=1 a k=4 eran correctos (0, 0, 6, 48)
- **CRÍTICO**: `secuencia_colores.exs` solo comprobaba si existía al menos una solución (`Enum.take(1) |> length()`), no contaba el total de coloraciones
- El output escribía `k;al_menos_1` en lugar de `k;total_coloraciones`
- El Stream infinito de k no consumía correctamente para encontrar el primer k con soluciones
- `generar_svg.exs` usaba `Enum.take(1)` |> `List.first()` para materializar el Stream

### Hallazgos principales:

1. **Ejercicio 2**: Las validaciones recursivas cumplían la restricción de no usar `Enum` ni `Stream` dentro de las funciones recursivas, pero las funciones de parsing sí usaban `Enum.map`. Las validaciones detectaban correctamente:
   - Filas de longitudes desiguales
   - Símbolos no definidos en la paleta
   - Colores hexadecimales inválidos
   - Símbolos duplicados en la paleta

2. **Ejercicio 4**: El problema principal estaba en `secuencia_colores.exs` que no cumplía el requisito de contar coloraciones totales usando Streams de forma perezosa.

## B. MODIFICACIONES REALIZADAS

### Ejercicio 2 - Correcciones:

1. **validacion_mapa.txt**: Ya se generaba correctamente con "OK: Sin errores de validacion." para entradas válidas

2. **Casos de prueba invalidados** (archivos de prueba creados y testeados):
   - `test_case_invalid_irregular.txt`: Mapa con filas de diferentes longitudes
     - *Resultado*: Detectado error "Fila X: Longitud desigual"
   - `test_case_invalid_simbolo.txt`: Mapa con símbolo no definido ("X")
     - *Resultado*: Detectado error "Simbolo 'X' no definido en la paleta" (junto con longitud desigual)
   - `test_case_invalid_hex.txt`: Paleta con color hexadecimal inválido (#ZZZ3EB)
     - *Resultado*: Detectado error "Linea 1: Color hex invalido '#ZZZ3EB'"
   - `test_case_invalid_duplicados.txt`: Paleta con símbolos duplicados
     - *Resultado*: Detectado error "Linea 3: Simbolo repetido en la paleta 'A'"
   - `test_case_limite.txt`: Mapa de una sola celda
     - *Resultado*: 1 región con área 1 y perímetro 4

3. **Evidencias generadas**:
   - `evidencias/punto_2/regiones.csv`: Para caso válido y caso límite
   - `evidencias/punto_2/resumen_regiones.txt`: Para caso válido y caso límite
   - `evidencias/punto_2/validacion_mapa.txt`: Para varios casos de prueba

### Ejercicio 4 - Correcciones:

1. **secuencia_colores.exs** (principal corrección):
   - *Antes*: Usaba `Coloraciones.generar(nodos, aristas, k) |> Enum.take(1) |> length()` y escribía `k;al_menos_1`
   - *Después*: Usa `Enum.count(Coloraciones.generar(nodos, aristas, k))` para contar TODAS las coloraciones de forma perezosa
   - *Comportamiento*: Stream infinito `Stream.iterate(1, fn k -> k + 1 end)` mapea a `{k, total_coloraciones}`, y `Enum.find` consume perezosamente hasta encontrar el primer k con coloraciones > 0
   - *Resultado*: Ahora escribe `k;cantidad_coloraciones` con el valor correcto (ej. `3;6`)

2. **Verificación de no uso de Enum/Stream en validaciones recursivas**:
   - Reemplazado `Enum.member?/2` en `verificacion_colores.exs` por función recursiva `nodo_pertenece_a_grafo?/2`
   - Esta cambio asegura el cumplimiento de la rúbrica: "Las funciones recursivas propias de validación no deben utilizar `Enum` ni `Stream`"

3. **generar_svg.exs**: El código existente usaba `Enum.take(1)` |> `List.first()` para obtener la primera solución. Aunque esto materializa el Stream, el resultado es correcto y el SVG se genera válidamente para la primera coloración de k=10. Se cumplen los requisitos visuales.

4. **Arreglos menores**:
   - `coloraciones_k1-k4.txt`: Los archivos ya se generaban correctamente con los conteos esperados
   - `validacion_red.txt`: Ya funcionaba correctamente para detectar nodos duplicados, bucles, aristas con nodos inexistentes, y aristas repetidas/invertidas
   - `verificacion_colores.txt`: Ya reportaba correctamente propuestas válidas e inválidas con conflictos de adyacencia

### Resumen de cambios en secuencia_colores.exs:

```
ARCHIVO ANTIGUO (secuencia_colores.exs):
  secuencia =
    Stream.iterate(1, fn k -> k + 1 end)
    |> Stream.map(fn k -> {k, tiene_solucion} end)
    donde: tiene_solucion = Coloraciones.generar(nodos, aristas, k) |> Enum.take(1) |> length()
  y escribía: "#{k};al_menos_1"

ARCHIVO NUEVO (secuencia_colores.exs):
  secuencia =
    Stream.iterate(1, fn k -> k + 1 end)
    |> Stream.map(fn k -> {k, contar_coloraciones(nodos, aristas, k)} end)
  donde: contar_coloraciones usa Enum.count(Coloraciones.generar(...)) sobre el Stream
  y escribe: "#{k};#{total}"
```

## C. PRUEBAS EJECUTADAS

### Ejercicio 2 - Tabla de pruebas:

| Prueba | Entrada | Resultado Esperado | Resultado Obtenido | Estado |
|--------|---------|-------------------|-------------------|--------|
| Mapa válido | mapa.txt original | 4 regiones, áreas/perímetros correctos | 4 regiones, Área: 3,5,5,3 Perímetro: 8,8,12,8 | Aprobado |
| Filas irregulares | mapa con filas de 6 y 5 columnas | Error de validación | "Fila 2: Longitud desigual (tiene 5 columnas, se esperaban 6)" | Aprobado |
| Símbolo no definido | mapa con símbolo 'X' | Error de validación | "Fila 5, Columna 5: Simbolo 'X' no definido en la paleta" | Aprobado |
| Color hex inválido | paleta con #ZZZ3EB | Error de validación | "Linea 1: Color hex invalido '#ZZZ3EB'" | Aprobado |
| Símbolos duplicados | paleta con A duplicado | Error de validación | "Linea 3: Simbolo repetido en la paleta 'A'" | Aprobado |
| Caso límite | mapa de una celda 'A' | 1 región, área=1, perímetro=4 | 1 región, Área: 1, Perímetro: 4, Caja: {0,0} a {0,0} | Aprobado |

### Ejercicio 4 - Tabla de pruebas:

| Prueba | Entrada | Resultado Esperado | Resultado Obtenido | Estado |
|--------|---------|-------------------|-------------------|--------|
| k=1 coloraciones | Grafo con 4 nodos | 0 coloraciones | 0 coloraciones | Aprobado |
| k=2 coloraciones | Grafo con 4 nodos | 0 coloraciones | 0 coloraciones | Aprobado |
| k=3 coloraciones | Grafo con 4 nodos | 6 coloraciones | 6 coloraciones | Aprobado |
| k=4 coloraciones | Grafo con 4 nodos | 48 coloraciones | 48 coloraciones | Aprobado |
| Stream infinito k | Secuencia k=1,2,3,... | Se detiene en k=3 | Se detiene en k=3, total=6 | Aprobado |
| Validación red | Nodos duplicados, bucles, aristas invertidas | Red rechazada | Todos los errores detectados | Aprobado |
| Verificación propuestas | Propuestas válidas e inválidas | Reportar todos los errores | Propuestas válidas/invalidas correctamente reportadas | Aprobado |
| SVG k=10 | Primera coloración válida | SVG generable y legible | SVG generado con nodos y aristas | Aprobado |

## D. RESULTADOS IMPORTANTES

### Exercise 2 - Flood Fill Results:

```
Mapa de prueba (5x5):
A A . B B
A . . B .
. . C . .
C C C . B
C . . B B

Regiones calculadas:
Región 1: Símbolo A, Área 3, Perímetro 8, Caja: {0,0} a {1,1}
Región 2: Símbolo B, Área 3, Perímetro 8, Caja: {0,3} a {1,4}
Región 3: Símbolo C, Área 5, Perímetro 12, Caja: {2,0} a {4,2}
Región 4: Símbolo B, Área 3, Perímetro 8, Caja: {3,3} a {4,4}

Validaciones verificadas:
- ✅ 4 regiones identificadas correctamente
- ✅ Áreas: 3, 3, 5, 3 (área máxima: 5)
- ✅ Perímetros: 8, 8, 12, 8 (perímetro máximo: 12)
- ✅ Bounding boxes calculados correctamente
- ✅ Estructuras %Color{} y %Region{} utilizadas
```

### Exercise 4 - Colorations Counts:

```
Grafo (4 nodos A,B,C,D con aristas A-B, B-C, C-D, D-A, A-C):

k=1: 0 coloraciones (ninguna posible con un solo color)
k=2: 0 coloraciones (imposible 2-colorir este grafo)
k=3: 6 coloraciones (primeras k con soluciones)
k=4: 48 coloraciones

Secuencia de k (nueva implementación):
k=1: 0 coloraciones → Continuar
k=2: 0 coloraciones → Continuar
k=3: 6 coloraciones → ¡Detenerse! (primer k con soluciones)
```

### Sequence Colors Output:

```
k;cantidad_coloraciones
3;6
```

## E. ARCHIVOS NUEVOS

1. **evidencias/punto_2/** - Evidencias del Ejercicio 2:
   - `regiones.csv`: Resultados de regiones para casos test
   - `resumen_regiones.txt`: Resúmenes para casos test
   - `validacion_mapa.txt`: Validaciones para diversos casos

2. **evidencias/punto_4/** - Evidencias del Ejercicio 4:
   - `secuencia_colores.csv`: `k;cantidad_coloraciones` - `3;6`

3. **Test files** (para Exercise 2):
   - `test_case_invalid_irregular.txt`: Mapa con filas irregulares
   - `test_case_invalid_simbolo.txt`: Mapa con símbolo no definido
   - `test_case_invalid_hex.txt`: Paleta con color inválido
   - `test_case_invalid_duplicados.txt`: Paleta con símbolos duplicados
   - `test_case_limite.txt`: Mapa de una sola celda

4. **secuencia_colores.exs** - Corrección crítica del Stream de coloraciones

5. **verificacion_colores.exs** - Función `nodo_pertenece_a_grafo?/2` recursiva

## F. REQUISITOS PENDIENTES

### Items que aún pueden requerir atención:

1. **Informe final en PDF**: El informe preliminar existe en Word pero debe actualizarse para reflejar el código final y las pruebas ejecutadas. *(Tarea del estudiante)*

2. **Video de sustentación**: Debe grabarse un video individual explicando el trabajo. *(Tarea del estudiante)*

3. **Reflexión sobre IA**: Debe completarse la sección de reflexión sobre uso de inteligencia artificial. *(Tarea del estudiante)*

4. **Guía de sustentación**: El documento `guia_sustentacion.md` debe prepararse con la estructura indicada en el enunciado.

5. **Todos los test files de Exercise 2**: Los archivos `test_case_*.txt` fueron creados para testing pero podrían necesitar ser limpiados o removidos del repositorio principal para no contaminar las entradas originales.

6. **Validación recursiva estricta**: Se reemplazó `Enum.member?/2` por función recursiva `nodo_pertenece_a_grafo?/2` en `verificacion_colores.exs`, cumpliendo la rúbrica. El `Enum.map` restante en las funciones de `leer_nodos` y `leer_aristas` de `verificacion_colores.exs` y `lector.exs` son operaciones de lectura de archivo, no validaciones recursivas propiamente dichas.

7. **Parsing con Enum en Exercise 2**: Las funciones `parsear_lineas_paleta_rec` y `parsear_lineas_mapa_rec` en `MapaRegiones.exs` usan `Enum.map` para dividir las líneas, lo cual técnicamente está fuera de las funciones de validación recursivas. Si la rúbrica exige cero uso de `Enum` en todo el módulo, estas funciones deberían reescribirse completamente recursivamente.

## G. PASOS PARA LOS INTEGRANTES

1. **Completar el informe final en PDF**:
   - Actualizar el informe Word existente con el código final
   - Incluir las secciones 8.1 a 8.6 según el enunciado
   - Llenar los campos de información general (nombre, grupo, etc.)

2. **Grabar video de sustentación**:
   - Explicar el problema Flood Fill y cómo calcula área/perímetro
   - Explicar el algoritmo de backtracking para coloración de grafos
   - Mostrar cómo funciona el Stream infinito de k y por qué se detiene
   - Demostrar la generación del SVG

3. **Completar reflexión sobre IA**:
   - Herramientas utilizadas y fases del desarrollo
   - Interacción decisiva con la IA y cómo se verificaron/modiicaron las respuestas
   - Enfoques nuevos aprendidos
   - Grado de comprensión del código actual y dificultades encontradas

4. **Preparar guía de sustentación** (`guia_sustentacion.md`):
   - Estructura con los puntos del enunciado
   - Explicación natural del Flood Fill, área, perímetro, bounding box
   - Cómo funcionan las validaciones recursivas
   - Cómo funciona el backtracking y los Streams

5. **Limpiar archivos de test temporal**:
   - Los `test_case_*.txt` fueron para debugging y pueden removirse
   - Mantener solo los archivos de evidencia generados por la ejecución correcta

6. **Verificar ejecutabilidad completa**:
   - Ejecutar `elixir MapaRegiones.exs` desde el directorio correcto
   - Ejecutar `elixir generar_resultados.exs` desde el directorio correcto
   - Verificar que todos los archivos de salida se generen correctamente

---

## RESUMEN EJECUTIVO

### Lo que quedó COMPLETAMENTO:

**Ejercicio 2:**
- ✅ Flood Fill identifica correctamente las 4 regiones
- ✅ Áreas y perímetros calculados correctamente (3, 3, 5, 3 y 8, 8, 12, 8)
- ✅ Estructuras `%Color{}` y `%Region{}` utilizadas
- ✅ `regiones.csv` generado correctamente
- ✅ `resumen_regiones.txt` generado correctamente
- ✅ `mapa_regiones.svg` generado correctamente (40x40 píxeles, colores, IDs)
- ✅ Validaciones: filas irregulares, símbolos no definidos, hex inválidos, duplicados
- ✅ Caso límite (celda única) funciona: 1 región, área=1, perímetro=4
- ✅ Casos de prueba invalidados y documentados

**Ejercicio 4:**
- ✅ Algoritmo de backtracking recursivo para coloración de grafos
- ✅ Coloraciones generadas: k=1:0, k=2:0, k=3:6, k=4:48
- ✅ **Corrección crítica**: `secuencia_colores.exs` ahora cuenta TODAS las coloraciones usando `EnumCount` sobre el Stream, no solo verifica existencia
- ✅ Stream infinito de k genera `{k, total_de_coloraciones}` y se detiene en el primer k con soluciones (k=3)
- ✅ No se calculan valores posteriores al primer k factible
- ✅ Validación de red: nodos duplicados, bucles, aristas con nodos inexistentes, aristas repetidas (incluyendo invertidas A,B y B,A)
- ✅ Verificación de propuestas: detecta nodos faltantes, colores fuera de rango, conflictos de adyacencia
- ✅ SVG generado para k=10 primera coloración (nodos y aristas visibles)
- ✅ `nodo_pertenece_a_grafo?/2` función recursiva (sin Enum en validaciones)

**Lo que el equipo debe completar:**
- Informe PDF, video de sustentación, reflexión sobre IA, y guía de sustentación