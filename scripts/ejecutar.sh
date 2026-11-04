#!/bin/bash
set -e
cd "$(dirname "$0")/.."

echo "💻 1. Copiando datos al contenedor..."
docker cp datos/clima.txt hadoop:/tmp/clima.txt
docker cp datos/clientes.txt hadoop:/tmp/clientes.txt
docker cp datos/pedidos.txt hadoop:/tmp/pedidos.txt

echo "🐳 Limpiando salidas previas..."
docker exec -u root hadoop rm -rf /tmp/salida_sort /tmp/salida_join

echo "🐳 2. Ejecutando Secondary Sort..."
docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop \
  /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  secondarysort /tmp/clima.txt /tmp/salida_sort

echo "🐳 3. Ejecutando Join..."
docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop \
  /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  join -inFormat org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat \
  -outFormat org.apache.hadoop.mapreduce.lib.output.TextOutputFormat \
  -outKey org.apache.hadoop.io.Text \
  /tmp/clientes.txt /tmp/pedidos.txt /tmp/salida_join

echo "💻 4. Extrayendo resultados..."
docker cp hadoop:/tmp/salida_sort/part-r-00000 resultados/resultado_sort.txt
docker cp hadoop:/tmp/salida_join/part-m-00000 resultados/resultado_join.txt

echo "Proceso completado. Resultados obtenidos:"
echo "--- SECONDARY SORT ---"
cat resultados/resultado_sort.txt
echo "--- JOIN ---"
cat resultados/resultado_join.txt
