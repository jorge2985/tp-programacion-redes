using System.IO.Compression;

namespace ServidorWeb.Servicios;

public sealed class ServicioCompresion
{
    public byte[] Comprimir(byte[] contenidoOriginal)
    {
        using var flujoSalida = new MemoryStream();

        // GZipStream comprime los bytes antes de enviarlos al cliente.
        // Por eso la respuesta HTTP incluye el encabezado Content-Encoding: gzip.
        using (var flujoGzip = new GZipStream(flujoSalida, CompressionLevel.SmallestSize))
        {
            flujoGzip.Write(contenidoOriginal, 0, contenidoOriginal.Length);
        }

        return flujoSalida.ToArray();
    }
}
