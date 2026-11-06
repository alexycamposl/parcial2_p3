
# Carga el módulo Lector para poder utilizar la función leer/1.
Code.require_file("lector.exs", __DIR__)

defmodule PruebaLector do

  @moduledoc """
  Módulo encargado de probar el funcionamiento del módulo Lector.

  Recorre varios archivos de entrada, muestra sus líneas válidas
  y permite comprobar el manejo de archivos que no existen.
  """

  @doc """
  Ejecuta las pruebas de lectura sobre los archivos del proyecto.

  Para cada archivo:
  - Muestra su nombre.
  - Intenta leerlo utilizando Lector.leer/1.
  - Imprime el número de línea y su contenido.
  - Informa si el archivo no fue encontrado.
  """
  def ejecutar do

    # Lista de archivos que se van a utilizar en la prueba.
    archivos = [
      "nodos.csv",
      "aristas.csv",
      "colores.txt",
      "propuestas.txt"
    ]

    # Recorre cada archivo de la lista para probar su lectura.
    Enum.each(archivos, fn archivo ->

      # Muestra el nombre del archivo que se está procesando.
      IO.puts("\n--- #{archivo} ---")

      # Construye la ruta del archivo y llama al módulo Lector.
      case Lector.leer(Path.join(__DIR__, archivo)) do

        # Si la lectura fue correcta, recorre el flujo recibido.
        {:ok, flujo} ->

          # Muestra el número de línea original y su contenido.
          Enum.each(flujo, fn {numero_linea, contenido} ->
            IO.puts("Línea #{numero_linea}: #{contenido}")
          end)

        # Si el archivo no existe, muestra un mensaje de error.
        {:error, {:archivo_no_encontrado, ruta}} ->
          IO.puts("ERROR: no se encontró el archivo #{ruta}")
      end
    end)
  end

end

# Llama a la función ejecutar/0 para iniciar las pruebas.
PruebaLector.ejecutar()

