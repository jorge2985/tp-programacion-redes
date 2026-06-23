param(
    [string]$RutaSalida = (Join-Path (Split-Path -Parent $PSScriptRoot) "Documentacion_Servidor_Web_Simple.docx")
)

# Este script genera un archivo .docx sin depender de Microsoft Word ni de librerias externas.
# Un archivo Word moderno es un paquete ZIP con documentos XML estandarizados (Open XML).
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Convertir-A-XmlSeguro {
    param([string]$Texto)

    return [System.Security.SecurityElement]::Escape($Texto)
}

function Crear-ParrafoXml {
    param(
        [string]$Texto,
        [string]$Estilo = "Normal"
    )

    $textoSeguro = Convertir-A-XmlSeguro $Texto
    return ('<w:p><w:pPr><w:pStyle w:val="{0}"/></w:pPr><w:r><w:t xml:space="preserve">{1}</w:t></w:r></w:p>' -f $Estilo, $textoSeguro)
}

$contenido = @(
    @{ Estilo = "Titulo"; Texto = "Servidor Web Simple en .NET" },
    @{ Estilo = "Subtitulo"; Texto = "Documento de cumplimiento detallado de requisitos" },
    @{ Estilo = "Normal"; Texto = "Proyecto: TP_final / WebServer" },
    @{ Estilo = "Normal"; Texto = "Tecnologia: .NET 8, aplicacion de consola y sockets TCP directos." },
    @{ Estilo = "Salto"; Texto = "" },

    @{ Estilo = "Encabezado1"; Texto = "1. Objetivo de este documento" },
    @{ Estilo = "Normal"; Texto = "Este archivo reproduce los diez requisitos del documento Servidor_web_simple.docx y, debajo de cada uno, explica como se implementa en el proyecto actual. La intencion es que una persona que esta aprendiendo pueda seguir el camino completo: desde que un navegador abre una conexion hasta que el servidor devuelve una respuesta y registra la solicitud." },
    @{ Estilo = "Normal"; Texto = "Los nombres del codigo estan mayormente en espanol para facilitar la lectura. Algunos terminos permanecen en ingles porque forman parte del estandar HTTP o de la API de .NET: GET, POST, Content-Length, Socket y GZipStream. No son nombres arbitrarios del proyecto, sino palabras tecnicas que el protocolo requiere." },

    @{ Estilo = "Encabezado1"; Texto = "2. Como leer el proyecto" },
    @{ Estilo = "Normal"; Texto = "El punto de entrada es WebServer/Program.cs. Primero carga config.json, prepara las rutas de trabajo, crea los servicios y pone en marcha el servidor. Program.cs no analiza HTTP ni busca archivos; solo coordina. Esta separacion evita concentrar toda la logica en un unico archivo." },
    @{ Estilo = "Normal"; Texto = "La carpeta Nucleo contiene el funcionamiento de red. ServidorHttp abre el socket que escucha conexiones y ManejadorCliente atiende una sola conexion. La carpeta ProtocoloHttp transforma bytes en una SolicitudHttp y construye bytes de una RespuestaHttp. La carpeta Services contiene operaciones auxiliares: archivos, logs, compresion y tipos MIME." },
    @{ Estilo = "Normal"; Texto = "El recorrido normal es: Program.cs -> ServidorHttp.IniciarAsync -> ManejadorCliente.AtenderAsync -> AnalizadorSolicitudHttp.Analizar -> ServicioLogs.RegistrarSolicitudAsync -> ServicioArchivos.ObtenerArchivoAsync -> ServicioCompresion.Comprimir -> ConstructorRespuestaHttp.Construir -> Socket.SendAsync." },

    @{ Estilo = "Encabezado1"; Texto = "3. Estructura de archivos relevante" },
    @{ Estilo = "Codigo"; Texto = "WebServer/Program.cs                         Inicio y composicion de servicios" },
    @{ Estilo = "Codigo"; Texto = "WebServer/config.json                       Puerto y carpeta publica" },
    @{ Estilo = "Codigo"; Texto = "WebServer/Nucleo/ConfiguracionServidor.cs  Lectura y validacion de configuracion" },
    @{ Estilo = "Codigo"; Texto = "WebServer/Nucleo/ServidorHttp.cs            Socket de escucha y concurrencia" },
    @{ Estilo = "Codigo"; Texto = "WebServer/Nucleo/ManejadorCliente.cs        Una solicitud completa por cliente" },
    @{ Estilo = "Codigo"; Texto = "WebServer/ProtocoloHttp/*                   Modelos, analizador y constructor HTTP" },
    @{ Estilo = "Codigo"; Texto = "WebServer/Services/*                        Archivos, registros, compresion y MIME" },
    @{ Estilo = "Codigo"; Texto = "WebServer/wwwroot/index.html y 404.html     Paginas estaticas publicas" },
    @{ Estilo = "Codigo"; Texto = "WebServer/logs/                              Un archivo de registro por dia" },

    @{ Estilo = "Encabezado1"; Texto = "4. Requisitos del enunciado y cumplimiento" },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 1. Debe poder atender un numero indefinido de solicitudes en forma concurrente." },
    @{ Estilo = "Normal"; Texto = "Se cumple mediante el bucle de escucha de Nucleo/ServidorHttp.cs, en el metodo IniciarAsync. El bucle while se mantiene activo mientras no se cancele el servidor. En cada vuelta espera una conexion usando socketEscucha.AcceptAsync(tokenCancelacion). No existe un contador que limite la cantidad total de solicitudes que puede recibir mientras el proceso esta en ejecucion." },
    @{ Estilo = "Normal"; Texto = "Cuando AcceptAsync entrega un socket de cliente, ServidorHttp crea un ManejadorCliente y ejecuta manejador.AtenderAsync dentro de Task.Run. Esa tarea se desprende del bucle de escucha: el servidor vuelve enseguida a aceptar otra conexion. Por eso una descarga, una lectura de archivo o una escritura de log de un cliente no obliga a esperar a los demas clientes." },
    @{ Estilo = "Normal"; Texto = "El metodo ManejadorCliente.AtenderAsync representa el trabajo aislado de una conexion. Recibe los bytes, los interpreta, escribe el log, construye la respuesta y cierra su socket. Las instancias de ManejadorCliente tienen su propio campo _socketCliente, de modo que cada tarea opera sobre el cliente que le corresponde." },
    @{ Estilo = "Normal"; Texto = "Para comprobarlo, iniciar el servidor y lanzar varias solicitudes a la vez desde varias terminales o pestañas. Cada una debe obtener su respuesta sin que la aplicacion deje de aceptar conexiones. El limite real esta dado por recursos del sistema operativo y el backlog de escucha, no por una cantidad fija de solicitudes escrita en el programa." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 2. Por defecto, debera servir el archivo index.html si la URL no especifica el archivo." },
    @{ Estilo = "Normal"; Texto = "Se cumple en Services/ServicioArchivos.cs, metodo privado ResolverRutaSolicitada. Ese metodo recibe la ruta que ya fue extraida de la solicitud HTTP. El analizador entrega la ruta / cuando el navegador solicita la direccion base, por ejemplo http://localhost:8080/." },
    @{ Estilo = "Normal"; Texto = "ResolverRutaSolicitada elimina primero la barra inicial con TrimStart('/'). Si el resultado queda vacio, o si la URL termina en barra, ejecuta Path.Combine(rutaLimpia, 'index.html'). Con una solicitud GET /, rutaLimpia es vacia y el resultado final es index.html. Con GET /carpeta/, el resultado seria carpeta/index.html." },
    @{ Estilo = "Normal"; Texto = "Despues, ObtenerArchivoAsync verifica File.Exists sobre la ruta resultante y lee el contenido con File.ReadAllBytesAsync. El archivo incluido en WebServer/wwwroot/index.html es el recurso que se devuelve por defecto. ManejadorCliente.CrearRespuestaAsync invoca este servicio solo para solicitudes GET." },
    @{ Estilo = "Normal"; Texto = "La prueba mas directa es abrir http://localhost:8080/ o ejecutar curl http://localhost:8080/. El contenido recibido debe coincidir con wwwroot/index.html. Leer primero ResolverRutaSolicitada y luego ObtenerArchivoAsync permite observar la decision y la lectura del archivo en ese orden." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 3. La carpeta desde donde se serviran los archivos debe ser configurable desde un archivo de configuracion externo." },
    @{ Estilo = "Normal"; Texto = "Se cumple mediante WebServer/config.json y Nucleo/ConfiguracionServidor.cs. El archivo JSON contiene la propiedad CarpetaRaiz con el valor inicial wwwroot. Al estar fuera del codigo C#, puede modificarse sin recompilar el proyecto." },
    @{ Estilo = "Normal"; Texto = "En Program.cs, ConfiguracionServidor.Cargar('config.json') lee ese archivo. El metodo Cargar usa File.ReadAllText y JsonSerializer.Deserialize para convertir el texto JSON en un objeto ConfiguracionServidor. Luego Program.cs combina el directorio actual con configuracion.CarpetaRaiz y obtiene una ruta absoluta llamada carpetaPublica." },
    @{ Estilo = "Normal"; Texto = "La variable carpetaPublica se entrega al constructor de ServicioArchivos. Ese servicio guarda la ubicacion en el campo _carpetaRaiz y todas las resoluciones de URL se hacen a partir de ella. Por eso el valor no queda solo almacenado: modifica efectivamente el lugar donde el servidor busca index.html, 404.html y los otros archivos." },
    @{ Estilo = "Normal"; Texto = "Para verificarlo, crear una carpeta alternativa dentro de WebServer, copiar alli index.html y 404.html, cambiar CarpetaRaiz en config.json, reiniciar la aplicacion y solicitar /. La clave del JSON debe escribirse exactamente como CarpetaRaiz, porque coincide con la propiedad publica del modelo ConfiguracionServidor." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 4. El puerto de escucha debe ser configurable desde un archivo de configuracion externo." },
    @{ Estilo = "Normal"; Texto = "Se cumple con el mismo archivo WebServer/config.json. La propiedad Puerto contiene inicialmente 8080. ConfiguracionServidor.Cargar la deserializa y llama al metodo privado Validar, que rechaza valores menores o iguales a cero o mayores que 65535. Esta validacion evita intentar iniciar TCP con un puerto invalido." },
    @{ Estilo = "Normal"; Texto = "Program.cs entrega configuracion.Puerto al constructor de Nucleo/ServidorHttp. En ServidorHttp.IniciarAsync, la instruccion socketEscucha.Bind(new IPEndPoint(IPAddress.Any, _puerto)) asocia el socket al puerto recibido. _puerto no es un numero fijo: proviene del JSON externo." },
    @{ Estilo = "Normal"; Texto = "Cambiar Puerto a 8090, detener y volver a ejecutar el programa hace que el mensaje de consola y el socket escuchen en el nuevo puerto. La direccion de prueba pasa a ser http://localhost:8090/. Si se cambia el archivo mientras el programa ya esta iniciado, es necesario reiniciar: la configuracion se lee al arrancar, no de forma continua." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 5. Si se solicita un archivo inexistente, debera devolver codigo 404 y un documento personalizado." },
    @{ Estilo = "Normal"; Texto = "Se cumple en ServicioArchivos.ObtenerArchivoAsync. Luego de resolver la ruta solicitada, el metodo consulta File.Exists. Si el archivo no existe, busca especificamente wwwroot/404.html mediante Path.Combine(_carpetaRaiz, '404.html'). Ese archivo es la pagina personalizada incluida en el proyecto." },
    @{ Estilo = "Normal"; Texto = "Cuando 404.html existe, el servicio crea un ResultadoArchivo con CodigoEstado = 404, FraseEstado = 'Not Found', el contenido del documento personalizado y tipo text/html. Si incluso 404.html faltara, se mantiene el codigo 404 y se genera un texto simple como respaldo. Asi nunca se convierte un recurso inexistente en una respuesta 200 por error." },
    @{ Estilo = "Normal"; Texto = "ManejadorCliente.CrearRespuestaAsync toma el ResultadoArchivo y lo transforma en RespuestaHttp. Por ultimo, ConstructorRespuestaHttp.Construir escribe la primera linea HTTP/1.1 404 Not Found. El estado y el contenido viajan juntos, por lo que el navegador recibe tanto el codigo correcto como la pagina explicativa." },
    @{ Estilo = "Normal"; Texto = "La prueba es GET /archivo-inexistente.html. Debe verse el HTML de wwwroot/404.html y la respuesta debe informar estado 404. Para seguir el codigo, leer ObtenerArchivoAsync, despues CrearRespuestaAsync y finalmente ConstructorRespuestaHttp.Construir." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 6. Debe aceptar GET y POST. En POST solo deben loguearse los datos recibidos." },
    @{ Estilo = "Normal"; Texto = "El metodo HTTP se obtiene en ProtocoloHttp/AnalizadorSolicitudHttp.cs. Analizar separa la primera linea de la solicitud, por ejemplo POST /formulario HTTP/1.1, y guarda la primera palabra en SolicitudHttp.Metodo. El cuerpo se obtiene en AnalizarCuerpo, que usa Content-Length cuando esta presente para saber cuantos bytes pertenecen al mensaje." },
    @{ Estilo = "Normal"; Texto = "ManejadorCliente.AtenderAsync registra toda solicitud antes de crear su respuesta. Para POST, ManejadorCliente.CrearRespuestaAsync detecta solicitud.Metodo == 'POST' y devuelve una confirmacion HTML. No guarda el cuerpo en una base de datos, no modifica archivos y no procesa reglas de negocio; eso respeta el alcance indicado por la consigna." },
    @{ Estilo = "Normal"; Texto = "ServicioLogs.CrearTextoLog agrega el bloque 'Datos POST:' solamente cuando solicitud.Metodo es POST. Debajo escribe solicitud.Cuerpo, que fue construido por el analizador HTTP. De esa manera el dato recibido queda disponible en el archivo diario de logs." },
    @{ Estilo = "Normal"; Texto = "Puede verificarse con curl -X POST http://localhost:8080/formulario -d 'nombre=Ana&edad=21'. La respuesta confirma la recepcion y el archivo logs/requests-AAAA-MM-DD.log contiene el cuerpo. GET sigue otra ruta: solicita un archivo usando ServicioArchivos." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 7. Debe manejar parametros de consulta desde la URL y solo loguearlos." },
    @{ Estilo = "Normal"; Texto = "Los parametros de consulta se analizan en AnalizadorSolicitudHttp.AnalizarParametrosConsulta. La funcion encuentra el signo ?, toma lo que aparece despues, divide los pares por &, y divide cada par nombre=valor por el primer signo igual. Tambien reemplaza + por espacio y aplica Uri.UnescapeDataString para interpretar caracteres codificados en URL." },
    @{ Estilo = "Normal"; Texto = "El resultado se guarda en SolicitudHttp.ParametrosConsulta, un diccionario con comparacion sin distinguir mayusculas y minusculas. En paralelo, ObtenerRutaSinConsulta elimina esa parte de la URL para que el servicio de archivos no intente buscar un archivo cuyo nombre incluya ?nombre=Juan." },
    @{ Estilo = "Normal"; Texto = "ServicioLogs.CrearTextoLog comprueba ParametrosConsulta.Count. Si hay datos, escribe 'Parametros de consulta:' y recorre el diccionario, agregando una linea por cada nombre y valor. Ninguna otra clase usa esos parametros para cambiar el contenido de la respuesta, por lo que su unico efecto funcional es quedar registrado." },
    @{ Estilo = "Normal"; Texto = "Ejemplo: GET /index.html?nombre=Juan&edad=20 entrega index.html y deja en el log las lineas nombre = Juan y edad = 20. Esta separacion entre ruta y consulta es importante: los parametros describen la solicitud, no la ubicacion fisica del recurso." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 8. Debe utilizar compresion de archivos para responder a las solicitudes." },
    @{ Estilo = "Normal"; Texto = "La compresion esta aislada en Services/ServicioCompresion.cs, metodo Comprimir. Recibe los bytes originales de un recurso, crea un MemoryStream y escribe esos bytes dentro de GZipStream con CompressionLevel.SmallestSize. Cuando GZipStream se cierra, el flujo de memoria contiene el resultado codificado con gzip." },
    @{ Estilo = "Normal"; Texto = "Para GET, ManejadorCliente.CrearRespuestaAsync obtiene el archivo y llama a _servicioCompresion.Comprimir(archivo.Contenido). Para POST tambien utiliza CrearRespuestaHtml, que comprime el mensaje de confirmacion. El objeto RespuestaHttp recibe los bytes comprimidos como Cuerpo y agrega el encabezado Content-Encoding: gzip." },
    @{ Estilo = "Normal"; Texto = "ConstructorRespuestaHttp calcula Content-Length usando respuesta.Cuerpo.Length. Como el cuerpo ya esta comprimido, ese valor representa correctamente el tamano que se envia por la red, no el tamano original del archivo. El navegador usa Content-Encoding para saber que debe descomprimir antes de mostrar el contenido." },
    @{ Estilo = "Normal"; Texto = "Para verificarlo se puede ejecutar curl -I http://localhost:8080/ y observar Content-Encoding: gzip. El codigo relevante debe leerse en este orden: ServicioCompresion.Comprimir, la asignacion de Content-Encoding en CrearRespuestaAsync y la construccion final de encabezados." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 9. Todas las solicitudes deben loguearse en un archivo por dia, incluyendo la IP de origen." },
    @{ Estilo = "Normal"; Texto = "El registro se inicia en ManejadorCliente.AtenderAsync. Despues de analizar los bytes, el metodo llama a ObtenerIpOrigen. Esa funcion consulta _socketCliente.RemoteEndPoint y, si el punto remoto es IPEndPoint, devuelve puntoFinal.Address.ToString(). En una prueba local normalmente aparece 127.0.0.1." },
    @{ Estilo = "Normal"; Texto = "A continuacion se invoca ServicioLogs.RegistrarSolicitudAsync(solicitud, ipOrigen). El servicio construye el nombre de archivo requests-AAAA-MM-DD.log con DateTime.Now y lo ubica en la carpeta logs. Como la fecha es parte del nombre, al cambiar de dia se crea automaticamente otro archivo. Program.cs crea la carpeta logs al iniciar si aun no existe." },
    @{ Estilo = "Normal"; Texto = "CrearTextoLog incorpora fecha y hora, IP de origen, metodo, ruta y version HTTP. Tambien agrega los parametros de consulta y los datos POST cuando corresponden. Esto cumple que todos los datos relevantes de cada solicitud queden inspeccionables luego de la ejecucion." },
    @{ Estilo = "Normal"; Texto = "El campo _bloqueoEscritura es un SemaphoreSlim. RegistrarSolicitudAsync espera ese bloqueo antes de usar File.AppendAllTextAsync y lo libera en finally. Como hay multiples tareas de clientes, este mecanismo evita que dos textos se mezclen dentro del mismo archivo cuando llegan solicitudes concurrentes." },

    @{ Estilo = "Encabezado2"; Texto = "Requisito 10. Solo deben usarse sockets directos y deben parsearse las solicitudes HTTP; no se deben utilizar herramientas adicionales." },
    @{ Estilo = "Normal"; Texto = "El acceso de red se implementa directamente con System.Net.Sockets.Socket en Nucleo/ServidorHttp.cs. El constructor recibe AddressFamily.InterNetwork, SocketType.Stream y ProtocolType.Tcp; esa combinacion representa un socket TCP IPv4. El servidor usa Bind para tomar el puerto, Listen para esperar conexiones y AcceptAsync para aceptar cada cliente." },
    @{ Estilo = "Normal"; Texto = "ManejadorCliente no usa HttpListener, ASP.NET, Kestrel ni un framework web. Lee bytes con _socketCliente.ReceiveAsync. RecibirSolicitudCompletaAsync detecta la secuencia CRLF CRLF, que en HTTP marca el fin de los encabezados, y consulta Content-Length para continuar leyendo hasta completar el cuerpo cuando existe." },
    @{ Estilo = "Normal"; Texto = "El parseo manual ocurre en AnalizadorSolicitudHttp. Lee la linea inicial, analiza los encabezados, separa ruta y consulta, interpreta parametros y extrae el cuerpo. La respuesta tambien se arma manualmente en ConstructorRespuestaHttp, que escribe la linea de estado, Date, Content-Length, los encabezados propios y la separacion vacia antes del cuerpo." },
    @{ Estilo = "Normal"; Texto = "El unico uso de bibliotecas de .NET es de bajo nivel y de proposito general: Socket para transporte TCP, JsonSerializer para el archivo de configuracion, GZipStream para la compresion y File para acceso al disco. Ninguna de ellas recibe o responde HTTP por el proyecto. Esto satisface el requisito de trabajar directamente sobre la capa de transporte y parsear HTTP en codigo propio." },

    @{ Estilo = "Encabezado1"; Texto = "5. Consideraciones de modularizacion" },
    @{ Estilo = "Normal"; Texto = "Cada clase tiene una responsabilidad acotada. ConfiguracionServidor conoce JSON y validaciones; ServidorHttp conoce el socket que escucha; ManejadorCliente conoce el ciclo de una conexion; AnalizadorSolicitudHttp conoce el formato de una solicitud; ConstructorRespuestaHttp conoce el formato de una respuesta; ServicioArchivos conoce el sistema de archivos; ServicioLogs conoce el formato de registro; ServicioCompresion conoce gzip." },
    @{ Estilo = "Normal"; Texto = "Esta division es importante porque permite cambiar una pieza sin reescribir las otras. Por ejemplo, si se quieren agregar tipos MIME, se modifica ServicioTiposMime. Si se desea otro formato de registro, se modifica ServicioLogs. Program.cs solo ensambla las piezas, por lo que permanece corto y facil de leer." },
    @{ Estilo = "Normal"; Texto = "Tambien existe una medida de seguridad en ServicioArchivos.EstaDentroDeCarpetaRaiz. Luego de formar la ruta absoluta, compara que siga dentro de _carpetaRaiz. Una URL como /../secreto.txt no puede salir de la carpeta publica; se redirige al resultado 404. Esta regla no era un requisito expreso, pero protege correctamente el limite de responsabilidad del servidor de archivos." },

    @{ Estilo = "Encabezado1"; Texto = "6. Guia breve de ejecucion y comprobacion" },
    @{ Estilo = "Normal"; Texto = "1. Abrir una terminal dentro de WebServer." },
    @{ Estilo = "Codigo"; Texto = "dotnet run" },
    @{ Estilo = "Normal"; Texto = "2. Abrir http://localhost:8080/ para comprobar index.html." },
    @{ Estilo = "Normal"; Texto = "3. Abrir http://localhost:8080/no-existe.html para comprobar 404.html y el estado 404." },
    @{ Estilo = "Codigo"; Texto = 'curl "http://localhost:8080/index.html?nombre=Juan&edad=20"' },
    @{ Estilo = "Codigo"; Texto = 'curl -X POST http://localhost:8080/formulario -d "nombre=Ana&edad=21"' },
    @{ Estilo = "Normal"; Texto = "4. Revisar logs/requests-AAAA-MM-DD.log. Deben aparecer la IP, los parametros del primer comando y el cuerpo del segundo." },
    @{ Estilo = "Normal"; Texto = "5. Cambiar Puerto o CarpetaRaiz en config.json, detener con Ctrl+C, volver a ejecutar y repetir las pruebas. Reiniciar es necesario porque la configuracion se lee al comienzo de Program.cs." },

    @{ Estilo = "Encabezado1"; Texto = "7. Conclusion" },
    @{ Estilo = "Normal"; Texto = "El proyecto implementa un servidor HTTP educativo sobre sockets TCP directos. La evidencia de cada requisito esta distribuida en clases pequenas y con responsabilidades separadas. El orden de lectura recomendado para entenderlo completamente es Program.cs, ConfiguracionServidor, ServidorHttp, ManejadorCliente, AnalizadorSolicitudHttp, ServicioArchivos, ServicioLogs, ServicioCompresion y ConstructorRespuestaHttp." }
)

$parrafos = foreach ($bloque in $contenido) {
    if ($bloque.Estilo -eq "Salto") {
        "<w:p/>"
    }
    else {
        Crear-ParrafoXml -Texto $bloque.Texto -Estilo $bloque.Estilo
    }
}

$documentoXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$($parrafos -join "`n")<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>
"@

$estilosXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos"/><w:sz w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:after="140" w:line="276" w:lineRule="auto"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Titulo"><w:name w:val="Titulo"/><w:pPr><w:jc w:val="center"/><w:spacing w:before="600" w:after="260"/></w:pPr><w:rPr><w:b/><w:sz w:val="38"/><w:color w:val="1F4E79"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitulo"><w:name w:val="Subtitulo"/><w:pPr><w:jc w:val="center"/><w:spacing w:after="400"/></w:pPr><w:rPr><w:i/><w:sz w:val="24"/><w:color w:val="404040"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Encabezado1"><w:name w:val="Encabezado 1"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="340" w:after="160"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/><w:color w:val="1F4E79"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Encabezado2"><w:name w:val="Encabezado 2"/><w:basedOn w:val="Normal"/><w:pPr><w:keepNext/><w:spacing w:before="260" w:after="120"/></w:pPr><w:rPr><w:b/><w:sz w:val="25"/><w:color w:val="2F5597"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Codigo"><w:name w:val="Codigo"/><w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="360"/><w:spacing w:after="60"/></w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="18"/><w:color w:val="404040"/></w:rPr></w:style>
</w:styles>
"@

$tiposContenidoXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>
"@

$relacionesRaizXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>
"@

$relacionesDocumentoXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>
"@

$fecha = [DateTime]::UtcNow.ToString("s") + "Z"
$propiedadesNucleoXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>Servidor Web Simple en .NET</dc:title><dc:creator>Jorge</dc:creator><dc:description>Documento de cumplimiento detallado de requisitos</dc:description><dcterms:created xsi:type="dcterms:W3CDTF">' + $fecha + '</dcterms:created><dcterms:modified xsi:type="dcterms:W3CDTF">' + $fecha + '</dcterms:modified></cp:coreProperties>'
$propiedadesAplicacionXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>Generador de documentacion del proyecto</Application></Properties>'

function Agregar-EntradaZip {
    param([System.IO.Compression.ZipArchive]$ArchivoZip, [string]$Nombre, [string]$Contenido)

    $entrada = $ArchivoZip.CreateEntry($Nombre)
    $escritor = [System.IO.StreamWriter]::new($entrada.Open(), [System.Text.UTF8Encoding]::new($false))

    try {
        $escritor.Write($Contenido)
    }
    finally {
        $escritor.Dispose()
    }
}

$carpetaSalida = Split-Path -Parent $RutaSalida
if (-not [string]::IsNullOrWhiteSpace($carpetaSalida)) {
    New-Item -ItemType Directory -Path $carpetaSalida -Force | Out-Null
}

$flujoArchivo = [System.IO.File]::Open($RutaSalida, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
$archivoZip = [System.IO.Compression.ZipArchive]::new($flujoArchivo, [System.IO.Compression.ZipArchiveMode]::Create)

try {
    Agregar-EntradaZip $archivoZip "[Content_Types].xml" $tiposContenidoXml
    Agregar-EntradaZip $archivoZip "_rels/.rels" $relacionesRaizXml
    Agregar-EntradaZip $archivoZip "word/document.xml" $documentoXml
    Agregar-EntradaZip $archivoZip "word/styles.xml" $estilosXml
    Agregar-EntradaZip $archivoZip "word/_rels/document.xml.rels" $relacionesDocumentoXml
    Agregar-EntradaZip $archivoZip "docProps/core.xml" $propiedadesNucleoXml
    Agregar-EntradaZip $archivoZip "docProps/app.xml" $propiedadesAplicacionXml
}
finally {
    if ($null -ne $archivoZip) {
        $archivoZip.Dispose()
    }

    $flujoArchivo.Dispose()
}

Write-Host "Documento creado: $RutaSalida"
