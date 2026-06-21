using System.Text;
using ServidorWeb.ProtocoloHttp;

namespace ServidorWeb.Servicios;

public sealed class ServicioLogs
{
    private readonly string _carpetaLogs;
    private readonly SemaphoreSlim _bloqueoEscritura = new(1, 1);

    public ServicioLogs(string carpetaLogs)
    {
        _carpetaLogs = carpetaLogs;
    }

    public async Task RegistrarSolicitudAsync(SolicitudHttp solicitud, string ipOrigen)
    {
        // Se crea un archivo por dia, como pide la consigna.
        string rutaArchivo = Path.Combine(_carpetaLogs, $"requests-{DateTime.Now:yyyy-MM-dd}.log");
        string textoLog = CrearTextoLog(solicitud, ipOrigen);

        // Varias solicitudes pueden llegar al mismo tiempo.
        // Este bloqueo evita que dos tareas escriban mezcladas en el mismo archivo.
        await _bloqueoEscritura.WaitAsync();

        try
        {
            await File.AppendAllTextAsync(rutaArchivo, textoLog);
        }
        finally
        {
            _bloqueoEscritura.Release();
        }
    }

    private static string CrearTextoLog(SolicitudHttp solicitud, string ipOrigen)
    {
        var constructor = new StringBuilder();

        constructor.AppendLine("========================================");
        constructor.AppendLine($"Fecha y hora: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        constructor.AppendLine($"IP de origen: {ipOrigen}");
        constructor.AppendLine($"Metodo: {solicitud.Metodo}");
        constructor.AppendLine($"Ruta: {solicitud.Ruta}");
        constructor.AppendLine($"Version HTTP: {solicitud.VersionHttp}");

        if (solicitud.ParametrosConsulta.Count > 0)
        {
            constructor.AppendLine("Parametros de consulta:");

            foreach (KeyValuePair<string, string> parametro in solicitud.ParametrosConsulta)
            {
                constructor.AppendLine($"  {parametro.Key} = {parametro.Value}");
            }
        }

        if (solicitud.Metodo == "POST")
        {
            constructor.AppendLine("Datos POST:");
            constructor.AppendLine(string.IsNullOrWhiteSpace(solicitud.Cuerpo) ? "  Sin cuerpo recibido." : solicitud.Cuerpo);
        }

        constructor.AppendLine();
        return constructor.ToString();
    }
}
