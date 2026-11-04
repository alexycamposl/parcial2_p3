defmodule Color do
  defstruct [:simbolo, :nombre, :hex]
end

defmodule Region do
  defstruct [:id, :simbolo, :celdas, :area, :perimetro, :desde, :hasta]
end

defmodule MapaRegiones do
  @tam_celda 40

  def ejecutar do
    archivos_requeridos = ["mapa.txt", "paleta.csv"]

    with :ok <- verificar_existencia_archivos(archivos_requeridos) do
      procesar()
    end
  end

  # REQUISITO 6: Verificación de archivos y manejo de errores de entrada

  defp verificar_existencia_archivos([]) do
    :ok
  end

  defp verificar_existencia_archivos([archivo | resto]) do
    if File.exists?(archivo) do
      verificar_existencia_archivos(resto)
    else
      IO.puts("ERROR: El archivo requerido '#{archivo}' no existe.")
      {:error, {:archivo_faltante, archivo}}
    end
  end

  # REQUISITO 1 y 3: Lectura en Flujo y Eliminación de comentarios/vacías

  defp leer_lineas_flujo(ruta) do
    File.stream!(ruta)
    |> Stream.with_index(1)
    |> Stream.map(fn {linea, num_linea} -> {String.trim(linea), num_linea} end)
    |> Stream.reject(fn {linea, _} ->
      linea == "" or String.starts_with?(linea, "#")
    end)
  end

  # REQUISITO 7: Validación Previa Recursiva (Sin Enum ni Stream dentro)

  defp validar_datos(lineas_mapa, lineas_paleta) do
    paleta_tokens = parsear_lineas_paleta_rec(lineas_paleta)
    errores_paleta = validar_paleta_rec(paleta_tokens, MapSet.new(), [])

    simbolos_paleta = extraer_simbolos_paleta_rec(paleta_tokens, MapSet.new())

    mapa_filas = parsear_lineas_mapa_rec(lineas_mapa)

    ancho_esperado = case mapa_filas do
      [{tokens, _} | _] -> rec_length(tokens)
      [] -> 0
    end

    errores_mapa = validar_mapa_rec(mapa_filas, 0, ancho_esperado, simbolos_paleta, [])

    errores_totales = errores_paleta ++ errores_mapa

    if rec_length(errores_totales) > 0 do
      {:error, errores_totales}
    else
      {:ok, paleta_tokens, mapa_filas}
    end
  end

  # Auxiliares recursivas para la validación (Cero Enum / Cero Stream)

  defp rec_length([]), do: 0
  defp rec_length([_ | t]), do: 1 + rec_length(t)

  defp parsear_lineas_paleta_rec([]), do: []
  defp parsear_lineas_paleta_rec([{linea, num_linea} | resto]) do
    partes = String.split(linea, ",") |> Enum.map(&String.trim/1)
    [{partes, num_linea} | parsear_lineas_paleta_rec(resto)]
  end

  defp parsear_lineas_mapa_rec([]), do: []
  defp parsear_lineas_mapa_rec([{linea, num_linea} | resto]) do
    tokens = String.split(linea) |> Enum.map(&String.trim/1)
    [{tokens, num_linea} | parsear_lineas_mapa_rec(resto)]
  end

  # Cláusulas de validar_paleta_rec/3 agrupadas seguidas
  defp validar_paleta_rec([], _vistos, acc_errores) do
    acc_errores
  end

  defp validar_paleta_rec([{partes, num_linea} | resto], vistos, acc) do
    acc1 = case partes do
      [simbolo, _nombre, hex] ->
        acc_hex = if es_hex_valido?(hex), do: acc, else: ["Linea #{num_linea}: Color hex invalido '#{hex}'." | acc]
        if MapSet.member?(vistos, simbolo) do
          ["Linea #{num_linea}: Simbolo repetido en la paleta '#{simbolo}'." | acc_hex]
        else
          acc_hex
        end

      _ ->
        ["Linea #{num_linea}: Formato invalido de paleta." | acc]
    end

    simbolo = case partes do
      [s | _] -> s
      _ -> ""
    end

    validar_paleta_rec(resto, MapSet.put(vistos, simbolo), acc1)
  end

  defp extraer_simbolos_paleta_rec([], acc), do: acc
  defp extraer_simbolos_paleta_rec([{partes, _} | resto], acc) do
    case partes do
      [s, _, _] -> extraer_simbolos_paleta_rec(resto, MapSet.put(acc, s))
      _ -> extraer_simbolos_paleta_rec(resto, acc)
    end
  end

  # Validación de Hexadecimal por Pattern Matching de Binarios
  defp es_hex_valido?(<<"#", resto::binary-size(6)>>) do
    String.match?(resto, ~r/^[0-9A-Fa-f]{6}$/)
  end
  defp es_hex_valido?(_), do: false

  defp validar_mapa_rec([], cant_filas, _ancho_esp, simbolos_paleta, acc) do
    acc1 = if cant_filas == 0, do: ["El mapa no contiene filas validas." | acc], else: acc
    acc2 = if not MapSet.member?(simbolos_paleta, "."), do: ["El simbolo '.' de fondo no esta definido en la paleta." | acc1], else: acc1
    acc2
  end

  defp validar_mapa_rec([{tokens, num_linea} | resto], fila_idx, ancho_esp, simbolos_paleta, acc) do
    len = rec_length(tokens)

    acc_len = if len != ancho_esp do
      ["Fila #{num_linea}: Longitud desigual (tiene #{len} columnas, se esperaban #{ancho_esp})." | acc]
    else
      acc
    end

    acc_syms = validar_tokens_mapa_rec(tokens, num_linea, 0, simbolos_paleta, acc_len)
    validar_mapa_rec(resto, fila_idx + 1, ancho_esp, simbolos_paleta, acc_syms)
  end

  defp validar_tokens_mapa_rec([], _num_linea, _col_idx, _simbolos_paleta, acc), do: acc
  defp validar_tokens_mapa_rec([token | resto], num_linea, col_idx, simbolos_paleta, acc) do
    acc1 = if not MapSet.member?(simbolos_paleta, token) do
      ["Fila #{num_linea}, Columna #{col_idx}: Simbolo '#{token}' no definido en la paleta." | acc]
    else
      acc
    end

    validar_tokens_mapa_rec(resto, num_linea, col_idx + 1, simbolos_paleta, acc1)
  end

  # REQUISITO 2 y REQUISITO 8: Construcción de mapa y Búsqueda de Regiones

  defp procesar do
    lineas_mapa = leer_lineas_flujo("mapa.txt") |> Enum.to_list()
    lineas_paleta = leer_lineas_flujo("paleta.csv") |> Enum.to_list()

    case validar_datos(lineas_mapa, lineas_paleta) do
      {:error, errores} ->
        escribir_errores_validacion(errores)
        IO.puts("Se encontraron errores de validacion. Revise 'validacion_mapa.txt'.")

      {:ok, paleta_raw, mapa_raw} ->
        File.write!("validacion_mapa.txt", "OK: Sin errores de validacion.\n")

        paleta_map = construir_paleta_map(paleta_raw)
        {grid, max_filas, max_cols} = construir_grid_mapa(mapa_raw)

        regiones = encontrar_regiones(grid, max_filas, max_cols)

        # Generación de Salidas en Flujo (REQUISITO 4 y 5)
        escribir_regiones_csv(regiones)
        escribir_mapa_svg(grid, regiones, paleta_map, max_filas, max_cols)
        escribir_resumen_y_pantalla(regiones)
    end
  end

  defp escribir_errores_validacion(errores) do
    File.open!("validacion_mapa.txt", [:write, :utf8], fn archivo ->
      errores
      |> Enum.reverse()
      |> Enum.each(fn err -> IO.write(archivo, "#{err}\n") end)
    end)
  end

  defp construir_paleta_map(paleta_raw) do
    Enum.reduce(paleta_raw, %{}, fn {partes, _}, acc ->
      case partes do
        [s, n, h] -> Map.put(acc, s, %Color{simbolo: s, nombre: n, hex: h})
        _ -> acc
      end
    end)
  end

  defp construir_grid_mapa(mapa_raw) do
    {grid, max_r, max_c} =
      Enum.reduce(mapa_raw, {%{}, 0, 0}, fn {tokens, _}, {acc_grid, r, _} ->
        {num_cols, new_grid} =
          Enum.reduce(tokens, {0, acc_grid}, fn token, {c, g} ->
            {c + 1, Map.put(g, {r, c}, token)}
          end)

        {new_grid, r + 1, num_cols}
      end)

    {grid, max_r, max_c}
  end

  # ALGORITMO RECURSIVO: Flood Fill (Caminata de regiones)

  defp encontrar_regiones(grid, max_filas, max_cols) do
    recorrer_casillas(0, 0, max_filas, max_cols, grid, MapSet.new(), 1, [])
    |> Enum.reverse()
  end

  defp recorrer_casillas(r, _c, max_filas, _max_cols, _grid, _visitados, _next_id, acc) when r >= max_filas do
    acc
  end

  defp recorrer_casillas(r, c, max_filas, max_cols, grid, visitados, next_id, acc) when c >= max_cols do
    recorrer_casillas(r + 1, 0, max_filas, max_cols, grid, visitados, next_id, acc)
  end

  defp recorrer_casillas(r, c, max_filas, max_cols, grid, visitados, next_id, acc) do
    pos = {r, c}
    simbolo = Map.get(grid, pos)

    if simbolo == "." or MapSet.member?(visitados, pos) do
      recorrer_casillas(r, c + 1, max_filas, max_cols, grid, visitados, next_id, acc)
    else
      {celdas_region, nuevos_visitados} = explorar_vecinos([pos], simbolo, grid, MapSet.new(), visitados)

      area = MapSet.size(celdas_region)
      perimetro = calcular_perimetro(celdas_region, simbolo, grid)
      {desde, hasta} = calcular_caja_envolvente(celdas_region)

      region = %Region{
        id: next_id,
        simbolo: simbolo,
        celdas: celdas_region,
        area: area,
        perimetro: perimetro,
        desde: desde,
        hasta: hasta
      }

      recorrer_casillas(r, c + 1, max_filas, max_cols, grid, nuevos_visitados, next_id + 1, [region | acc])
    end
  end

  defp explorar_vecinos([], _simbolo, _grid, celdas_region, visitados) do
    {celdas_region, visitados}
  end

  defp explorar_vecinos([pos | frontera], simbolo, grid, celdas_region, visitados) do
    if MapSet.member?(celdas_region, pos) do
      explorar_vecinos(frontera, simbolo, grid, celdas_region, visitados)
    else
      nuevas_celdas = MapSet.put(celdas_region, pos)
      nuevos_visitados = MapSet.put(visitados, pos)

      vecinos_validos =
        obtener_vecinos(pos)
        |> Enum.filter(fn v_pos ->
          Map.get(grid, v_pos) == simbolo and not MapSet.member?(nuevas_celdas, v_pos)
        end)

      explorar_vecinos(frontera ++ vecinos_validos, simbolo, grid, nuevas_celdas, nuevos_visitados)
    end
  end

  defp obtener_vecinos({r, c}) do
    [{r - 1, c}, {r + 1, c}, {r, c - 1}, {r, c + 1}]
  end

  defp calcular_perimetro(celdas_region, simbolo, grid) do
    Enum.reduce(celdas_region, 0, fn pos, acc_perim ->
      lados_libres =
        obtener_vecinos(pos)
        |> Enum.count(fn v_pos -> Map.get(grid, v_pos) != simbolo end)

      acc_perim + lados_libres
    end)
  end

  defp calcular_caja_envolvente(celdas_region) do
    celdas = MapSet.to_list(celdas_region)
    filas = Enum.map(celdas, fn {r, _c} -> r end)
    cols = Enum.map(celdas, fn {_r, c} -> c end)

    {{Enum.min(filas), Enum.min(cols)}, {Enum.max(filas), Enum.max(cols)}}
  end

  # REQUISITO 4: Salidas por flujo (Fragmentos sin formar string completo)

  defp escribir_regiones_csv(regiones) do
    File.open!("regiones.csv", [:write, :utf8], fn archivo ->
      IO.write(archivo, "id;simbolo;area;perimetro;desde;hasta\n")

      regiones
      |> Stream.each(fn r ->
        desde_str = "{#{elem(r.desde, 0)},#{elem(r.desde, 1)}}"
        hasta_str = "{#{elem(r.hasta, 0)},#{elem(r.hasta, 1)}}"
        linea = "#{r.id};#{escapar_xml(r.simbolo)};#{r.area};#{r.perimetro};#{desde_str};#{hasta_str}\n"
        IO.write(archivo, linea)
      end)
      |> Stream.run()
    end)
  end

  defp escribir_mapa_svg(grid, regiones, paleta_map, max_filas, max_cols) do
    ancho_px = max_cols * @tam_celda
    alto_px = max_filas * @tam_celda

    id_por_casilla =
      Enum.reduce(regiones, %{}, fn r, acc ->
        casilla_min = Enum.min_by(MapSet.to_list(r.celdas), fn {fr, fc} -> {fr, fc} end)
        Map.put(acc, casilla_min, r.id)
      end)

    File.open!("mapa_regiones.svg", [:write, :utf8], fn archivo ->
      # 1. Apertura
      IO.write(
        archivo,
        ~s(<svg xmlns="http://www.w3.org/2000/svg" width="#{ancho_px}" height="#{alto_px}">\n)
      )

      # 2. Dibujar casillas por fragmentos progresivos
      for r <- 0..(max_filas - 1), c <- 0..(max_cols - 1) do
        simbolo = Map.get(grid, {r, c}, ".")
        color_info = Map.get(paleta_map, simbolo, %Color{hex: "#FFFFFF"})
        x = c * @tam_celda
        y = r * @tam_celda

        # Rectángulo
        IO.write(
          archivo,
          ~s(  <rect x="#{x}" y="#{y}" width="#{@tam_celda}" height="#{@tam_celda}" fill="#{color_info.hex}" stroke="#000000" stroke-width="1"/>\n)
        )

        # Texto ID
        case Map.get(id_por_casilla, {r, c}) do
          nil ->
            :ok

          id ->
            tx = x + div(@tam_celda, 2)
            ty = y + div(@tam_celda, 2) + 5

            IO.write(
              archivo,
              ~s(  <text x="#{tx}" y="#{ty}" font-family="sans-serif" font-size="14" font-weight="bold" fill="#000000" text-anchor="middle">#{id}</text>\n)
            )
        end
      end

      # 3. Cierre
      IO.write(archivo, "</svg>\n")
    end)
  end

  defp escapar_xml(texto) do
    texto
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  # REQUISITO 5: Pantalla y Archivo de Resumen

  defp escribir_resumen_y_pantalla(regiones) do
    num_regiones = Enum.count(regiones)

    if num_regiones == 0 do
      contenido = "Numero de regiones: 0\nNo se encontraron regiones.\n"
      IO.puts(contenido)
      File.write!("resumen_regiones.txt", contenido)
    else
      max_area = Enum.map(regiones, & &1.area) |> Enum.max()
      max_perim = Enum.map(regiones, & &1.perimetro) |> Enum.max()

      regiones_max_area = Enum.filter(regiones, &(&1.area == max_area))
      regiones_max_perim = Enum.filter(regiones, &(&1.perimetro == max_perim))

      lineas_resumen = [
        "=========================================",
        "RESUMEN DE REGIONES",
        "=========================================",
        "Numero total de regiones: #{num_regiones}",
        "",
        "--- MAYOR AREA (Area: #{max_area}) ---"
      ] ++
        Enum.map(regiones_max_area, fn r ->
          "ID: #{r.id} | Simbolo: #{r.simbolo} | Area: #{r.area} | Perimetro: #{r.perimetro} | Caja: {#{elem(r.desde, 0)},#{elem(r.desde, 1)}} a {#{elem(r.hasta, 0)},#{elem(r.hasta, 1)}}"
        end) ++
        [
          "",
          "--- MAYOR PERIMETRO (Perimetro: #{max_perim}) ---"
        ] ++
        Enum.map(regiones_max_perim, fn r ->
          "ID: #{r.id} | Simbolo: #{r.simbolo} | Area: #{r.area} | Perimetro: #{r.perimetro} | Caja: {#{elem(r.desde, 0)},#{elem(r.desde, 1)}} a {#{elem(r.hasta, 0)},#{elem(r.hasta, 1)}}"
        end)

      texto_final = Enum.join(lineas_resumen, "\n") <> "\n"

      IO.puts(texto_final)
      IO.puts("Revise el archivo regiones.csv para tener una mayor claridad")
      IO.puts("Abra el archivo mapa_regiones.svg para visualizar el mapa de una mejor forma\n")
      File.write!("resumen_regiones.txt", texto_final)
    end
  end
end

MapaRegiones.ejecutar()
