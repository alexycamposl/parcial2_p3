
# Carga el módulo encargado de leer los archivos de entrada.
Code.require_file("lector.exs", __DIR__)

# Módulo encargado de verificar las propuestas de coloración
# y determinar si cumplen las reglas del problema.
defmodule VerificacionColores do

  @moduledoc """
  Este módulo verifica las propuestas de coloración de un grafo.

  Comprueba que todos los nodos tengan un color, que los colores
  estén dentro del rango permitido y que dos nodos conectados
  no tengan el mismo color.

  Los resultados de la verificación se guardan en un archivo
  de texto llamado verificacion_colores.txt.
  """

  @doc """
  Ejecuta el proceso de verificación de las propuestas.

  Lee los nodos, las aristas y las propuestas desde sus archivos.
  Después verifica cada propuesta y guarda los resultados.

  Si alguno de los archivos no existe, muestra un mensaje de error.
  """
  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")),
         {:ok, flujo_propuestas} <- Lector.leer(Path.join(__DIR__, "propuestas.txt")) do

      # Convierte los datos de los archivos en nodos y aristas.
      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      # Define la ubicación del archivo donde se guardarán los resultados.
      ruta_salida = Path.join(__DIR__, "verificacion_colores.txt")

      # Abre el archivo en modo escritura y realiza las verificaciones.
      File.open!(ruta_salida, [:write], fn archivo ->
        verificar_propuestas(
          flujo_propuestas,
          nodos,
          aristas,
          archivo
        )
      end)

      # Informa que el proceso terminó correctamente.
      IO.puts("Verificación terminada. Revisa verificacion_colores.txt.")
    else
      # Muestra un mensaje cuando no se encuentra algún archivo.
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
    end
  end


  #Obtiene los identificadores de los nodos del grafo.

  #Elimina el encabezado del archivo y extrae el identificador
  #de cada nodo.

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


  #Obtiene las conexiones entre los nodos.

  #Elimina el encabezado y convierte cada conexión en una tupla
  #que contiene los dos nodos conectados.

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

  # Recorre todas las propuestas del archivo.
  # Analiza cada una, verifica sus asignaciones y escribe el resultado.
  defp verificar_propuestas(flujo, nodos, aristas, archivo) do
    Enum.each(flujo, fn {linea, contenido} ->
      case analizar_propuesta(contenido) do
        {:ok, k, asignacion} ->

          # Comprueba si la asignación cumple todas las reglas.
          errores =
            validar_asignacion(nodos, aristas, k, asignacion)

          # Si no hay errores, la propuesta es válida.
          if errores == [] do
            IO.write(archivo, "Línea #{linea}: PROPUESTA VÁLIDA\n")
          else
            # Si hay errores, informa que la propuesta es inválida
            # y escribe los motivos encontrados.
            IO.write(archivo, "Línea #{linea}: PROPUESTA INVÁLIDA\n")
            escribir_errores(archivo, errores)
          end

        {:error, motivo} ->
          # Informa cuando la propuesta tiene un formato incorrecto.
          IO.write(
            archivo,
            "Línea #{linea}: PROPUESTA INVÁLIDA - #{motivo}\n"
          )
      end
    end)
  end

  # Separa la cantidad de colores k de las asignaciones de los nodos.
  # El formato esperado es: k;nodo=color;nodo=color.
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

  # Caso base de la conversión.
  # Cuando no quedan asignaciones por procesar, devuelve el resultado.
  defp convertir_asignaciones([], k, asignacion) do
    {:ok, k, asignacion}
  end

  # Procesa cada asignación de nodo y color.
  # Comprueba que el formato sea correcto y que el nodo no esté repetido.
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

  # Ejecuta las diferentes validaciones de una propuesta.
  # Combina los errores encontrados en una sola lista.
  defp validar_asignacion(nodos, aristas, k, asignacion) do
    errores_nodos = validar_nodos_propuesta(nodos, asignacion)
    errores_colores = validar_rango_colores(nodos, k, asignacion)
    errores_aristas = validar_aristas(aristas, asignacion)

    errores_nodos ++ errores_colores ++ errores_aristas
  end

  # Comprueba que no falten nodos y que no existan nodos adicionales.
  defp validar_nodos_propuesta(nodos, asignacion) do
    faltantes = buscar_faltantes(nodos, asignacion, [])
    adicionales = buscar_adicionales(Map.keys(asignacion), nodos, [])

    faltantes ++ adicionales
  end

  # Caso base: termina cuando ya no quedan nodos por revisar.
  defp buscar_faltantes([], _asignacion, errores), do: errores

  # Busca los nodos del grafo que no recibieron un color.
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

  # Caso base: termina cuando ya no quedan nodos adicionales por revisar.
  defp buscar_adicionales([], _nodos, errores), do: errores

  # Comprueba que cada nodo de la propuesta pertenezca al grafo.
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

  # Comprueba que cada color esté dentro del rango permitido: 1 hasta k.
  defp validar_rango_colores(nodos, k, asignacion) do
    validar_rango_colores(nodos, k, asignacion, [])
  end

  # Caso base: termina cuando todos los nodos han sido revisados.
  defp validar_rango_colores([], _k, _asignacion, errores), do: errores

  # Revisa el color asignado a cada nodo.
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

  # Comprueba que los nodos conectados por una arista
  # tengan colores diferentes.
  defp validar_aristas(aristas, asignacion) do
    validar_aristas(aristas, asignacion, [])
  end

  # Caso base: termina cuando ya no quedan aristas por revisar.
  defp validar_aristas([], _asignacion, errores), do: errores

  # Revisa cada arista y detecta si sus dos extremos tienen el mismo color.
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

  # Caso base: no quedan errores por escribir.
  defp escribir_errores(_archivo, []), do: :ok

  # Escribe cada error encontrado en el archivo de resultados.
  defp escribir_errores(archivo, [error | resto]) do
    IO.write(archivo, "  - #{error}\n")
    escribir_errores(archivo, resto)
  end

end

# Ejecuta la verificación de las propuestas al iniciar el archivo.
VerificacionColores.ejecutar()
