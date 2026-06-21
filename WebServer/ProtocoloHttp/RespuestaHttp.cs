namespace ServidorWeb.ProtocoloHttp;

public sealed class RespuestaHttp
{
    public int CodigoEstado { get; init; }

    public string FraseEstado { get; init; } = string.Empty;

    public Dictionary<string, string> Encabezados { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public byte[] Cuerpo { get; init; } = Array.Empty<byte>();
}
