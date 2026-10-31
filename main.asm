.386
.model flat, stdcall
.stack 4096
option casemap:none
INCLUDE Irvine32.inc

; Inventario de ropa: maximo 10 tipos de prenda.
; El precio se almacena en centavos: $250.00 = 25000.
MAX_PROD EQU 10
TAM_COD EQU 8
TAM_NOM EQU 26
TAM_DATOS EQU 4 + MAX_PROD*TAM_COD + MAX_PROD*TAM_NOM + MAX_PROD*4 + MAX_PROD*4
OFF_COD EQU 4
OFF_NOM EQU OFF_COD + MAX_PROD*TAM_COD
OFF_PRE EQU OFF_NOM + MAX_PROD*TAM_NOM
OFF_STK EQU OFF_PRE + MAX_PROD*4

.data
menuTxt BYTE 13,10,"===== TIENDA DE ROPA =====",13,10
        BYTE "1. Registrar prenda",13,10
        BYTE "2. Mostrar inventario",13,10
        BYTE "3. Buscar prenda",13,10
        BYTE "4. Recibir mercancia",13,10
        BYTE "5. Vender prendas",13,10
        BYTE "6. Resumen",13,10
        BYTE "7. Guardar inventario",13,10
        BYTE "8. Cargar inventario",13,10
        BYTE "0. Salir",13,10
        BYTE "Opcion: ",0
pedCod BYTE "Codigo (ABC-123): ",0
pedNom BYTE "Nombre (maximo 25 caracteres): ",0
pedPre BYTE "Precio (ejemplo 250.00): ",0
pedStk BYTE "Existencias iniciales (0-100): ",0
pedCant BYTE "Cantidad: ",0
mMal BYTE "Dato u opcion incorrecta.",13,10,0
mLleno BYTE "El inventario ya tiene 10 productos.",13,10,0
mRepetido BYTE "Ese codigo ya existe.",13,10,0
mNo BYTE "Prenda no encontrada.",13,10,0
mExceso BYTE "Operacion rechazada: revisa las existencias o el limite de 100.",13,10,0
mRegistrado BYTE "Prenda registrada.",13,10,0
mRecibido BYTE "Mercancia recibida.",13,10,0
mVendido BYTE "Venta realizada.",13,10,0
mVacio BYTE "Inventario vacio.",13,10,0
mCodigo BYTE "Codigo: ",0
mNombre BYTE " | Prenda: ",0
mPrecio BYTE " | Precio: $",0
mMXN BYTE " MXN",0
mStock BYTE " | Unidades: ",0
mSubtotal BYTE "Subtotal: $",0
mDescuento BYTE "Descuento: $",0
mTotal BYTE "Total: $",0
mPorc BYTE "Porcentaje aplicado: ",0
mPorcFin BYTE "%",13,10,0
mUnidades BYTE "Unidades disponibles: ",0
mValor BYTE "Valor del inventario: $",0
mIngresos BYTE "Ingresos de esta sesion: $",0
mGuardado BYTE "Inventario guardado.",13,10,0
mCargado BYTE "Inventario cargado.",13,10,0
mArchivo BYTE "No se pudo cargar o guardar el archivo correctamente.",13,10,0
mCambios BYTE "Hay cambios sin guardar. Continuar? (S/N): ",0
mSalir BYTE "Guardar antes de salir? (S/N): ",0
mAdios BYTE "Fin del programa.",13,10,0
archivo BYTE "ropa.dat",0

; Datos que se guardan juntos: 424 bytes.
inicioDatos LABEL BYTE
numProductos DWORD 0
codigos BYTE MAX_PROD*TAM_COD DUP(0)
nombres BYTE MAX_PROD*TAM_NOM DUP(0)
precios DWORD MAX_PROD DUP(0)
stocks DWORD MAX_PROD DUP(0)

; Datos temporales: nunca se guardan.
entrada BYTE 128 DUP(0)
codigoTmp BYTE TAM_COD DUP(0)
nombreTmp BYTE TAM_NOM DUP(0)
precioTmp DWORD 0
stockTmp DWORD 0
indice DWORD 0
cantidad DWORD 0
subtotal DWORD 0
descuento DWORD 0
total DWORD 0
porcentaje DWORD 0
ingresos DWORD 0
cambios DWORD 0
resultado DWORD 0
archivoHandle DWORD 0
bytesLeidos DWORD 0
bufferArchivo BYTE TAM_DATOS+1 DUP(0)
textoNumero BYTE 16 DUP(0)

.code
; Entrada: opcion del usuario. Salida: menu y llamadas. Registros: EAX, EDX.
main PROC
MenuPrincipal:
    mov edx, OFFSET menuTxt
    call WriteString
    call LeerTexto
    call AEntero
    cmp edx, 1
    jne OpcionMala
    cmp eax, 0
    je Salir
    cmp eax, 1
    je Op1
    cmp eax, 2
    je Op2
    cmp eax, 3
    je Op3
    cmp eax, 4
    je Op4
    cmp eax, 5
    je Op5
    cmp eax, 6
    je Op6
    cmp eax, 7
    je Op7
    cmp eax, 8
    je Op8
OpcionMala:
    mov edx, OFFSET mMal
    call WriteString
    jmp MenuPrincipal
Op1:
    call Registrar
    jmp MenuPrincipal
Op2:
    call MostrarTodo
    jmp MenuPrincipal
Op3:
    call Buscar
    jmp MenuPrincipal
Op4:
    call Recibir
    jmp MenuPrincipal
Op5:
    call Vender
    jmp MenuPrincipal
Op6:
    call Resumen
    jmp MenuPrincipal
Op7:
    call Guardar
    jmp MenuPrincipal
Op8:
    cmp cambios, 0
    je CargarDirecto
    mov edx, OFFSET mCambios
    call PreguntarSi
    cmp eax, 1
    jne MenuPrincipal
CargarDirecto:
    call Cargar
    jmp MenuPrincipal
Salir:
    cmp cambios, 0
    je Fin
    mov edx, OFFSET mSalir
    call PreguntarSi
    cmp eax, 1
    jne Fin
    call Guardar
    cmp eax, 1
    jne MenuPrincipal
Fin:
    mov edx, OFFSET mAdios
    call WriteString
    exit
main ENDP

; Lee una linea a 'entrada'. EDX queda libre despues de la llamada.
; Entrada: ninguna. Salida: entrada y longitud en EAX. ECX/EDX preservados.
LeerTexto PROC USES ecx edx
    mov edx, OFFSET entrada
    mov ecx, SIZEOF entrada - 1
    call ReadString
    ret
LeerTexto ENDP

; Lee S o s como SI. Entrada: EDX=mensaje. Salida: EAX=1 o 0.
; Entrada: EDX=mensaje. Salida: EAX=1 (si) o 0 (no). EDX preservado.
PreguntarSi PROC USES edx
    call WriteString
    call LeerTexto
    mov al, entrada[0]
    cmp al, 's'
    je PS_Si
    cmp al, 'S'
    je PS_Si
    xor eax, eax
    ret
PS_Si:
    mov eax, 1
    ret
PreguntarSi ENDP

; Texto entero sin signo -> EAX numero, EDX=1 valido/0 error.
; Entrada: entrada. Salida: EAX=numero, EDX=validez. EBX/ECX/ESI preservados.
AEntero PROC USES ebx ecx esi
    xor eax, eax
    xor ecx, ecx
    mov esi, OFFSET entrada
AE_Bucle:
    movzx ebx, BYTE PTR [esi]
    cmp ebx, 0
    je AE_Fin
    cmp ebx, '0'
    jb AE_Error
    cmp ebx, '9'
    ja AE_Error
    sub ebx, '0'
    imul eax, eax, 10
    jo AE_Error
    add eax, ebx
    jc AE_Error
    inc ecx
    inc esi
    jmp AE_Bucle
AE_Fin:
    cmp ecx, 0
    je AE_Error
    mov edx, 1
    ret
AE_Error:
    xor eax, eax
    xor edx, edx
    ret
AEntero ENDP

; Convierte precio escrito como 250, 250.5 o 250.50 a centavos.
; EAX=centavos; EDX=1 valido/0 invalido.
; Entrada: entrada. Salida: EAX=centavos, EDX=validez. EBX/ECX/ESI/EDI preservados.
APrecio PROC USES ebx ecx esi edi
    xor eax, eax
    xor ebx, ebx            ; cantidad de decimales
    xor ecx, ecx            ; digitos antes del punto
    xor edi, edi            ; 1 si aparece punto
    mov esi, OFFSET entrada
AP_Bucle:
    movzx edx, BYTE PTR [esi]
    cmp edx, 0
    je AP_Fin
    cmp edx, '.'
    je AP_Punto
    cmp edx, '0'
    jb AP_Error
    cmp edx, '9'
    ja AP_Error
    sub edx, '0'
    imul eax, eax, 10
    jo AP_Error
    add eax, edx
    jc AP_Error
    cmp edi, 0
    jne AP_Decimal
    inc ecx
    jmp AP_Siguiente
AP_Decimal:
    inc ebx
    cmp ebx, 2
    ja AP_Error
AP_Siguiente:
    inc esi
    jmp AP_Bucle
AP_Punto:
    cmp edi, 0
    jne AP_Error
    cmp ecx, 0
    je AP_Error
    mov edi, 1
    inc esi
    jmp AP_Bucle
AP_Fin:
    cmp ecx, 0
    je AP_Error
    cmp edi, 0
    je AP_100
    cmp ebx, 0
    je AP_Error
    cmp ebx, 1
    je AP_10
    jmp AP_Limite
AP_100:
    imul eax, eax, 100
    jo AP_Error
    jmp AP_Limite
AP_10:
    imul eax, eax, 10
    jo AP_Error
AP_Limite:
    cmp eax, 1
    jb AP_Error
    cmp eax, 999999
    ja AP_Error
    mov edx, 1
    ret
AP_Error:
    xor eax, eax
    xor edx, edx
    ret
APrecio ENDP

; Muestra un entero sin WriteDec: divisiones entre 10.
; Entrada: EAX=entero. Salida: texto en consola. EAX/EBX/EDX/EDI preservados.
MostrarEntero PROC USES eax ebx edx edi
    mov edi, OFFSET textoNumero + SIZEOF textoNumero - 1
    mov BYTE PTR [edi], 0
    mov ebx, 10
ME_Bucle:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov BYTE PTR [edi], dl
    cmp eax, 0
    jne ME_Bucle
    mov edx, edi
    call WriteString
    ret
MostrarEntero ENDP

; EAX=centavos: muestra pesos.punto.dos decimales.
; Entrada: EAX=centavos. Salida: pesos y dos decimales. EAX/EBX/EDX preservados.
MostrarPrecio PROC USES eax ebx edx
    xor edx, edx
    mov ebx, 100
    div ebx
    push edx
    call MostrarEntero
    mov al, '.'
    call WriteChar
    pop eax
    cmp eax, 10
    jae MP_Fin
    push eax
    mov al, '0'
    call WriteChar
    pop eax
MP_Fin:
    call MostrarEntero
    ret
MostrarPrecio ENDP

; ESI apunta a codigo de 8 bytes. EAX=1 si cumple ABC-123.
; Entrada: ESI=codigo de 8 bytes. Salida: EAX=1/0. ECX/ESI preservados.
CodigoValido PROC USES ecx esi
    mov ecx, 3
CV_Letras:
    mov al, [esi]
    cmp al, 'A'
    jb CV_Error
    cmp al, 'Z'
    ja CV_Error
    inc esi
    loop CV_Letras
    cmp BYTE PTR [esi], '-'
    jne CV_Error
    inc esi
    mov ecx, 3
CV_Digitos:
    mov al, [esi]
    cmp al, '0'
    jb CV_Error
    cmp al, '9'
    ja CV_Error
    inc esi
    loop CV_Digitos
    cmp BYTE PTR [esi], 0
    jne CV_Error
    mov eax, 1
    ret
CV_Error:
    xor eax, eax
    ret
CodigoValido ENDP

; Busca codigoTmp. EAX=indice (0-9) o -1 si no existe.
; Entrada: codigoTmp. Salida: EAX=indice o -1. EBX/ECX/ESI/EDI preservados.
IndiceCodigo PROC USES ebx ecx esi edi
    xor ebx, ebx
IC_Bucle:
    cmp ebx, numProductos
    jae IC_No
    mov eax, ebx
    shl eax, 3
    lea edi, codigos[eax]
    mov esi, OFFSET codigoTmp
    mov ecx, 7
    cld
    repe cmpsb
    je IC_Si
    inc ebx
    jmp IC_Bucle
IC_Si:
    mov eax, ebx
    ret
IC_No:
    mov eax, -1
    ret
IndiceCodigo ENDP

; Pide codigo, lo valida y devuelve su indice o -1.
; Entrada: texto del usuario. Salida: EAX=indice o -1. ECX/EDX/ESI/EDI preservados.
PedirProducto PROC USES ecx edx esi edi
    mov edx, OFFSET pedCod
    call WriteString
    call LeerTexto
    mov esi, OFFSET entrada
    call CodigoValido
    cmp eax, 1
    jne PP_No
    mov esi, OFFSET entrada
    mov edi, OFFSET codigoTmp
    mov ecx, TAM_COD
    cld
    rep movsb
    call IndiceCodigo
    ret
PP_No:
    mov eax, -1
    ret
PedirProducto ENDP

; Entrada: codigo, nombre, precio y stock. Salida: alta valida. Registros generales preservados.
Registrar PROC USES eax ebx ecx edx esi edi
    cmp numProductos, MAX_PROD
    jae R_Lleno
    mov edx, OFFSET pedCod
    call WriteString
    call LeerTexto
    mov esi, OFFSET entrada
    call CodigoValido
    cmp eax, 1
    jne R_Error
    mov esi, OFFSET entrada
    mov edi, OFFSET codigoTmp
    mov ecx, TAM_COD
    cld
    rep movsb
    call IndiceCodigo
    cmp eax, -1
    jne R_Duplicado

    mov edx, OFFSET pedNom
    call WriteString
    call LeerTexto
    cmp eax, 1
    jb R_Error
    cmp eax, 25
    ja R_Error
    mov esi, OFFSET entrada
    mov edi, OFFSET nombreTmp
    mov ecx, TAM_NOM
    cld
    rep movsb

    mov edx, OFFSET pedPre
    call WriteString
    call LeerTexto
    call APrecio
    cmp edx, 1
    jne R_Error
    mov precioTmp, eax

    mov edx, OFFSET pedStk
    call WriteString
    call LeerTexto
    call AEntero
    cmp edx, 1
    jne R_Error
    cmp eax, 100
    ja R_Error
    mov stockTmp, eax

    ; Solo al final (todo valido) se modifica el inventario.
    mov eax, numProductos
    shl eax, 3
    lea edi, codigos[eax]
    mov esi, OFFSET codigoTmp
    mov ecx, TAM_COD
    rep movsb
    mov eax, numProductos
    imul eax, eax, TAM_NOM
    lea edi, nombres[eax]
    mov esi, OFFSET nombreTmp
    mov ecx, TAM_NOM
    rep movsb
    mov esi, numProductos
    mov eax, precioTmp
    mov precios[esi*4], eax
    mov eax, stockTmp
    mov stocks[esi*4], eax
    inc numProductos
    mov cambios, 1
    mov edx, OFFSET mRegistrado
    call WriteString
    ret
R_Lleno:
    mov edx, OFFSET mLleno
    jmp R_Aviso
R_Duplicado:
    mov edx, OFFSET mRepetido
    jmp R_Aviso
R_Error:
    mov edx, OFFSET mMal
R_Aviso:
    call WriteString
    ret
Registrar ENDP

; ESI=indice; muestra un solo producto.
; Entrada: ESI=indice. Salida: datos en consola. EAX/EDX/ESI preservados.
MostrarUno PROC USES eax edx esi
    mov edx, OFFSET mCodigo
    call WriteString
    mov eax, esi
    shl eax, 3
    lea edx, codigos[eax]
    call WriteString
    mov edx, OFFSET mNombre
    call WriteString
    mov eax, esi
    imul eax, eax, TAM_NOM
    lea edx, nombres[eax]
    call WriteString
    mov edx, OFFSET mPrecio
    call WriteString
    mov eax, precios[esi*4]
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    mov edx, OFFSET mStock
    call WriteString
    mov eax, stocks[esi*4]
    call MostrarEntero
    call Crlf
    ret
MostrarUno ENDP

; Entrada: inventario. Salida: lista por consola. EDX/ESI preservados.
MostrarTodo PROC USES edx esi
    cmp numProductos, 0
    je MT_Vacio
    xor esi, esi
MT_Bucle:
    cmp esi, numProductos
    jae MT_Fin
    call MostrarUno
    inc esi
    jmp MT_Bucle
MT_Vacio:
    mov edx, OFFSET mVacio
    call WriteString
MT_Fin:
    ret
MostrarTodo ENDP

; Entrada: codigo del usuario. Salida: datos o error. EAX/EDX/ESI preservados.
Buscar PROC USES eax edx esi
    call PedirProducto
    cmp eax, -1
    je B_No
    mov esi, eax
    call MostrarUno
    ret
B_No:
    mov edx, OFFSET mNo
    call WriteString
    ret
Buscar ENDP

; Entrada: codigo y cantidad. Salida: stock actualizado o error. EAX/EBX/EDX/ESI preservados.
Recibir PROC USES eax ebx edx esi
    call PedirProducto
    cmp eax, -1
    je RV_No
    mov indice, eax
    mov edx, OFFSET pedCant
    call WriteString
    call LeerTexto
    call AEntero
    cmp edx, 1
    jne RV_Error
    cmp eax, 1
    jb RV_Error
    cmp eax, 100
    ja RV_Exceso
    mov esi, indice
    mov ebx, stocks[esi*4]
    add ebx, eax
    cmp ebx, 100
    ja RV_Exceso
    mov stocks[esi*4], ebx
    mov cambios, 1
    mov edx, OFFSET mRecibido
    call WriteString
    ret
RV_No:
    mov edx, OFFSET mNo
    jmp RV_Mensaje
RV_Exceso:
    mov edx, OFFSET mExceso
    jmp RV_Mensaje
RV_Error:
    mov edx, OFFSET mMal
RV_Mensaje:
    call WriteString
    ret
Recibir ENDP

; Entrada: codigo y cantidad. Salida: existencias e ingresos actualizados o error. EAX/EBX/EDX/ESI preservados.
Vender PROC USES eax ebx edx esi
    call PedirProducto
    cmp eax, -1
    je V_No
    mov indice, eax
    mov edx, OFFSET pedCant
    call WriteString
    call LeerTexto
    call AEntero
    cmp edx, 1
    jne V_Error
    cmp eax, 1
    jb V_Error
    mov esi, indice
    cmp eax, stocks[esi*4]
    ja V_Exceso
    mov cantidad, eax

    ; Subtotal = precio en centavos * unidades.
    mov eax, precios[esi*4]
    mul cantidad
    cmp edx, 0
    jne V_Error
    mov subtotal, eax
    mov porcentaje, 0
    cmp cantidad, 20
    jae V_Quince
    cmp cantidad, 10
    jb V_Calcular
    mov porcentaje, 10
    jmp V_Calcular
V_Quince:
    mov porcentaje, 15
V_Calcular:
    mov eax, subtotal
    mul porcentaje
    cmp edx, 0
    jne V_Error
    mov ebx, 100
    div ebx
    mov descuento, eax
    mov eax, subtotal
    sub eax, descuento
    mov total, eax

    ; Confirmar que ingresos tampoco desborde antes de vender.
    mov eax, ingresos
    add eax, total
    jc V_Error
    mov ingresos, eax
    mov esi, indice
    mov eax, stocks[esi*4]
    sub eax, cantidad
    mov stocks[esi*4], eax
    mov cambios, 1

    mov edx, OFFSET mSubtotal
    call WriteString
    mov eax, subtotal
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    call Crlf
    mov edx, OFFSET mPorc
    call WriteString
    mov eax, porcentaje
    call MostrarEntero
    mov edx, OFFSET mPorcFin
    call WriteString
    mov edx, OFFSET mDescuento
    call WriteString
    mov eax, descuento
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    call Crlf
    mov edx, OFFSET mTotal
    call WriteString
    mov eax, total
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    call Crlf
    mov edx, OFFSET mVendido
    call WriteString
    ret
V_No:
    mov edx, OFFSET mNo
    jmp V_Mensaje
V_Exceso:
    mov edx, OFFSET mExceso
    jmp V_Mensaje
V_Error:
    mov edx, OFFSET mMal
V_Mensaje:
    call WriteString
    ret
Vender ENDP

; Entrada: inventario e ingresos. Salida: totales en consola. EAX/EBX/EDX/ESI preservados.
Resumen PROC USES eax ebx edx esi
    xor esi, esi
    xor ebx, ebx            ; suma de unidades
    mov resultado, 0        ; valor total en centavos
RS_Bucle:
    cmp esi, numProductos
    jae RS_Mostrar
    add ebx, stocks[esi*4]
    mov eax, precios[esi*4]
    mul stocks[esi*4]
    add resultado, eax
    inc esi
    jmp RS_Bucle
RS_Mostrar:
    mov edx, OFFSET mUnidades
    call WriteString
    mov eax, ebx
    call MostrarEntero
    call Crlf
    mov edx, OFFSET mValor
    call WriteString
    mov eax, resultado
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    call Crlf
    mov edx, OFFSET mIngresos
    call WriteString
    mov eax, ingresos
    call MostrarPrecio
    mov edx, OFFSET mMXN
    call WriteString
    call Crlf
    ret
Resumen ENDP

; Guardar exactamente 424 bytes. EAX=1 si tuvo exito.
; Entrada: inventario. Salida: archivo y EAX=1/0. EBX/ECX/EDX preservados.
Guardar PROC USES ebx ecx edx
    mov edx, OFFSET archivo
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je G_Error
    mov archivoHandle, eax
    mov edx, OFFSET inicioDatos
    mov ecx, TAM_DATOS
    call WriteToFile
    jc G_CerrarError
    mov resultado, eax
    mov eax, archivoHandle
    call CloseFile
    jc G_Error
    cmp resultado, TAM_DATOS
    jne G_Error
    mov cambios, 0
    mov edx, OFFSET mGuardado
    call WriteString
    mov eax, 1
    ret
G_CerrarError:
    mov eax, archivoHandle
    call CloseFile
G_Error:
    mov edx, OFFSET mArchivo
    call WriteString
    xor eax, eax
    ret
Guardar ENDP

; Comprueba el archivo en memoria temporal ANTES de sustituir los datos.
; Valida codigos, nombres, precios, existencias y codigos repetidos.
; Entrada: bufferArchivo. Salida: EAX=1/0. EBX/ECX/EDX/ESI/EDI preservados.
ArchivoValido PROC USES ebx ecx edx esi edi
    mov eax, DWORD PTR [bufferArchivo]
    cmp eax, MAX_PROD
    ja AV_Error
    xor ebx, ebx
AV_Producto:
    cmp ebx, DWORD PTR [bufferArchivo]
    jae AV_Duplicados
    mov eax, ebx
    shl eax, 3
    mov esi, OFFSET bufferArchivo + OFF_COD
    add esi, eax
    call CodigoValido
    cmp eax, 1
    jne AV_Error

    mov eax, ebx
    imul eax, eax, TAM_NOM
    mov esi, OFFSET bufferArchivo + OFF_NOM
    add esi, eax
    cmp BYTE PTR [esi], 0
    je AV_Error
    mov ecx, TAM_NOM
AV_Nombre:
    cmp BYTE PTR [esi], 0
    je AV_NombreOK
    inc esi
    loop AV_Nombre
    jmp AV_Error
AV_NombreOK:
    mov eax, DWORD PTR bufferArchivo[ebx*4 + OFF_PRE]
    cmp eax, 1
    jb AV_Error
    cmp eax, 999999
    ja AV_Error
    cmp DWORD PTR bufferArchivo[ebx*4 + OFF_STK], 100
    ja AV_Error
    inc ebx
    jmp AV_Producto

AV_Duplicados:
    xor ebx, ebx
AV_Externo:
    cmp ebx, DWORD PTR [bufferArchivo]
    jae AV_OK
    mov edx, ebx
    inc edx
AV_Interno:
    cmp edx, DWORD PTR [bufferArchivo]
    jae AV_Siguiente
    mov eax, ebx
    shl eax, 3
    mov esi, OFFSET bufferArchivo + OFF_COD
    add esi, eax
    mov eax, edx
    shl eax, 3
    mov edi, OFFSET bufferArchivo + OFF_COD
    add edi, eax
    mov ecx, 7
    cld
    repe cmpsb
    je AV_Error
    inc edx
    jmp AV_Interno
AV_Siguiente:
    inc ebx
    jmp AV_Externo
AV_OK:
    mov eax, 1
    ret
AV_Error:
    xor eax, eax
    ret
ArchivoValido ENDP

; Lee 425 bytes maximos, para detectar archivos demasiado largos.
; Entrada: archivo en disco. Salida: inventario y EAX=1/0. EBX/ECX/EDX/ESI/EDI preservados.
Cargar PROC USES ebx ecx edx esi edi
    mov edx, OFFSET archivo
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je C_Error
    mov archivoHandle, eax
    mov edx, OFFSET bufferArchivo
    mov ecx, TAM_DATOS + 1
    call ReadFromFile
    jc C_CerrarError
    mov bytesLeidos, eax
    mov eax, archivoHandle
    call CloseFile
    jc C_Error
    cmp bytesLeidos, TAM_DATOS
    jne C_Error
    call ArchivoValido
    cmp eax, 1
    jne C_Error
    mov esi, OFFSET bufferArchivo
    mov edi, OFFSET inicioDatos
    mov ecx, TAM_DATOS
    cld
    rep movsb
    mov cambios, 0
    mov edx, OFFSET mCargado
    call WriteString
    mov eax, 1
    ret
C_CerrarError:
    mov eax, archivoHandle
    call CloseFile
C_Error:
    mov edx, OFFSET mArchivo
    call WriteString
    xor eax, eax
    ret
Cargar ENDP

END main
