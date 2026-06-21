using System.Text.Json;

namespace ServidorWeb.Nucleo;

public sealed class ConfiguracionServidor
{
    public int Puerto { get; set; } = 8080;

    public string CarpetaRaiz { get; set; } = "wwwroot";

    public static ConfiguracionServidor Cargar(string rutaArchivo)
    {
        // La configuracion esta fuera del codigo para que el usuario pueda cambiar
        // el puerto o la carpeta publica sin recompilar el proyecto.
        if (!File.Exists(rutaArchivo))
        {
            throw new FileNotFoundException($"No se encontro el archivo de configuracion: {rutaArchivo}");
        }

        string textoJson = File.ReadAllText(rutaArchivo);
        ConfiguracionServidor? configuracion = JsonSerializer.Deserialize<ConfiguracionServidor>(textoJson);

        if (configuracion is null)
        {
            throw new InvalidOperationException("El archivo de configuracion esta vacio o tiene formato invalido.");
        }

        Validar(configuracion);
        return configuracion;
    }

    private static void Validar(ConfiguracionServidor configuracion)
    {
        // TCP permite puertos entre 1 y 65535.
        if (configuracion.Puerto <= 0 || configuracion.Puerto > 65535)
        {
            throw new InvalidOperationException("El puerto debe estar entre 1 y 65535.");
        }

        if (string.IsNullOrWhiteSpace(configuracion.CarpetaRaiz))
        {
            throw new InvalidOperationException("La carpeta raiz no puede estar vacia.");
        }
    }
}
