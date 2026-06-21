using ServidorWeb.Nucleo;
using ServidorWeb.Servicios;

// Nombre del archivo externo desde donde se lee el puerto y la carpeta publica.
const string nombreArchivoConfiguracion = "config.json";

try
{
    // 1) Cargamos la configuracion antes de iniciar el servidor.
    // Si el archivo no existe o tiene datos invalidos, el programa informa el error y termina.
    ConfiguracionServidor configuracion = ConfiguracionServidor.Cargar(nombreArchivoConfiguracion);

    // Directory.GetCurrentDirectory() apunta a la carpeta desde donde se ejecuta el programa.
    // Al usar "dotnet run" desde WebServer, config.json, wwwroot y logs quedan juntos.
    string carpetaBase = Directory.GetCurrentDirectory();
    string carpetaPublica = Path.GetFullPath(Path.Combine(carpetaBase, configuracion.CarpetaRaiz));
    string carpetaLogs = Path.Combine(carpetaBase, "logs");

    // Creamos las carpetas si no existen. Esto evita errores al iniciar por primera vez.
    Directory.CreateDirectory(carpetaPublica);
    Directory.CreateDirectory(carpetaLogs);

    // Cada servicio tiene una responsabilidad concreta.
    // Esto respeta la modularizacion y hace mas facil entender o modificar el codigo.
    var servicioArchivos = new ServicioArchivos(carpetaPublica);
    var servicioLogs = new ServicioLogs(carpetaLogs);
    var servicioCompresion = new ServicioCompresion();
    var servidor = new ServidorHttp(configuracion.Puerto, servicioArchivos, servicioLogs, servicioCompresion);

    Console.WriteLine("Servidor web simple iniciado.");
    Console.WriteLine($"Puerto: {configuracion.Puerto}");
    Console.WriteLine($"Direccion: http://localhost:{configuracion.Puerto}/");
    Console.WriteLine($"Carpeta de archivos: {carpetaPublica}");
    Console.WriteLine("Presione Ctrl + C para detener.");

    using var origenCancelacion = new CancellationTokenSource();

    // Ctrl + C no cierra el proceso de golpe: primero avisamos al servidor que debe detenerse.
    Console.CancelKeyPress += (_, argumentosEvento) =>
    {
        argumentosEvento.Cancel = true;
        origenCancelacion.Cancel();
    };

    await servidor.IniciarAsync(origenCancelacion.Token);
}
catch (Exception excepcion)
{
    Console.WriteLine("No se pudo iniciar el servidor.");
    Console.WriteLine(excepcion.Message);
}
