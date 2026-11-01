

defmodule Coloraciones do

  # Genera las coloraciones válidas de forma perezosa.
  def generar(nodos, aristas, k) do
    buscar(nodos, aristas, k, %{})
  end

  # Caso base: todos los nodos tienen color.
  defp buscar([], _aristas, _k, asignacion) do
    Stream.map([asignacion], fn solucion -> solucion end)
  end

  # Caso recursivo: toma el siguiente nodo.
  defp buscar([nodo | resto], aristas, k, asignacion) do
    1..k
    |> Stream.flat_map(fn color ->
      nueva_asignacion = Map.put(asignacion, nodo, color)

      if color_valido?(nodo, color, aristas, nueva_asignacion) do
        buscar(resto, aristas, k, nueva_asignacion)
      else
        Stream.concat([])
      end
    end)
  end

  # Comprueba que el nodo no tenga vecinos del mismo color.
  defp color_valido?(nodo, color, aristas, asignacion) do
    Enum.all?(aristas, fn {a, b} ->
      if a == nodo do
        Map.get(asignacion, b) != color
      else
        if b == nodo do
          Map.get(asignacion, a) != color
        else
          true
        end
      end
    end)
  end

end
