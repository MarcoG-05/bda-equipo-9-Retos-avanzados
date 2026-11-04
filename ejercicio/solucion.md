# Solución al Mini Ejercicio

## Parte 1: Secondary Sort
**Llave Compuesta:** `[Norte, 150]`
El Map no emite solo la sucursal, sino que combina ambas columnas en la llave para que Hadoop las ordene automáticamente en el Shuffle.

## Parte 2: Join
**Llave emitida:** `1`
**Valores agrupados:** `( [estudiantes] Ana, [calificaciones] Matematicas )`
El Map agrupa por el ID común (1) y junta los valores etiquetados de ambos archivos para armar el registro final.
