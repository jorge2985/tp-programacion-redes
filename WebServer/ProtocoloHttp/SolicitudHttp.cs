namespace ServidorWeb.ProtocoloHttp;

public sealed class SolicitudHttp
{
    public string Metodo { get; init; } = string.Empty;

    public string Ruta { get; init; } = "/";

    public string VersionHttp { get; init; } = "HTTP/1.1";

    public Dictionary<string, string> Encabezados { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public Dictionary<string, string> ParametrosConsulta { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public string Cuerpo { get; init; } = string.Empty;
}
