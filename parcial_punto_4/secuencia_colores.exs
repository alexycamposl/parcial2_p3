
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

defmodule SecuenciaColores do

  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")) do

      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      secuencia =
        Stream.iterate(1, fn k -> k + 1 end)
        |> Stream.map(fn k ->
          tiene_solucion =
            Coloraciones.generar(nodos, aristas, k)
            |> Enum.take(1)
            |> length()

          {k, tiene_solucion}
        end)

      buscar_primero(secuencia)
    else
      {:error, {:archivo_no_encontrado, ruta}} ->
        IO.puts("ERROR: no se encontró el archivo #{ruta}")
    end
  end

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

  defp buscar_primero(secuencia) do
    {k, _resultado} =
      Enum.find(secuencia, fn {_k, tiene_solucion} ->
        tiene_solucion > 0
      end)

    ruta = Path.join(__DIR__, "secuencia_colores.csv")

    File.open!(ruta, [:write], fn archivo ->
      IO.write(archivo, "k;cantidad_coloraciones\n")
      IO.write(archivo, "#{k};al_menos_1\n")
    end)

    IO.puts("Primer valor de k con solución: #{k}")
    IO.puts("Archivo generado: secuencia_colores.csv")
  end

end

SecuenciaColores.ejecutar()
