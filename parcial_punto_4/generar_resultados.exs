

# Carga los archivos que contienen las funciones para leer datos
# y generar las coloraciones del grafo.
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

# Módulo encargado de generar los archivos con todas las
# coloraciones válidas para cada cantidad de colores.
defmodule GenerarResultados do

  @moduledoc """
  Este módulo genera archivos de texto con las coloraciones válidas
  de un grafo para diferentes cantidades de colores.

  Lee los nodos, las aristas y las cantidades de colores desde
  los archivos de entrada. Después utiliza el módulo Coloraciones
  para encontrar las soluciones y guardarlas en archivos separados.
  """

  @doc """
  Ejecuta el proceso completo de generación de resultados.

  Lee los archivos nodos.csv, aristas.csv y colores.txt.
  Si todos existen, procesa su información y genera los archivos
  con las coloraciones válidas.

  Si alguno no existe, muestra un mensaje de error.
  """
  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")),
         {:ok, flujo_colores} <- Lector.leer(Path.join(__DIR__, "colores.txt")) do

      # Convierte la información de cada archivo en datos utilizables.
      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)
      colores = leer_colores(flujo_colores)

      # Genera un archivo de resultados para cada cantidad de colores.
      generar_archivos(nodos, aristas, colores)
    else
      # Se ejecuta cuando no se encuentra alguno de los archivos.
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
    end
  end

  # Obtiene los identificadores de los nodos.
  # Primero elimina la fila del encabezado y después toma el primer
  # dato de cada línea, que corresponde al identificador del nodo.
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

  # Obtiene las conexiones existentes entre los nodos.
  # Elimina el encabezado y convierte cada conexión en una tupla
  # formada por los dos nodos que están conectados.
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

  # Obtiene las cantidades de colores que se van a evaluar.
  # Convierte cada línea del archivo en un número entero.
  defp leer_colores(flujo) do
    flujo
    |> Enum.map(fn {_linea, contenido} -> String.to_integer(contenido) end)
  end

  # Genera un archivo de texto por cada cantidad de colores.
  # Por ejemplo, para k = 3 crea el archivo coloraciones_k3.txt.
  defp generar_archivos(nodos, aristas, colores) do
    Enum.each(colores, fn k ->
      ruta = Path.join(__DIR__, "coloraciones_k#{k}.txt")

      # Abre el archivo en modo escritura y guarda las soluciones.
      # El modo :write reemplaza el contenido anterior del archivo.
      total =
        File.open!(ruta, [:write], fn archivo ->
          cantidad =
            escribir_coloraciones(
              Coloraciones.generar(nodos, aristas, k),
              archivo,
              1,
              nodos
            )

          # Escribe al final del archivo la cantidad total encontrada.
          IO.write(archivo, "\nTotal de coloraciones: #{cantidad}\n")
          cantidad
        end)

      # Muestra en pantalla el resultado de cada cantidad de colores.
      IO.puts(
        "k = #{k}: #{total} coloraciones. Archivo: coloraciones_k#{k}.txt"
      )
    end)
  end

  # Recorre las coloraciones generadas y las escribe en el archivo.
  # También lleva el conteo de las soluciones encontradas.
  defp escribir_coloraciones(flujo, archivo, numero, nodos) do
    Enum.reduce(flujo, 0, fn asignacion, total ->

      # Organiza los colores siguiendo el mismo orden de los nodos
      # que aparece en el archivo nodos.csv.
      contenido =
        nodos
        |> Enum.map(fn nodo ->
          "#{nodo}=#{Map.fetch!(asignacion, nodo)}"
        end)
        |> Enum.join(";")

      # Escribe cada solución con su número correspondiente.
      IO.write(archivo, "#{numero + total}. #{contenido}\n")

      # Aumenta en uno el contador de soluciones.
      total + 1
    end)
  end

end

# Llama a la función principal para iniciar la generación de resultados.
GenerarResultados.ejecutar()
