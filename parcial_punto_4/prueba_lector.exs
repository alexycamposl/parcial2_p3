
Code.require_file("lector.exs", __DIR__)

defmodule PruebaLector do

  def ejecutar do
    archivos = [
      "nodos.csv",
      "aristas.csv",
      "colores.txt",
      "propuestas.txt"
    ]

    Enum.each(archivos, fn archivo ->
      IO.puts("\n--- #{archivo} ---")

      case Lector.leer(Path.join(__DIR__, archivo)) do
        {:ok, flujo} ->
          Enum.each(flujo, fn {numero_linea, contenido} ->
            IO.puts("Línea #{numero_linea}: #{contenido}")
          end)

        {:error, {:archivo_no_encontrado, ruta}} ->
          IO.puts("ERROR: no se encontró el archivo #{ruta}")
      end
    end)
  end

end

PruebaLector.ejecutar()
