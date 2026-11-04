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
  -Creacion del contenedor:
    docker run -it --name hadoop -p 9870:9870 \
    -p 9000:9000 --hostname hadoop debian:12 bash
  -Denro del contenedor poner:
    apt update -y
    apt upgrade -y
    apt install -y openssh-server wget sudo vim nano net-tools curl
  -Instalar hadoop
   -Nos movemos de carpeta
    cd /opt
   -Descargamos hadoop comprimido
    wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
   -Descomprimos el hadoop
    tar -zxvf hadoop-3.3.6.tar.gz
   -Creamos el enlace simbolico
    ln -s hadoop-3.3.6 hadoop
* Los datos de entrada requieren el uso estricto de tabuladores (`\t`) como separador.

## 4. Guía Paso a Paso

Para reproducir esta práctica, ejecuta los siguientes comandos en orden. Las instrucciones utilizan los emojis acordados: 💻 indica un comando ejecutado en la terminal de tu computadora anfitriona y 🐳 indica un comando ejecutado dentro del contenedor de Hadoop.

**4.1 Generar los archivos de datos en tu computadora**
Es indispensable utilizar `printf` en lugar de crear los archivos a mano para garantizar que las columnas estén separadas por tabuladores reales (`\t`), un requisito estricto del algoritmo `join`.

```bash
# 💻 En tu computadora
printf "2023\t35\n2023\t31\n2023\t38\n2022\t28\n2022\t34\n" > datos/clima.txt
printf "1\tMarco\n2\tFelipe\n3\tJosue\n" > datos/clientes.txt
printf "1\tLaptop\n1\tMouse\n3\tTeclado\n" > datos/pedidos.txt

```

**4.2 Copiar los datos al contenedor**

```bash
# 💻 En tu computadora
docker cp datos/clima.txt hadoop:/tmp/clima.txt
docker cp datos/clientes.txt hadoop:/tmp/clientes.txt
docker cp datos/pedidos.txt hadoop:/tmp/pedidos.txt

```

**4.3 Limpiar salidas previas (Recomendado)**
Hadoop arroja error si las carpetas de salida ya existen. Ejecuta esto para asegurar una ejecución limpia.

```bash
# 🐳 Dentro del contenedor
docker exec -u root hadoop rm -rf /tmp/salida_sort /tmp/salida_join

```

**4.4 Ejecutar los algoritmos dentro de Hadoop**
Ejecutaremos el *Secondary Sort* y el *Join*. Los comandos incluyen saltos de línea (`\`) para facilitar su lectura y declaran la ruta de Java explícitamente para evitar errores de conexión.

```bash
# 🐳 Dentro del contenedor (Ejecutar Secondary Sort)
docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop \
  /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  secondarysort /tmp/clima.txt /tmp/salida_sort

# 🐳 Dentro del contenedor (Ejecutar Join)
docker exec -u hadoop -e JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 hadoop \
  /opt/hadoop/bin/hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
  join -inFormat org.apache.hadoop.mapreduce.lib.input.KeyValueTextInputFormat \
  -outFormat org.apache.hadoop.mapreduce.lib.output.TextOutputFormat \
  -outKey org.apache.hadoop.io.Text \
  /tmp/clientes.txt /tmp/pedidos.txt /tmp/salida_join

```

**4.5 Extraer los resultados a tu computadora**
Nota que el archivo del *Secondary Sort* termina en `part-r` (pasó por un Reduce), mientras que el del *Join* termina en `part-m` (fue un Map-side join).

```bash
# 💻 En tu computadora
docker cp hadoop:/tmp/salida_sort/part-r-00000 resultados/resultado_sort.txt
docker cp hadoop:/tmp/salida_join/part-m-00000 resultados/resultado_join.txt

```

## 5. Resultado Esperado
Al ejecutar un `cat` de los resultados, deberías ver las temperaturas ordenadas por año y las compras cruzadas y asociadas a cada cliente.

## 6. Explicación de Map y Reduce
* **Secondary Sort:** El *Map* emite una llave compuesta `[Año, Temperatura]`. El framework agrupa por Año, pero ordena por la llave completa. El *Reduce* recibe la llave y los valores ya ordenados listos para iterar.
* **Join:** El algoritmo lee de ambos archivos usando el ID como llave. Como es un *Map-side join*, cruza los datos coincidentes durante el mapeo sin requerir fase *Reduce*.

## 7. Errores Comunes y Soluciones
* **Error:** `JAVA_HOME is not set`. **Solución:** Pasar explícitamente `-e JAVA_HOME=/usr/lib/jvm/...` en el comando `docker exec`.
* **Error:** El `join` no procesa los datos. **Solución:** Requiere columnas separadas por un tabulador real (`\t`) y especificar explícitamente `-inFormat KeyValueTextInputFormat`.
* **Error:** `Could not find the file /part-r-00000`. **Solución:** El ejemplo de Join no usa Reducers, por lo que el archivo de salida termina en `part-m-00000`.
