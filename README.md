# Equipo 9 - Retos Avanzados: Secondary Sort y Join

## 1. Integrantes
* Marco Antonio Galicia Flores
* Felipe Jose Gonzalez Navarrete
* Daniel Croche Soto
* Josue SIfuentes Valdez

## 2. Descripción y Caso de Uso Real
* **Secondary Sort:** Ordena los valores asociados a una llave durante la fase de *Shuffle & Sort*. **Caso de uso:** Análisis de datos climáticos donde necesitamos agrupar por año y, dentro de cada año, ordenar las temperaturas de menor a mayor.
* **Join:** Cruza múltiples conjuntos de datos basándose en una llave común. **Caso de uso:** Unir una tabla de clientes con una tabla de pedidos para saber qué compró cada persona (como un INNER JOIN).

## 3. Requisitos
* Contenedor de Docker con **Hadoop 3.3.6** funcionando.
* Los datos de entrada requieren el uso estricto de tabuladores (`\t`) como separador.

## 4. Guía Paso a Paso
Genera los archivos de datos en tu computadora con tabuladores:
💻 `printf "2023\t35\n2023\t31\n2023\t38\n2022\t28\n2022\t34\n" > datos/clima.txt`
💻 `printf "1\tMarco\n2\tFelipe\n3\tJosue\n" > datos/clientes.txt`
💻 `printf "1\tLaptop\n1\tMouse\n3\tTeclado\n" > datos/pedidos.txt`

Copia los datos al contenedor:
💻 `docker cp datos/clima.txt hadoop:/tmp/clima.txt`
💻 `docker cp datos/clientes.txt hadoop:/tmp/clientes.txt`
💻 `docker cp datos/pedidos.txt hadoop:/tmp/pedidos.txt`

Limpia salidas previas (opcional pero recomendado):
🐳 `docker exec -u root hadoop rm -rf /tmp/salida_sort /tmp/salida_join`

Ejecuta los algoritmos dentro de Hadoop:
🐳 `docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar secondarysort /tmp/clima.txt /tmp/salida_sort`

🐳 `docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar join -inFormat org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat -outFormat org.apache.hadoop.mapreduce.lib.output.TextOutputFormat -outKey org.apache.hadoop.io.Text /tmp/clientes.txt /tmp/pedidos.txt /tmp/salida_join`

Extrae los resultados a tu computadora:
💻 `docker cp hadoop:/tmp/salida_sort/part-r-00000 resultados/resultado_sort.txt`
💻 `docker cp hadoop:/tmp/salida_join/part-m-00000 resultados/resultado_join.txt`

## 5. Resultado Esperado
Al ejecutar un `cat` de los resultados, deberías ver las temperaturas ordenadas por año y las compras cruzadas y asociadas a cada cliente.

## 6. Explicación de Map y Reduce
* **Secondary Sort:** El *Map* emite una llave compuesta `[Año, Temperatura]`. El framework agrupa por Año, pero ordena por la llave completa. El *Reduce* recibe la llave y los valores ya ordenados listos para iterar.
* **Join:** El algoritmo lee de ambos archivos usando el ID como llave. Como es un *Map-side join*, cruza los datos coincidentes durante el mapeo sin requerir fase *Reduce*.

## 7. Errores Comunes y Soluciones
* **Error:** `JAVA_HOME is not set`. **Solución:** Pasar explícitamente `-e JAVA_HOME=/usr/lib/jvm/...` en el comando `docker exec`.
* **Error:** El `join` no procesa los datos. **Solución:** Requiere columnas separadas por un tabulador real (`\t`) y especificar explícitamente `-inFormat KeyValueTextInputFormat`.
* **Error:** `Could not find the file /part-r-00000`. **Solución:** El ejemplo de Join no usa Reducers, por lo que el archivo de salida termina en `part-m-00000`.
