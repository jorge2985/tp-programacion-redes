namespace ServidorWeb.Servicios;

public sealed class ServicioArchivos
{
    private readonly string _carpetaRaiz;

    public ServicioArchivos(string carpetaRaiz)
    {
        _carpetaRaiz = Path.GetFullPath(carpetaRaiz);
    }

    public async Task<ResultadoArchivo> ObtenerArchivoAsync(string rutaSolicitada)
    {
        string rutaArchivo = ResolverRutaSolicitada(rutaSolicitada);

        if (File.Exists(rutaArchivo))
        {
            return new ResultadoArchivo
            {
                CodigoEstado = 200,
                FraseEstado = "OK",
                Contenido = await File.ReadAllBytesAsync(rutaArchivo),
                TipoContenido = ServicioTiposMime.ObtenerTipoContenido(rutaArchivo)
            };
        }

        string rutaNoEncontrado = Path.Combine(_carpetaRaiz, "404.html");

        if (File.Exists(rutaNoEncontrado))
        {
            return new ResultadoArchivo
            {
                CodigoEstado = 404,
                FraseEstado = "Not Found",
                Contenido = await File.ReadAllBytesAsync(rutaNoEncontrado),
                TipoContenido = "text/html; charset=utf-8"
            };
        }

        return new ResultadoArchivo
        {
            CodigoEstado = 404,
            FraseEstado = "Not Found",
            Contenido = System.Text.Encoding.UTF8.GetBytes("404 - Archivo no encontrado"),
            TipoContenido = "text/plain; charset=utf-8"
        };
    }

    private string ResolverRutaSolicitada(string rutaSolicitada)
    {
        // Las URLs usan '/', pero Windows usa '\'. Convertimos la ruta al formato del sistema.
        string rutaLimpia = rutaSolicitada.TrimStart('/');

        // Si el usuario pide "/" o una carpeta, se responde index.html por defecto.
        if (string.IsNullOrWhiteSpace(rutaLimpia) || rutaSolicitada.EndsWith('/'))
        {
            rutaLimpia = Path.Combine(rutaLimpia, "index.html");
        }

        rutaLimpia = rutaLimpia.Replace('/', Path.DirectorySeparatorChar);
        string rutaCompleta = Path.GetFullPath(Path.Combine(_carpetaRaiz, rutaLimpia));

        // Evita path traversal: una URL como /../secreto.txt no puede salir de wwwroot.
        if (!EstaDentroDeCarpetaRaiz(rutaCompleta))
        {
            return Path.Combine(_carpetaRaiz, "404.html");
        }

        return rutaCompleta;
    }

    private bool EstaDentroDeCarpetaRaiz(string rutaCompleta)
    {
        string carpetaNormalizada = Path.TrimEndingDirectorySeparator(_carpetaRaiz);
        string rutaNormalizada = Path.TrimEndingDirectorySeparator(rutaCompleta);

        return rutaNormalizada.Equals(carpetaNormalizada, StringComparison.OrdinalIgnoreCase)
            || rutaNormalizada.StartsWith(carpetaNormalizada + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase);
    }
}

public sealed class ResultadoArchivo
{
    public int CodigoEstado { get; init; }

    public string FraseEstado { get; init; } = string.Empty;

    public byte[] Contenido { get; init; } = Array.Empty<byte>();

    public string TipoContenido { get; init; } = "application/octet-stream";
}
