

# Carga los módulos necesarios para leer los archivos
# y generar las coloraciones válidas del grafo.
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

# Módulo encargado de crear una imagen SVG del grafo coloreado.
defmodule GenerarSVG do

  @moduledoc """
  Este módulo genera una representación gráfica de un grafo
  utilizando el formato SVG.

  Lee los nodos y las aristas del grafo, obtiene una coloración
  válida con 10 colores y genera un archivo que muestra los nodos,
  sus colores y las conexiones entre ellos.
  """

  @doc """
  Ejecuta el proceso de generación de la imagen SVG.

  Lee los archivos de nodos y aristas, busca la primera coloración
  válida con 10 colores y genera el archivo SVG.

  Si no encuentra una coloración o falta algún archivo,
  muestra el mensaje correspondiente.
  """
  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")) do

      # Convierte la información de los archivos en datos utilizables.
      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      # Genera las coloraciones posibles y toma únicamente la primera.
      asignacion =
        Coloraciones.generar(
          Enum.map(nodos, fn {id, _x, _y} -> id end),
          aristas,
          10
        )
        |> Enum.take(1)
        |> List.first()

      # Comprueba si se encontró una coloración válida.
      case asignacion do
        nil ->
          IO.puts("No se encontró una coloración válida para k = 10.")

        asignacion ->
          # Si existe una solución, genera el archivo SVG.
          escribir_svg(nodos, aristas, asignacion)
          IO.puts("SVG generado: primera_coloracion_k10.svg")
      end
    else
      # Informa cuando alguno de los archivos de entrada no existe.
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
    end
  end

  # Lee los nodos y obtiene su identificador y sus coordenadas.
  # Cada nodo queda representado mediante una tupla {id, x, y}.
  defp leer_nodos(flujo) do
    flujo
    |> Enum.reject(fn {_linea, contenido} ->
      String.downcase(contenido) == "id,x,y"
    end)
    |> Enum.map(fn {_linea, contenido} ->
      [id, x, y] = String.split(contenido, ",")
      {String.trim(id), String.to_integer(String.trim(x)),
       String.to_integer(String.trim(y))}
    end)
  end

  # Lee las conexiones entre los nodos.
  # Cada arista queda representada mediante una tupla con sus dos extremos.
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

  # Crea el archivo SVG y escribe en él los elementos del grafo.
  # Primero dibuja las conexiones, después los nodos y finalmente
  # cierra la estructura del documento SVG.
  defp escribir_svg(nodos, aristas, asignacion) do
    ruta = Path.join(__DIR__, "primera_coloracion_k10.svg")

    # Abre el archivo en modo escritura, reemplazando su contenido anterior.
    File.open!(ruta, [:write], fn archivo ->

      # Escribe la estructura inicial del documento SVG.
      IO.write(archivo, """
      <svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300">
      <rect width="100%" height="100%" fill="white"/>
      """)

      # Dibuja primero las conexiones entre los nodos.
      escribir_aristas(archivo, aristas, nodos)

      # Dibuja los nodos con los colores de la asignación encontrada.
      escribir_nodos(archivo, nodos, asignacion)

      # Cierra el documento SVG.
      IO.write(archivo, "</svg>\n")
    end)
  end

  # Caso base: cuando no quedan aristas, termina el dibujo de conexiones.
  defp escribir_aristas(_archivo, [], _nodos), do: :ok

  # Dibuja una conexión entre dos nodos.
  # Busca las coordenadas de ambos extremos, escribe una línea SVG
  # y continúa con las demás aristas.
  defp escribir_aristas(archivo, [{a, b} | resto], nodos) do
    {_, x1, y1} = Enum.find(nodos, fn {id, _, _} -> id == a end)
    {_, x2, y2} = Enum.find(nodos, fn {id, _, _} -> id == b end)

    # Escribe una línea que representa la conexión entre los nodos.
    IO.write(
      archivo,
      ~s(<line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="black" stroke-width="2"/>\n)
    )

    # Continúa dibujando las aristas restantes.
    escribir_aristas(archivo, resto, nodos)
  end

  # Caso base: cuando no quedan nodos, termina el dibujo.
  defp escribir_nodos(_archivo, [], _asignacion), do: :ok

  # Dibuja un nodo con su color y su identificador.
  defp escribir_nodos(archivo, [{id, x, y} | resto], asignacion) do

    # Busca el color correspondiente al número asignado al nodo.
    color = color_svg(Map.fetch!(asignacion, id))

    # Dibuja el círculo que representa el nodo.
    IO.write(
      archivo,
      ~s(<circle cx="#{x}" cy="#{y}" r="20" fill="#{color}" stroke="black"/>\n)
    )

    # Escribe el identificador del nodo en el centro del círculo.
    IO.write(
      archivo,
      ~s(<text x="#{x}" y="#{y + 5}" font-size="14" text-anchor="middle" fill="black">#{id}</text>\n)
    )

    # Continúa dibujando los nodos restantes.
    escribir_nodos(archivo, resto, asignacion)
  end

  # Asigna un código de color hexadecimal a cada número de color.
  # Estos valores son utilizados por SVG para mostrar los nodos.
  defp color_svg(1), do: "#ff9999"
  defp color_svg(2), do: "#99ccff"
  defp color_svg(3), do: "#99dd99"
  defp color_svg(4), do: "#ffcc66"
  defp color_svg(5), do: "#cc99ff"
  defp color_svg(6), do: "#66dddd"
  defp color_svg(7), do: "#ff99cc"
  defp color_svg(8), do: "#cccc66"
  defp color_svg(9), do: "#bbbbbb"

  # Utiliza este color cuando el número no coincide con los anteriores.
  defp color_svg(_), do: "#eeeeee"

end

# Ejecuta el proceso de generación del archivo SVG.
GenerarSVG.ejecutar()
