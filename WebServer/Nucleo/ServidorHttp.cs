using System.Net;
using System.Net.Sockets;
using ServidorWeb.Servicios;

namespace ServidorWeb.Nucleo;

public sealed class ServidorHttp
{
    private readonly int _puerto;
    private readonly ServicioArchivos _servicioArchivos;
    private readonly ServicioLogs _servicioLogs;
    private readonly ServicioCompresion _servicioCompresion;

    public ServidorHttp(
        int puerto,
        ServicioArchivos servicioArchivos,
        ServicioLogs servicioLogs,
        ServicioCompresion servicioCompresion)
    {
        _puerto = puerto;
        _servicioArchivos = servicioArchivos;
        _servicioLogs = servicioLogs;
        _servicioCompresion = servicioCompresion;
    }

    public async Task IniciarAsync(CancellationToken tokenCancelacion)
    {
        // Este Socket es el punto central del servidor.
        // AddressFamily.InterNetwork indica IPv4.
        // SocketType.Stream indica TCP orientado a conexion.
        // ProtocolType.Tcp confirma que usamos TCP como protocolo de transporte.
        using var socketEscucha = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);

        // Bind asocia el socket al puerto configurado.
        socketEscucha.Bind(new IPEndPoint(IPAddress.Any, _puerto));

        // Listen deja el socket esperando conexiones entrantes.
        socketEscucha.Listen(backlog: 100);

        while (!tokenCancelacion.IsCancellationRequested)
        {
            Socket socketCliente;

            try
            {
                // AcceptAsync se queda esperando hasta que un navegador o cliente se conecte.
                socketCliente = await socketEscucha.AcceptAsync(tokenCancelacion);
            }
            catch (OperationCanceledException)
            {
                break;
            }

            // Cada cliente se atiende en una tarea separada.
            // Asi una solicitud lenta no bloquea a las demas solicitudes.
            var manejador = new ManejadorCliente(
                socketCliente,
                _servicioArchivos,
                _servicioLogs,
                _servicioCompresion);

            _ = Task.Run(() => manejador.AtenderAsync(), CancellationToken.None);
        }
    }
}
