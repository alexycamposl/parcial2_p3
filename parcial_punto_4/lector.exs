
defmodule Lector do

  @moduledoc """
  Módulo encargado de leer archivos de texto de forma perezosa.

  Permite recorrer un archivo línea por línea, conservando el número
  de línea original y descartando las líneas vacías o los comentarios
  que comienzan con el símbolo #.
  """

  @doc """
  Lee un archivo y devuelve un flujo (Stream) con sus líneas válidas.

  Recibe:
    - ruta: ubicación del archivo que se desea leer.

  Retorna:
    - {:ok, flujo}: si el archivo existe y puede prepararse para su lectura.
    - {:error, {:archivo_no_encontrado, ruta}}: si el archivo no existe.
  """
  def leer(ruta) do
    # Comprueba que el archivo exista antes de intentar leerlo.
    if File.exists?(ruta) do

      # Crea un flujo para procesar el archivo línea por línea,
      # sin cargar todo su contenido en memoria.
      flujo =
        File.stream!(ruta)

        # Asigna a cada línea su número original, comenzando desde 1.
        |> Stream.with_index(1)

        # Elimina los espacios y saltos de línea sobrantes.
        |> Stream.map(fn {linea, numero_linea} ->
          {numero_linea, String.trim(linea)}
        end)

        # Descarta las líneas vacías y las que comienzan con #.
        # Conserva el número de línea de las demás.
        |> Stream.reject(fn {_numero_linea, linea} ->
          linea == "" or String.starts_with?(linea, "#")
        end)

      # Devuelve el flujo preparado para que otro módulo lo recorra.
      {:ok, flujo}

    else
      # Informa que el archivo solicitado no existe.
      {:error, {:archivo_no_encontrado, ruta}}
    end
  end

end
