
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

defmodule GenerarSVG do

  def ejecutar do
    with {:ok, flujo_nodos} <- Lector.leer(Path.join(__DIR__, "nodos.csv")),
         {:ok, flujo_aristas} <- Lector.leer(Path.join(__DIR__, "aristas.csv")) do

      nodos = leer_nodos(flujo_nodos)
      aristas = leer_aristas(flujo_aristas)

      asignacion =
        Coloraciones.generar(
          Enum.map(nodos, fn {id, _x, _y} -> id end),
          aristas,
          10
        )
        |> Enum.take(1)
        |> List.first()

      case asignacion do
        nil ->
          IO.puts("No se encontró una coloración válida para k = 10.")

        asignacion ->
          escribir_svg(nodos, aristas, asignacion)
          IO.puts("SVG generado: primera_coloracion_k10.svg")
      end
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
      [id, x, y] = String.split(contenido, ",")
      {String.trim(id), String.to_integer(String.trim(x)),
       String.to_integer(String.trim(y))}
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

  defp escribir_svg(nodos, aristas, asignacion) do
    ruta = Path.join(__DIR__, "primera_coloracion_k10.svg")

    File.open!(ruta, [:write], fn archivo ->
      IO.write(archivo, """
      <svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300">
      <rect width="100%" height="100%" fill="white"/>
      """)

      escribir_aristas(archivo, aristas, nodos)
      escribir_nodos(archivo, nodos, asignacion)

      IO.write(archivo, "</svg>\n")
    end)
  end

  defp escribir_aristas(_archivo, [], _nodos), do: :ok

  defp escribir_aristas(archivo, [{a, b} | resto], nodos) do
    {_, x1, y1} = Enum.find(nodos, fn {id, _, _} -> id == a end)
    {_, x2, y2} = Enum.find(nodos, fn {id, _, _} -> id == b end)

    IO.write(
      archivo,
      ~s(<line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="black" stroke-width="2"/>\n)
    )

    escribir_aristas(archivo, resto, nodos)
  end

  defp escribir_nodos(_archivo, [], _asignacion), do: :ok

  defp escribir_nodos(archivo, [{id, x, y} | resto], asignacion) do
    color = color_svg(Map.fetch!(asignacion, id))

    IO.write(
      archivo,
      ~s(<circle cx="#{x}" cy="#{y}" r="20" fill="#{color}" stroke="black"/>\n)
    )

    IO.write(
      archivo,
      ~s(<text x="#{x}" y="#{y + 5}" font-size="14" text-anchor="middle" fill="black">#{id}</text>\n)
    )

    escribir_nodos(archivo, resto, asignacion)
  end

  defp color_svg(1), do: "#ff9999"
  defp color_svg(2), do: "#99ccff"
  defp color_svg(3), do: "#99dd99"
  defp color_svg(4), do: "#ffcc66"
  defp color_svg(5), do: "#cc99ff"
  defp color_svg(6), do: "#66dddd"
  defp color_svg(7), do: "#ff99cc"
  defp color_svg(8), do: "#cccc66"
  defp color_svg(9), do: "#bbbbbb"
  defp color_svg(_), do: "#eeeeee"

end

GenerarSVG.ejecutar()
