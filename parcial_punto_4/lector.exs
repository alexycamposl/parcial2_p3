
defmodule Lector do

  def leer(ruta) do
    if File.exists?(ruta) do
      flujo =
        File.stream!(ruta)
        |> Stream.with_index(1)
        |> Stream.map(fn {linea, numero_linea} ->
          {numero_linea, String.trim(linea)}
        end)
        |> Stream.reject(fn {_numero_linea, linea} ->
          linea == "" or String.starts_with?(linea, "#")
        end)

      {:ok, flujo}
    else
      {:error, {:archivo_no_encontrado, ruta}}
    end
  end

end
