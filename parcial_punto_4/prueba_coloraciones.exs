
Code.require_file("lector.exs", __DIR__)
Code.require_file("coloraciones.exs", __DIR__)

# Lee los nodos y las aristas desde los archivos.
{:ok, flujo_nodos} = Lector.leer(Path.join(__DIR__, "nodos.csv"))
{:ok, flujo_aristas} = Lector.leer(Path.join(__DIR__, "aristas.csv"))

nodos =
  flujo_nodos
  |> Enum.reject(fn {_linea, contenido} ->
    String.downcase(contenido) == "id,x,y"
  end)
  |> Enum.map(fn {_linea, contenido} ->
    contenido
    |> String.split(",")
    |> hd()
    |> String.trim()
  end)

aristas =
  flujo_aristas
  |> Enum.reject(fn {_linea, contenido} ->
    String.downcase(contenido) == "nodo_a,nodo_b"
  end)
  |> Enum.map(fn {_linea, contenido} ->
    [a, b] = String.split(contenido, ",")
    {String.trim(a), String.trim(b)}
  end)

# Prueba k = 1, 2, 3 y 4.
Enum.each([1, 2, 3, 4], fn k ->
  total =
    Coloraciones.generar(nodos, aristas, k)
    |> Enum.count()

  IO.puts("k = #{k}: #{total} coloraciones")
end)
