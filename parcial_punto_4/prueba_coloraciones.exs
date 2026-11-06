
# Carga el módulo Lector para leer los archivos de entrada.
Code.require_file("lector.exs", __DIR__)

# Carga el módulo Coloraciones para generar las posibles coloraciones del grafo.
Code.require_file("coloraciones.exs", __DIR__)

# Lee los nodos y las aristas desde los archivos.
{:ok, flujo_nodos} = Lector.leer(Path.join(__DIR__, "nodos.csv"))
{:ok, flujo_aristas} = Lector.leer(Path.join(__DIR__, "aristas.csv"))

# Procesa el flujo de nodos para obtener únicamente sus identificadores.
nodos =
  flujo_nodos

  # Elimina la primera línea si corresponde al encabezado del archivo CSV.
  |> Enum.reject(fn {_linea, contenido} ->
    String.downcase(contenido) == "id,x,y"
  end)

  # Separa cada registro por comas y obtiene el identificador del nodo.
  |> Enum.map(fn {_linea, contenido} ->
    contenido
    |> String.split(",")
    |> hd()
    |> String.trim()
  end)

# Procesa el flujo de aristas para obtener las conexiones entre nodos.
aristas =
  flujo_aristas

  # Elimina la primera línea si corresponde al encabezado del archivo CSV.
  |> Enum.reject(fn {_linea, contenido} ->
    String.downcase(contenido) == "nodo_a,nodo_b"
  end)

  # Separa los identificadores de los dos nodos que forman cada arista.
  |> Enum.map(fn {_linea, contenido} ->
    [a, b] = String.split(contenido, ",")
    {String.trim(a), String.trim(b)}
  end)

# Prueba las coloraciones utilizando los valores de k: 1, 2, 3 y 4.
Enum.each([1, 2, 3, 4], fn k ->

  # Genera las coloraciones posibles y cuenta cuántas existen.
  total =
    Coloraciones.generar(nodos, aristas, k)
    |> Enum.count()

  # Muestra en pantalla el total de coloraciones para cada valor de k.
  IO.puts("k = #{k}: #{total} coloraciones")
end)
