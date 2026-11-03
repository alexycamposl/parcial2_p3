Code.require_file("lector.exs", __DIR__)

result = Lector.leer("nodos.csv")
IO.inspect(result, label: "Lector result")