using System.Text;

namespace ServidorWeb.ProtocoloHttp;

public static class ConstructorRespuestaHttp
{
    public static byte[] Construir(RespuestaHttp respuesta)
    {
        var constructorEncabezados = new StringBuilder();

        // Primera linea de una respuesta HTTP:
        // HTTP/1.1 200 OK
        constructorEncabezados.Append($"HTTP/1.1 {respuesta.CodigoEstado} {respuesta.FraseEstado}\r\n");
        constructorEncabezados.Append("Connection: close\r\n");
        constructorEncabezados.Append($"Date: {DateTimeOffset.UtcNow:R}\r\n");
        constructorEncabezados.Append($"Content-Length: {respuesta.Cuerpo.Length}\r\n");

        foreach (KeyValuePair<string, string> encabezado in respuesta.Encabezados)
        {
            constructorEncabezados.Append($"{encabezado.Key}: {encabezado.Value}\r\n");
        }

        // Una linea vacia separa los encabezados del cuerpo de la respuesta.
        constructorEncabezados.Append("\r\n");

        byte[] bytesEncabezados = Encoding.ASCII.GetBytes(constructorEncabezados.ToString());
        byte[] bytesRespuestaCompleta = new byte[bytesEncabezados.Length + respuesta.Cuerpo.Length];

        Buffer.BlockCopy(bytesEncabezados, 0, bytesRespuestaCompleta, 0, bytesEncabezados.Length);
        Buffer.BlockCopy(respuesta.Cuerpo, 0, bytesRespuestaCompleta, bytesEncabezados.Length, respuesta.Cuerpo.Length);

        return bytesRespuestaCompleta;
    }
}
