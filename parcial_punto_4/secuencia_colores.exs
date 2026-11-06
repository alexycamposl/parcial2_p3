<<<<<<< HEAD
=======


# Carga los módulos necesarios para leer los archivos
# y generar las coloraciones válidas del grafo.
>>>>>>> 150e73e (se documenta  y actualiza el segundo punto del taller)
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

# Módulo encargado de encontrar el primer número de colores
# con el que se puede realizar una coloración válida del grafo.
defmodule SecuenciaColores do

<<<<<<< HEAD
  def run_test do
    IO.puts("=== DENTRO DEL TEST ===")
    result = with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
                  {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")) do

      IO.puts("Lectura exitosa")
      # Filtrar encabezados y convertir a lista
      nodos = flujo_nodos
      |> Enum.reject(fn {_linea, contenido} -> String.downcase(contenido) == "id,x,y" end)
      |> Enum.map(fn {_linea, contenido} -> contenido |> String.split(",") |> hd() |> String.trim() end)
      |> Enum.to_list()

      aristas = flujo_aristas
      |> Enum.reject(fn {_linea, contenido} -> String.downcase(contenido) == "nodo_a,nodo_b" end)
      |> Enum.map(fn {_linea, contenido} -> [a, b] = String.split(contenido, ","); {String.trim(a), String.trim(b)} end)
      |> Enum.to_list()

      IO.puts("Nodos: #{length(nodos)}")
      IO.puts("Aristas: #{length(aristas)}")

      # Stream infinito que genera {k, total_de_coloraciones} de forma perezosa
      secuencia =
        Stream.iterate(1, fn k -> k + 1 end)
        |> Stream.map(fn k -> {k, contar_coloraciones(nodos, aristas, k)} end)

      consumir_secuencia(secuencia)
=======
  @moduledoc """
  Este módulo busca el menor número de colores que permite
  obtener al menos una coloración válida para un grafo.

  Lee los nodos y las aristas desde sus archivos de entrada,
  genera una secuencia creciente de cantidades de colores
  y se detiene cuando encuentra una solución.

  Finalmente, guarda el resultado en secuencia_colores.csv.
  """

  @doc """
  Ejecuta el proceso de búsqueda del primer número de colores.

  Lee los nodos y las aristas, genera una secuencia de valores
  de k y busca el primero que permita obtener una solución.

  Si alguno de los archivos no existe, muestra un mensaje de error.
  """
  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")) do

      # Obtiene los identificadores de los nodos y las conexiones.
      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      # Genera una secuencia perezosa que comienza en 1
      # y aumenta de uno en uno.
      secuencia =
        Stream.iterate(1, fn k -> k + 1 end)
        |> Stream.map(fn k ->

          # Comprueba si existe al menos una coloración válida
          # utilizando la cantidad de colores indicada por k.
          tiene_solucion =
            Coloraciones.generar(nodos, aristas, k)
            |> Enum.take(1)
            |> length()

          # Devuelve el número de colores y el resultado de la búsqueda.
          {k, tiene_solucion}
        end)

      # Busca el primer valor de k que tenga una solución.
      buscar_primero(secuencia)
    else
      # Muestra un mensaje cuando no se encuentra algún archivo.
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
>>>>>>> 150e73e (se documenta  y actualiza el segundo punto del taller)
    end
    IO.puts("Resultado with: #{inspect(result)}")
  end

<<<<<<< HEAD
  # Conta TODAS las coloraciones válidas para un valor de k dado
  defp contar_coloraciones(nodos, aristas, k) do
    result = Enum.count(Coloraciones.generar(nodos, aristas, k))
    IO.puts("Contando k=#{k}: #{result} coloraciones")
    result
  end

  defp consumir_secuencia(secuencia) do
    IO.puts("Consumiendo secuencia...")
    {k, total} = Enum.find(secuencia, fn {_k, total} -> total > 0 end)
    IO.puts("Encontrado: k=#{k}, total=#{total}")
=======
  # Lee los identificadores de los nodos.
  # Elimina el encabezado y extrae el primer dato de cada línea.
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

  # Lee las conexiones existentes entre los nodos.
  # Cada conexión se convierte en una tupla con sus dos extremos.
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

  # Busca el primer número de colores que permite obtener
  # al menos una coloración válida.
  defp buscar_primero(secuencia) do

    # Recorre la secuencia hasta encontrar una solución.
    # Enum.find se detiene cuando se cumple la condición.
    {k, _resultado} =
      Enum.find(secuencia, fn {_k, tiene_solucion} ->
        tiene_solucion > 0
      end)
>>>>>>> 150e73e (se documenta  y actualiza el segundo punto del taller)

    # Define la ubicación del archivo donde se guardará el resultado.
    ruta = Path.join(__DIR__, "secuencia_colores.csv")

    # Crea el archivo y escribe el encabezado y el primer valor encontrado.
    File.open!(ruta, [:write], fn archivo ->
      IO.write(archivo, "k;cantidad_coloraciones\n")
      IO.write(archivo, "#{k};#{total}\n")
    end)

    # Muestra el resultado de la búsqueda en pantalla.
    IO.puts("Primer valor de k con solución: #{k}")
    IO.puts("Total de coloraciones: #{total}")
    IO.puts("Archivo generado: secuencia_colores.csv")
  end

end

<<<<<<< HEAD
SecuenciaColores.run_test()
=======
# Ejecuta la búsqueda del primer número de colores con solución.
SecuenciaColores.ejecutar()
>>>>>>> 150e73e (se documenta  y actualiza el segundo punto del taller)
