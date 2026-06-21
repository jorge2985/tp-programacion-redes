using System.Text;

namespace ServidorWeb.ProtocoloHttp;

public static class AnalizadorSolicitudHttp
{
    public static SolicitudHttp Analizar(byte[] bytesSolicitud)
    {
        int indiceFinEncabezados = BuscarFinEncabezados(bytesSolicitud);

        if (indiceFinEncabezados < 0)
        {
            throw new InvalidOperationException("La solicitud HTTP no contiene fin de encabezados.");
        }

        string textoEncabezados = Encoding.ASCII.GetString(bytesSolicitud, 0, indiceFinEncabezados);
        string[] lineas = textoEncabezados.Split("\r\n", StringSplitOptions.None);

        // La primera linea tiene este formato:
        // GET /index.html?nombre=Ana HTTP/1.1
        string[] partesLineaInicial = lineas[0].Split(' ', 3, StringSplitOptions.RemoveEmptyEntries);

        if (partesLineaInicial.Length != 3)
        {
            throw new InvalidOperationException("La primera linea HTTP es invalida.");
        }

        Dictionary<string, string> encabezados = AnalizarEncabezados(lineas);
        string rutaCompleta = partesLineaInicial[1];

        return new SolicitudHttp
        {
            Metodo = partesLineaInicial[0].ToUpperInvariant(),
            Ruta = ObtenerRutaSinConsulta(rutaCompleta),
            VersionHttp = partesLineaInicial[2],
            Encabezados = encabezados,
            ParametrosConsulta = AnalizarParametrosConsulta(rutaCompleta),
            Cuerpo = AnalizarCuerpo(bytesSolicitud, indiceFinEncabezados, encabezados)
        };
    }

    private static Dictionary<string, string> AnalizarEncabezados(string[] lineas)
    {
        var encabezados = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        // La linea 0 es la linea inicial. Los encabezados empiezan en la linea 1.
        for (int i = 1; i < lineas.Length; i++)
        {
            string linea = lineas[i];
            int indiceSeparador = linea.IndexOf(':');

            if (indiceSeparador <= 0)
            {
                continue;
            }

            string nombre = linea[..indiceSeparador].Trim();
            string valor = linea[(indiceSeparador + 1)..].Trim();
            encabezados[nombre] = valor;
        }

        return encabezados;
    }

    private static string AnalizarCuerpo(
        byte[] bytesSolicitud,
        int indiceFinEncabezados,
        Dictionary<string, string> encabezados)
    {
        int indiceInicioCuerpo = indiceFinEncabezados + 4;
        int largoDisponible = bytesSolicitud.Length - indiceInicioCuerpo;

        if (largoDisponible <= 0)
        {
            return string.Empty;
        }

        int largoContenido = 0;

        if (encabezados.TryGetValue("Content-Length", out string? valor))
        {
            int.TryParse(valor, out largoContenido);
        }

        int largoCuerpo = largoContenido > 0
            ? Math.Min(largoContenido, largoDisponible)
            : largoDisponible;

        return Encoding.UTF8.GetString(bytesSolicitud, indiceInicioCuerpo, largoCuerpo);
    }

    private static string ObtenerRutaSinConsulta(string rutaCompleta)
    {
        int indiceInicioConsulta = rutaCompleta.IndexOf('?');
        string ruta = indiceInicioConsulta >= 0 ? rutaCompleta[..indiceInicioConsulta] : rutaCompleta;

        return string.IsNullOrWhiteSpace(ruta) ? "/" : Uri.UnescapeDataString(ruta);
    }

    private static Dictionary<string, string> AnalizarParametrosConsulta(string rutaCompleta)
    {
        var parametros = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        int indiceInicioConsulta = rutaCompleta.IndexOf('?');

        if (indiceInicioConsulta < 0 || indiceInicioConsulta == rutaCompleta.Length - 1)
        {
            return parametros;
        }

        string textoConsulta = rutaCompleta[(indiceInicioConsulta + 1)..];
        string[] pares = textoConsulta.Split('&', StringSplitOptions.RemoveEmptyEntries);

        foreach (string par in pares)
        {
            string[] partes = par.Split('=', 2);
            string nombre = Uri.UnescapeDataString(partes[0].Replace('+', ' '));
            string valor = partes.Length > 1
                ? Uri.UnescapeDataString(partes[1].Replace('+', ' '))
                : string.Empty;

            parametros[nombre] = valor;
        }

        return parametros;
    }

    private static int BuscarFinEncabezados(byte[] bytes)
    {
        for (int i = 0; i <= bytes.Length - 4; i++)
        {
            if (bytes[i] == '\r' && bytes[i + 1] == '\n' && bytes[i + 2] == '\r' && bytes[i + 3] == '\n')
            {
                return i;
            }
        }

        return -1;
    }
}
