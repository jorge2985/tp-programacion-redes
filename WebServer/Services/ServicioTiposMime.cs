namespace ServidorWeb.Servicios;

public static class ServicioTiposMime
{
    public static string ObtenerTipoContenido(string rutaArchivo)
    {
        string extension = Path.GetExtension(rutaArchivo).ToLowerInvariant();

        // Content-Type le dice al navegador que tipo de archivo esta recibiendo.
        return extension switch
        {
            ".html" or ".htm" => "text/html; charset=utf-8",
            ".css" => "text/css; charset=utf-8",
            ".js" => "application/javascript; charset=utf-8",
            ".json" => "application/json; charset=utf-8",
            ".txt" => "text/plain; charset=utf-8",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif" => "image/gif",
            ".svg" => "image/svg+xml",
            ".ico" => "image/x-icon",
            ".pdf" => "application/pdf",
            _ => "application/octet-stream"
        };
    }
}
