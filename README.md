[README.md](https://github.com/user-attachments/files/34223329/README.md)
# Inventario-Ropa-Mayoreo-Unidad2.
Proyecto de Unidad 2 - Inventario y ventas de ropa con descuentos por mayoreo.
# Inventario de Ropa con Descuentos por Mayoreo

**Proyecto de la Unidad 2 - Lenguajes de Interfaz**

## Integrantes

- Oscar Javier Chaidez Salazar
- Ángel Daniel Vega Hernández

## ¿De qué trata el proyecto?

Este programa permite llevar el inventario y las ventas de una tienda de ropa. Está hecho en lenguaje ensamblador **MASM x86 de 32 bits**, utilizando la biblioteca **Irvine32** y **Visual Studio**.

El inventario admite un máximo de **10 productos diferentes**, con hasta **100 unidades de cada producto**.

## Opciones del programa

1. **Registrar prenda:** captura código, nombre, precio y existencias.
2. **Mostrar inventario:** muestra las prendas registradas.
3. **Buscar prenda:** encuentra un producto por su código.
4. **Recibir mercancía:** aumenta las existencias sin superar 100 unidades.
5. **Vender prendas:** calcula el importe, aplica el descuento y descuenta las unidades vendidas.
6. **Resumen:** muestra las unidades disponibles, el valor del inventario y los ingresos de la sesión.
7. **Guardar inventario:** guarda los productos en `ropa.dat`.
8. **Cargar inventario:** recupera los productos de `ropa.dat`.
0. **Salir:** cierra el programa y pregunta si deseas guardar cuando hay cambios pendientes.

## Regla adicional: descuento por mayoreo

La cantidad comprada **en una sola venta** determina el descuento:

| Cantidad | Descuento |
|---|---:|
| 1 a 9 prendas | 0 % |
| 10 a 19 prendas | 10 % |
| 20 o más prendas | 15 % |

Ejemplo: si una playera cuesta **$250.00 MXN** y se venden **12**, el subtotal es **$3,000.00 MXN**, el descuento es **$300.00 MXN** y el cliente paga **$2,700.00 MXN**.

Los descuentos se aplican solo cuando hay suficientes existencias.

## Reglas principales

- Máximo de 10 tipos de prendas.
- Código único con formato `ABC-123`.
- Nombre de 1 a 25 caracteres.
- Precio desde $0.01 hasta $9,999.99 MXN.
- Existencias de 0 a 100 unidades por producto.
- Los precios se guardan como **centavos enteros** para hacer los cálculos.
- Las ventas y entradas de mercancía se validan antes de actualizar el inventario.

## Archivos del repositorio

```text
Inventario-Ropa-Mayoreo-Unidad2/
|-- Projectu2.slnx
|-- README.md
|-- Informe_Proyecto.pdf        (pendiente de agregar)
|-- Tabla_Pruebas.xlsx          (pendiente de agregar)
`-- ProjectPract/
    |-- ProjectPract.vcxproj
    |-- ProjectPract.vcxproj.filters
    |-- main.asm
    `-- ropa.dat
```

**Nota:** la solución `Projectu2.slnx` busca el archivo `ProjectPract/ProjectPract.vcxproj`, por eso es importante respetar la estructura de carpetas.

## Cómo compilar y ejecutar

1. En una computadora con **Windows**, instala Visual Studio con las herramientas de desarrollo de C++ y el ensamblador MASM.
2. Prepara la biblioteca **Irvine32 de 32 bits**. La configuración incluida en `ProjectPract.vcxproj` busca sus archivos en `C:\Irvine`. Si los tienes en otra carpeta, cambia las rutas de inclusión y bibliotecas en las propiedades del proyecto.
3. Descarga el repositorio desde GitHub (`Code` → `Download ZIP`) y extrae su contenido, o clónalo con Git.
4. Abre `Projectu2.slnx` en una versión de Visual Studio compatible con archivos `.slnx`.
5. Selecciona la configuración **Debug | Win32**. **No uses x64** para este proyecto, ya que utiliza Irvine32.
6. Compila la solución con **Compilar → Compilar solución** (o `Ctrl+Shift+B`).
7. Ejecuta el programa sin depuración con `Ctrl+F5`.
8. En el menú, utiliza la opción **8. Cargar inventario** si deseas recuperar los productos de `ropa.dat`.

**Importante sobre `ropa.dat`:** el programa abre el archivo usando una ruta relativa. Si no lo encuentra, colócalo en el **directorio de trabajo** desde el que se ejecuta el programa o ajusta ese directorio en las propiedades de depuración de Visual Studio. Al guardar con la opción 7, el archivo se crea en ese directorio de trabajo.

## Pruebas sugeridas para la demostración

- Registrar una prenda válida y rechazar un código repetido.
- Buscar una prenda existente y una inexistente.
- Recibir mercancía sin rebasar 100 unidades y rechazar una entrada que exceda el límite.
- Vender con 0 %, 10 % y 15 % de descuento.
- Intentar vender más prendas de las disponibles y confirmar que no se modifique el inventario.
- Mostrar el resumen del inventario.
- Guardar, cerrar, abrir de nuevo y cargar `ropa.dat`.

Los **resultados obtenidos** de estas pruebas se documentarán en `Tabla_Pruebas.xlsx` después de ejecutarlas en Visual Studio. No se incluyen resultados de prueba no verificados.

## Nota sobre las herramientas

Para compilar en otra computadora se necesita instalar y configurar MASM, Visual Studio e Irvine32. El repositorio contiene el código del proyecto y el inventario de ejemplo, pero no la biblioteca Irvine32 ni herramientas de Visual Studio.
