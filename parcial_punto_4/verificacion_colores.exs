
Code.require_file("lector.exs", __DIR__)

defmodule VerificacionColores do

  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")),
         {:ok, flujo_propuestas} <- Lector.leer(Path.join(__DIR__, "propuestas.txt")) do

      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      ruta_salida = Path.join(__DIR__, "verificacion_colores.txt")

      File.open!(ruta_salida, [:write], fn archivo ->
        verificar_propuestas(
          flujo_propuestas,
          nodos,
          aristas,
          archivo
        )
      end)

      IO.puts("Verificación terminada. Revisa verificacion_colores.txt.")
    else
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
    end
  end

  # Lectura de los nodos y sus identificadores.
  defp leer_nodos(flujo) do
    flujo
    |> Enum.reject(fn {_linea, contenido} ->
      String.downcase(contenido) == "id,x,y"
    end)
    |> Enum.map(fn {_linea, contenido} ->
      contenido
      |> String.split(",")
      |> hd()
      |> String.trim()
    end)
  end

  # Lectura de las aristas.
  defp leer_aristas(flujo) do
    flujo
    |> Enum.reject(fn {_linea, contenido} ->
      String.downcase(contenido) == "nodo_a,nodo_b"
    end)
    |> Enum.map(fn {_linea, contenido} ->
      [a, b] = String.split(contenido, ",")
      {String.trim(a), String.trim(b)}
    end)
  end

  # Recorre cada propuesta y escribe el resultado inmediatamente.
  defp verificar_propuestas(flujo, nodos, aristas, archivo) do
    Enum.each(flujo, fn {linea, contenido} ->
      case analizar_propuesta(contenido) do
        {:ok, k, asignacion} ->
          errores =
            validar_asignacion(nodos, aristas, k, asignacion)

          if errores == [] do
            IO.write(archivo, "Línea #{linea}: PROPUESTA VÁLIDA\n")
          else
            IO.write(archivo, "Línea #{linea}: PROPUESTA INVÁLIDA\n")
            escribir_errores(archivo, errores)
          end

        {:error, motivo} ->
          IO.write(
            archivo,
            "Línea #{linea}: PROPUESTA INVÁLIDA - #{motivo}\n"
          )
      end
    end)
  end

  # Separa k de las asignaciones nodo=color.
  defp analizar_propuesta(contenido) do
    partes = String.split(contenido, ";")

    case partes do
      [texto_k | asignaciones] ->
        case Integer.parse(String.trim(texto_k)) do
          {k, ""} when k > 0 ->
            convertir_asignaciones(asignaciones, k, %{})

          _ ->
            {:error, "el número de colores k debe ser un entero positivo"}
        end

      _ ->
        {:error, "formato de propuesta incorrecto"}
    end
  end

  defp convertir_asignaciones([], k, asignacion) do
    {:ok, k, asignacion}
  end

  defp convertir_asignaciones([texto | resto], k, asignacion) do
    case String.split(texto, "=") do
      [nodo, texto_color] ->
        nodo = String.trim(nodo)

        case Integer.parse(String.trim(texto_color)) do
          {color, ""} ->
            if Map.has_key?(asignacion, nodo) do
              {:error, "el nodo '#{nodo}' aparece más de una vez"}
            else
              convertir_asignaciones(
                resto,
                k,
                Map.put(asignacion, nodo, color)
              )
            end

          _ ->
            {:error, "color no entero para el nodo '#{nodo}'"}
        end

      _ ->
        {:error, "asignación incorrecta: '#{texto}'"}
    end
  end

  # Combina todos los errores encontrados.
  defp validar_asignacion(nodos, aristas, k, asignacion) do
    errores_nodos = validar_nodos_propuesta(nodos, asignacion)
    errores_colores = validar_rango_colores(nodos, k, asignacion)
    errores_aristas = validar_aristas(aristas, asignacion)

    errores_nodos ++ errores_colores ++ errores_aristas
  end

  # Detecta nodos faltantes y nodos que no pertenecen al grafo.
  defp validar_nodos_propuesta(nodos, asignacion) do
    faltantes = buscar_faltantes(nodos, asignacion, [])
    adicionales = buscar_adicionales(Map.keys(asignacion), nodos, [])

    faltantes ++ adicionales
  end

  defp buscar_faltantes([], _asignacion, errores), do: errores

  defp buscar_faltantes([nodo | resto], asignacion, errores) do
    if Map.has_key?(asignacion, nodo) do
      buscar_faltantes(resto, asignacion, errores)
    else
      buscar_faltantes(
        resto,
        asignacion,
        ["Falta asignar un color al nodo '#{nodo}'." | errores]
      )
    end
  end

  defp buscar_adicionales([], _nodos, errores), do: errores

  defp buscar_adicionales([nodo | resto], nodos, errores) do
    if Enum.member?(nodos, nodo) do
      buscar_adicionales(resto, nodos, errores)
    else
      buscar_adicionales(
        resto,
        nodos,
        ["El nodo '#{nodo}' no pertenece al grafo." | errores]
      )
    end
  end

  # Cada color debe estar entre 1 y k.
  defp validar_rango_colores(nodos, k, asignacion) do
    validar_rango_colores(nodos, k, asignacion, [])
  end

  defp validar_rango_colores([], _k, _asignacion, errores), do: errores

  defp validar_rango_colores([nodo | resto], k, asignacion, errores) do
    case Map.fetch(asignacion, nodo) do
      {:ok, color} when color >= 1 and color <= k ->
        validar_rango_colores(resto, k, asignacion, errores)

      {:ok, color} ->
        validar_rango_colores(
          resto,
          k,
          asignacion,
          ["Color #{color} fuera del rango 1..#{k} para '#{nodo}'." | errores]
        )

      :error ->
        validar_rango_colores(resto, k, asignacion, errores)
    end
  end

  # Comprueba que los extremos de cada arista tengan colores diferentes.
  defp validar_aristas(aristas, asignacion) do
    validar_aristas(aristas, asignacion, [])
  end

  defp validar_aristas([], _asignacion, errores), do: errores

  defp validar_aristas([{a, b} | resto], asignacion, errores) do
    conflicto =
      case {Map.fetch(asignacion, a), Map.fetch(asignacion, b)} do
        {{:ok, color_a}, {:ok, color_b}} when color_a == color_b ->
          ["Conflicto: '#{a}' y '#{b}' tienen el mismo color #{color_a}."]
        _ ->
          []
      end

    validar_aristas(resto, asignacion, errores ++ conflicto)
  end

  defp escribir_errores(_archivo, []), do: :ok

  defp escribir_errores(archivo, [error | resto]) do
    IO.write(archivo, "  - #{error}\n")
    escribir_errores(archivo, resto)
  end

end

VerificacionColores.ejecutar()
