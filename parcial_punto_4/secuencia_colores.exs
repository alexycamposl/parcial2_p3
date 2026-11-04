Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

defmodule SecuenciaColores do

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
    end
    IO.puts("Resultado with: #{inspect(result)}")
  end

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

    ruta = Path.join(__DIR__, "secuencia_colores.csv")

    File.open!(ruta, [:write], fn archivo ->
      IO.write(archivo, "k;cantidad_coloraciones\n")
      IO.write(archivo, "#{k};#{total}\n")
    end)

    IO.puts("Primer valor de k con solución: #{k}")
    IO.puts("Total de coloraciones: #{total}")
    IO.puts("Archivo generado: secuencia_colores.csv")
  end

end

SecuenciaColores.run_test()