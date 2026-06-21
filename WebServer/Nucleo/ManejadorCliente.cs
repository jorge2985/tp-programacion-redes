using System.Net;
using System.Net.Sockets;
using System.Text;
using ServidorWeb.ProtocoloHttp;
using ServidorWeb.Servicios;

namespace ServidorWeb.Nucleo;

public sealed class ManejadorCliente
{
    private const int TamanoBuffer = 8192;
    private const int TamanoMaximoSolicitud = 1024 * 1024;

    private readonly Socket _socketCliente;
    private readonly ServicioArchivos _servicioArchivos;
    private readonly ServicioLogs _servicioLogs;
    private readonly ServicioCompresion _servicioCompresion;

    public ManejadorCliente(
        Socket socketCliente,
        ServicioArchivos servicioArchivos,
        ServicioLogs servicioLogs,
        ServicioCompresion servicioCompresion)
    {
        _socketCliente = socketCliente;
        _servicioArchivos = servicioArchivos;
        _servicioLogs = servicioLogs;
        _servicioCompresion = servicioCompresion;
    }

    public async Task AtenderAsync()
    {
        try
        {
            // Recibimos los bytes crudos enviados por el cliente.
            // Todavia no son objetos C#: son texto HTTP viajando sobre TCP.
            byte[] bytesSolicitud = await RecibirSolicitudCompletaAsync();

            if (bytesSolicitud.Length == 0)
            {
                return;
            }

            SolicitudHttp solicitud = AnalizadorSolicitudHttp.Analizar(bytesSolicitud);
            string ipOrigen = ObtenerIpOrigen();

            await _servicioLogs.RegistrarSolicitudAsync(solicitud, ipOrigen);

            RespuestaHttp respuesta = await CrearRespuestaAsync(solicitud);
            byte[] bytesRespuesta = ConstructorRespuestaHttp.Construir(respuesta);

            await _socketCliente.SendAsync(bytesRespuesta, SocketFlags.None);
        }
        catch (Exception excepcion)
        {
            // Ante un error inesperado, se responde HTTP 500 para que el cliente no quede esperando.
            RespuestaHttp respuestaError = CrearRespuestaTextoPlano(500, "Internal Server Error", excepcion.Message);
            byte[] bytesRespuesta = ConstructorRespuestaHttp.Construir(respuestaError);
            await _socketCliente.SendAsync(bytesRespuesta, SocketFlags.None);
        }
        finally
        {
            _socketCliente.CerrarCorrectamente();
        }
    }

    private async Task<byte[]> RecibirSolicitudCompletaAsync()
    {
        using var memoria = new MemoryStream();
        byte[] buffer = new byte[TamanoBuffer];

        do
        {
            int bytesRecibidos = await _socketCliente.ReceiveAsync(buffer, SocketFlags.None);

            if (bytesRecibidos == 0)
            {
                break;
            }

            memoria.Write(buffer, 0, bytesRecibidos);
            byte[] bytesActuales = memoria.ToArray();
            int indiceFinEncabezados = BuscarFinEncabezados(bytesActuales);

            if (indiceFinEncabezados >= 0)
            {
                int largoCuerpoEsperado = ObtenerLargoContenido(bytesActuales, indiceFinEncabezados);
                int largoCuerpoRecibido = bytesActuales.Length - indiceFinEncabezados - 4;

                // Si ya tenemos todos los encabezados y todo el cuerpo, dejamos de leer.
                if (largoCuerpoRecibido >= largoCuerpoEsperado)
                {
                    break;
                }
            }
        }
        while (memoria.Length < TamanoMaximoSolicitud);

        return memoria.ToArray();
    }

    private async Task<RespuestaHttp> CrearRespuestaAsync(SolicitudHttp solicitud)
    {
        if (solicitud.Metodo == "POST")
        {
            // La consigna pide aceptar POST y loguear los datos recibidos.
            // No pide guardar ni procesar esos datos, por eso solo devolvemos confirmacion.
            return CrearRespuestaHtml(200, "OK", "<h1>POST recibido</h1><p>Los datos fueron logueados correctamente.</p>");
        }

        if (solicitud.Metodo != "GET")
        {
            return CrearRespuestaTextoPlano(405, "Method Not Allowed", "Metodo no permitido. Solo se aceptan GET y POST.");
        }

        ResultadoArchivo archivo = await _servicioArchivos.ObtenerArchivoAsync(solicitud.Ruta);
        byte[] cuerpoComprimido = _servicioCompresion.Comprimir(archivo.Contenido);

        return new RespuestaHttp
        {
            CodigoEstado = archivo.CodigoEstado,
            FraseEstado = archivo.FraseEstado,
            Cuerpo = cuerpoComprimido,
            Encabezados =
            {
                ["Content-Type"] = archivo.TipoContenido,
                ["Content-Encoding"] = "gzip"
            }
        };
    }

    private RespuestaHttp CrearRespuestaHtml(int codigoEstado, string fraseEstado, string cuerpoHtml)
    {
        byte[] cuerpo = Encoding.UTF8.GetBytes($"<!doctype html><html lang=\"es\"><body>{cuerpoHtml}</body></html>");
        byte[] cuerpoComprimido = _servicioCompresion.Comprimir(cuerpo);

        return new RespuestaHttp
        {
            CodigoEstado = codigoEstado,
            FraseEstado = fraseEstado,
            Cuerpo = cuerpoComprimido,
            Encabezados =
            {
                ["Content-Type"] = "text/html; charset=utf-8",
                ["Content-Encoding"] = "gzip"
            }
        };
    }

    private static RespuestaHttp CrearRespuestaTextoPlano(int codigoEstado, string fraseEstado, string texto)
    {
        byte[] cuerpo = Encoding.UTF8.GetBytes(texto);

        return new RespuestaHttp
        {
            CodigoEstado = codigoEstado,
            FraseEstado = fraseEstado,
            Cuerpo = cuerpo,
            Encabezados =
            {
                ["Content-Type"] = "text/plain; charset=utf-8"
            }
        };
    }

    private string ObtenerIpOrigen()
    {
        if (_socketCliente.RemoteEndPoint is IPEndPoint puntoFinal)
        {
            return puntoFinal.Address.ToString();
        }

        return "IP desconocida";
    }

    private static int BuscarFinEncabezados(byte[] bytes)
    {
        // En HTTP, los encabezados terminan con la secuencia:
        // retorno de carro + salto de linea + retorno de carro + salto de linea.
        for (int i = 0; i <= bytes.Length - 4; i++)
        {
            if (bytes[i] == '\r' && bytes[i + 1] == '\n' && bytes[i + 2] == '\r' && bytes[i + 3] == '\n')
            {
                return i;
            }
        }

        return -1;
    }

    private static int ObtenerLargoContenido(byte[] bytesSolicitud, int indiceFinEncabezados)
    {
        string textoEncabezados = Encoding.ASCII.GetString(bytesSolicitud, 0, indiceFinEncabezados);
        string[] lineas = textoEncabezados.Split("\r\n");

        foreach (string linea in lineas)
        {
            if (linea.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase))
            {
                string valor = linea["Content-Length:".Length..].Trim();
                return int.TryParse(valor, out int largoContenido) ? largoContenido : 0;
            }
        }

        return 0;
    }
}

internal static class ExtensionesSocket
{
    public static void CerrarCorrectamente(this Socket socket)
    {
        try
        {
            socket.Shutdown(SocketShutdown.Both);
        }
        catch
        {
            // Si el cliente ya cerro la conexion, Shutdown puede fallar.
            // No es grave: de todas formas cerramos el socket abajo.
        }

        socket.Close();
    }
}
