@echo off
echo "Creando mapa irregular..."
echo A A . B B B > mapa.txt
echo A . . B . >> mapa.txt
echo . . C . . >> mapa.txt
echo C C C . B extra >> mapa.txt
echo C . . B B >> mapa.txt
echo.
echo "Ejecutando MapaRegiones..."
elixir MapaRegiones.exs