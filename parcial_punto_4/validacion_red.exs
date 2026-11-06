Code.require_file("lector.exs", __DIR__)
defmodule ValidacionRed do

  @moduledoc """
  Módulo encargado de validar la estructura de la red o grafo.

  Comprueba que los nodos no estén duplicados y que las
  aristas conecten nodos existentes.

  También detecta bucles y aristas repetidas, teniendo
  en cuenta que el grafo es no dirigido.
  """

  @doc """
  Valida que no existan identificadores de nodos duplicados.

  Recibe una lista de tuplas con el número de línea y el
  identificador de cada nodo.

  Devuelve una lista con los errores encontrados.

  Ejemplo:

      ValidacionRed.validar_nodos([
        {2, "A"},
        {3, "B"},
        {4, "A"}
      ])

  Resultado esperado:

      ["Línea 4: ID de nodo duplicado 'A'."]
  """
  def validar_nodos(nodos) do
    validar_nodos(nodos, [], [])
  end

  # Caso base: termina cuando ya no quedan nodos por revisar.
  defp validar_nodos([], _vistos, errores) do
    errores
  end

  # Revisa si el identificador actual ya fue encontrado.
  defp validar_nodos([{linea, nodo} | resto], vistos, errores) do
    if buscar_id(nodo, vistos) do
      error = "Línea #{linea}: ID de nodo duplicado '#{nodo}'."
      validar_nodos(resto, vistos, [error | errores])
    else
      validar_nodos(resto, [nodo | vistos], errores)
    end
  end

  # Busca recursivamente un identificador en una lista.
  defp buscar_id(_nodo, []) do
    false
  end

  # Caso en el que el identificador coincide.
  defp buscar_id(nodo, [nodo | _resto]) do
    true
  end

  # Continúa buscando en el resto de la lista.
  defp buscar_id(nodo, [_otro | resto]) do
    buscar_id(nodo, resto)
  end


  @doc """
  Valida las aristas del grafo.

  Recibe una lista de aristas y una lista con los
  identificadores de los nodos existentes.

  Comprueba que no haya nodos desconocidos, bucles
  ni aristas repetidas.

  Devuelve una lista con los errores encontrados.

  Ejemplo:

      ValidacionRed.validar_aristas(
        [{5, "A", "Z"}],
        ["A", "B", "C"]
      )

  Resultado esperado:

      ["Línea 5: nodo desconocido 'Z' en arista."]
  """
  def validar_aristas(aristas, nodos) do
    validar_aristas(aristas, nodos, [], [])
  end

  # Caso base: termina cuando se revisaron todas las aristas.
  defp validar_aristas([], _nodos, _vistas, errores) do
    errores
  end

  # Revisa una arista y la agrega a la lista de aristas vistas.
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

  # Reúne los posibles errores de una arista.
  defp errores_arista(linea, nodo_a, nodo_b, nodos, vistas) do

    # Comprueba si los extremos de la arista existen.
    desconocidos =
      errores_nodos_desconocidos(
        linea,
        [nodo_a, nodo_b],
        nodos
      )

    # Detecta si una arista conecta un nodo consigo mismo.
    bucles =
      if nodo_a == nodo_b do
        ["Línea #{linea}: bucle detectado '#{nodo_a},#{nodo_b}'."]
      else
        []
      end

    # Comprueba si la arista ya apareció anteriormente.
    repetidas =
      if buscar_arista(nodo_a, nodo_b, vistas) do
        ["Línea #{linea}: arista repetida '#{nodo_a},#{nodo_b}'."]
      else
        []
      end

    desconocidos ++ bucles ++ repetidas
  end

  # Caso base: ya no quedan nodos por comprobar.
  defp errores_nodos_desconocidos(_linea, [], _nodos) do
    []
  end

  # Comprueba si cada extremo de la arista pertenece al grafo.
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

  # Caso base: no hay más aristas para comparar.
  defp buscar_arista(_a, _b, []) do
    false
  end

  # Comprueba si una arista ya existe, sin importar su dirección.
  # Por ejemplo, A-B y B-A representan la misma arista.
  defp buscar_arista(a, b, [{x, y} | resto]) do
    if (a == x and b == y) or (a == y and b == x) do
      true
    else
      buscar_arista(a, b, resto)
    end
  end


  @doc """
  Ejecuta la validación completa de los archivos del grafo.

  Lee nodos.csv y aristas.csv, convierte su contenido
  en estructuras de datos y ejecuta las validaciones.

  Escribe los errores encontrados en validacion_red.txt.

  Si la red es válida, devuelve:

      {:ok, nodos, aristas}

  Si existen errores, devuelve:

      {:error, errores}
  """
  def validar_archivos do

    # Define las rutas de los archivos de entrada y salida.
    ruta_nodos = Path.join(__DIR__, "nodos.csv")
    ruta_aristas = Path.join(__DIR__, "aristas.csv")
    ruta_salida = Path.join(__DIR__, "validacion_red.txt")

    # Intenta leer los dos archivos requeridos.
    with {:ok, flujo_nodos} <- Lector.leer(ruta_nodos),
         {:ok, flujo_aristas} <- Lector.leer(ruta_aristas) do

      # Consume los flujos para trabajar con sus datos.
      nodos_con_encabezado =
        Enum.to_list(flujo_nodos)

      aristas_con_encabezado =
        Enum.to_list(flujo_aristas)

      # Convierte los registros de texto en listas de datos.
      nodos =
        convertir_nodos(nodos_con_encabezado)

      aristas =
        convertir_aristas(aristas_con_encabezado)

      # Ejecuta la validación de los identificadores.
      errores_nodos = validar_nodos(nodos)

      # Extrae los identificadores para validar las aristas.
      ids =
        extraer_ids(nodos)

      # Ejecuta la validación de las conexiones.
      errores_aristas =
        validar_aristas(aristas, ids)

      # Combina todos los errores encontrados.
      errores =
        errores_nodos ++ errores_aristas

      # Guarda el resultado de la validación en un archivo.
      escribir_errores(ruta_salida, errores)

      if errores == [] do
        IO.puts("Red válida. No se encontraron errores.")
        {:ok, nodos, aristas}
      else
        IO.puts("Red inválida. Se encontraron #{length(errores)} errores.")
        {:error, errores}
      end

    else
      # Informa si falta alguno de los archivos de entrada.
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("No se encontró el archivo requerido: #{ruta}")
        {:error, {:archivo_no_encontrado, ruta}}
    end
  end

  # Inicia la conversión de los registros de nodos.
  defp convertir_nodos(lineas) do
    convertir_nodos(lineas, [])
  end

  # Caso base: devuelve los nodos convertidos.
  defp convertir_nodos([], resultado) do
    resultado
  end

  # Convierte cada registro de texto en una tupla.
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

  # Inicia la conversión de los registros de aristas.
  defp convertir_aristas(lineas) do
    convertir_aristas(lineas, [])
  end

  # Caso base: devuelve las aristas convertidas.
  defp convertir_aristas([], resultado) do
    resultado
  end

  # Convierte cada registro de texto en una tupla de aristas.
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

  # Inicia la extracción de los identificadores de los nodos.
  defp extraer_ids(nodos) do
    extraer_ids(nodos, [])
  end

  # Caso base: devuelve la lista de identificadores.
  defp extraer_ids([], resultado) do
    resultado
  end

  # Extrae el identificador de cada nodo.
  defp extraer_ids([{_linea, id} | resto], resultado) do
    extraer_ids(resto, [id | resultado])
  end

  # Crea el archivo de salida y escribe los errores.
  defp escribir_errores(ruta, errores) do
    File.open!(ruta, [:write], fn archivo ->
      if errores == [] do
        IO.write(archivo, "Red válida. No se encontraron errores.\n")
      else
        escribir_lineas(archivo, errores)
      end
    end)
  end

  # Caso base: termina cuando no quedan errores por escribir.
  defp escribir_lineas(_archivo, []) do
    :ok
  end

  # Escribe cada error en una línea del archivo.
  defp escribir_lineas(archivo, [linea | resto]) do
    IO.write(archivo, linea <> "\n")
    escribir_lineas(archivo, resto)
  end

end
