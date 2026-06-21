# Servidor Web Simple

Aplicacion de consola en .NET 8 que implementa un servidor HTTP basico usando sockets TCP directamente.

## Como ejecutar

Desde la carpeta `WebServer`:

```powershell
dotnet run
```

Luego abrir en el navegador:

```text
http://localhost:8080/
```

## Configuracion

El archivo `config.json` permite cambiar el puerto y la carpeta desde donde se sirven los archivos:

```json
{
  "Port": 8080,
  "RootDirectory": "wwwroot"
}
```

## Pruebas sugeridas

```powershell
curl http://localhost:8080/
curl http://localhost:8080/index.html
curl http://localhost:8080/no-existe.html
curl "http://localhost:8080/index.html?nombre=Juan&edad=20"
curl -X POST http://localhost:8080/formulario -d "nombre=Ana&edad=21"
```

Los logs se guardan en la carpeta `logs`, con un archivo por dia.
