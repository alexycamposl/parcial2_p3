
defmodule ValidacionRed do

  def validar_nodos(nodos) do
    validar_nodos(nodos, [], [])
  end

  defp validar_nodos([], _vistos, errores) do
    errores
  end

  defp validar_nodos([{linea, nodo} | resto], vistos, errores) do
    if buscar_id(nodo, vistos) do
      error = "Línea #{linea}: ID de nodo duplicado '#{nodo}'."
      validar_nodos(resto, vistos, [error | errores])
    else
      validar_nodos(resto, [nodo | vistos], errores)
    end
  end

  defp buscar_id(_nodo, []) do
    false
  end

  defp buscar_id(nodo, [nodo | _resto]) do
    true
  end

  defp buscar_id(nodo, [_otro | resto]) do
    buscar_id(nodo, resto)
  end


  def validar_aristas(aristas, nodos) do
    validar_aristas(aristas, nodos, [], [])
  end

  defp validar_aristas([], _nodos, _vistas, errores) do
    errores
  end

  defp validar_aristas(
         [{linea, nodo_a, nodo_b} | resto],
         nodos,
         vistas,
         errores
       ) do

    errores_actuales =
      errores_arista(linea, nodo_a, nodo_b, nodos, vistas)

    nueva_vista =
      [{nodo_a, nodo_b} | vistas]

    validar_aristas(
      resto,
      nodos,
      nueva_vista,
      errores_actuales ++ errores
    )
  end

  defp errores_arista(linea, nodo_a, nodo_b, nodos, vistas) do
    desconocidos =
      errores_nodos_desconocidos(
        linea,
        [nodo_a, nodo_b],
        nodos
      )

    bucles =
      if nodo_a == nodo_b do
        ["Línea #{linea}: bucle detectado '#{nodo_a},#{nodo_b}'."]
      else
        []
      end

    repetidas =
      if buscar_arista(nodo_a, nodo_b, vistas) do
        ["Línea #{linea}: arista repetida '#{nodo_a},#{nodo_b}'."]
      else
        []
      end

    desconocidos ++ bucles ++ repetidas
  end

  defp errores_nodos_desconocidos(_linea, [], _nodos) do
    []
  end

  defp errores_nodos_desconocidos(linea, [nodo | resto], nodos) do
    if buscar_id(nodo, nodos) do
      errores_nodos_desconocidos(linea, resto, nodos)
    else
      [
        "Línea #{linea}: nodo desconocido '#{nodo}' en arista."
        | errores_nodos_desconocidos(linea, resto, nodos)
      ]
    end
  end

  defp buscar_arista(_a, _b, []) do
    false
  end

  defp buscar_arista(a, b, [{x, y} | resto]) do
    if (a == x and b == y) or (a == y and b == x) do
      true
    else
      buscar_arista(a, b, resto)
    end
  end


  def validar_archivos do
    ruta_nodos = Path.join(__DIR__, "nodos.csv")
    ruta_aristas = Path.join(__DIR__, "aristas.csv")
    ruta_salida = Path.join(__DIR__, "validacion_red.txt")

    with {:ok, flujo_nodos} <- Lector.leer(ruta_nodos),
         {:ok, flujo_aristas} <- Lector.leer(ruta_aristas) do

      nodos_con_encabezado =
        Enum.to_list(flujo_nodos)

      aristas_con_encabezado =
        Enum.to_list(flujo_aristas)

      nodos =
        convertir_nodos(nodos_con_encabezado)

      aristas =
        convertir_aristas(aristas_con_encabezado)

      errores_nodos = validar_nodos(nodos)

      ids =
        extraer_ids(nodos)

      errores_aristas =
        validar_aristas(aristas, ids)

      errores =
        errores_nodos ++ errores_aristas

      escribir_errores(ruta_salida, errores)

      if errores == [] do
        IO.puts("Red válida. No se encontraron errores.")
        {:ok, nodos, aristas}
      else
        IO.puts("Red inválida. Se encontraron #{length(errores)} errores.")
        {:error, errores}
      end
    else
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("No se encontró el archivo requerido: #{ruta}")
        {:error, {:archivo_no_encontrado, ruta}}
    end
  end

  defp convertir_nodos(lineas) do
    convertir_nodos(lineas, [])
  end

  defp convertir_nodos([], resultado) do
    resultado
  end

  defp convertir_nodos([{linea, contenido} | resto], resultado) do
    if String.downcase(contenido) == "id,x,y" do
      convertir_nodos(resto, resultado)
    else
      partes = String.split(contenido, ",")

      case partes do
        [id, _x, _y] ->
          convertir_nodos(
            resto,
            [{linea, String.trim(id)} | resultado]
          )

        _ ->
          convertir_nodos(resto, resultado)
      end
    end
  end

  defp convertir_aristas(lineas) do
    convertir_aristas(lineas, [])
  end

  defp convertir_aristas([], resultado) do
    resultado
  end

  defp convertir_aristas([{linea, contenido} | resto], resultado) do
    if String.downcase(contenido) == "nodo_a,nodo_b" do
      convertir_aristas(resto, resultado)
    else
      partes = String.split(contenido, ",")

      case partes do
        [a, b] ->
          convertir_aristas(
            resto,
            [{linea, String.trim(a), String.trim(b)} | resultado]
          )

        _ ->
          convertir_aristas(resto, resultado)
      end
    end
  end

  defp extraer_ids(nodos) do
    extraer_ids(nodos, [])
  end

  defp extraer_ids([], resultado) do
    resultado
  end

  defp extraer_ids([{_linea, id} | resto], resultado) do
    extraer_ids(resto, [id | resultado])
  end

  defp escribir_errores(ruta, errores) do
    File.open!(ruta, [:write], fn archivo ->
      if errores == [] do
        IO.write(archivo, "Red válida. No se encontraron errores.\n")
      else
        escribir_lineas(archivo, errores)
      end
    end)
  end

  defp escribir_lineas(_archivo, []) do
    :ok
  end

  defp escribir_lineas(archivo, [linea | resto]) do
    IO.write(archivo, linea <> "\n")
    escribir_lineas(archivo, resto)
  end

end
