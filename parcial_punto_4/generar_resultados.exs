
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

defmodule GenerarResultados do

  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")),
         {:ok, flujo_colores} <- Lector.leer(Path.join(__DIR__, "colores.txt")) do

      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)
      colores = leer_colores(flujo_colores)

      generar_archivos(nodos, aristas, colores)
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

  defp leer_colores(flujo) do
    flujo
    |> Enum.map(fn {_linea, contenido} -> String.to_integer(contenido) end)
  end


defp generar_archivos(nodos, aristas, colores) do
  Enum.each(colores, fn k ->
    ruta = Path.join(__DIR__, "coloraciones_k#{k}.txt")

    total =
      File.open!(ruta, [:write], fn archivo ->
        cantidad =
          escribir_coloraciones(
            Coloraciones.generar(nodos, aristas, k),
            archivo,
            1,
            nodos
          )

        IO.write(archivo, "\nTotal de coloraciones: #{cantidad}\n")
        cantidad
      end)

    IO.puts(
      "k = #{k}: #{total} coloraciones. Archivo: coloraciones_k#{k}.txt"
    )
  end)
end



defp escribir_coloraciones(flujo, archivo, numero, nodos) do
  Enum.reduce(flujo, 0, fn asignacion, total ->
    contenido =
      nodos
      |> Enum.map(fn nodo ->
        "#{nodo}=#{Map.fetch!(asignacion, nodo)}"
      end)
      |> Enum.join(";")

    IO.write(archivo, "#{numero + total}. #{contenido}\n")
    total + 1
  end)
end


end

GenerarResultados.ejecutar()
