using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WebSocketSharp;

namespace TestSockets
{
    internal class Program
    {
        static void Main(string[] args)
        {
            using (var ws = new WebSocket("ws://localhost:7894/pulsar"))
            {
                ws.OnMessage += (mes, e) =>
                {
                    Console.WriteLine($"New Message with len {e.Data.Length}!");
                };
                ws.OnError += (mes, e) => Console.WriteLine($"ERROR {e.Message}\n{e.Exception}");
                ws.OnOpen += (mes, e) => Console.WriteLine($"Open {e}");
                ws.OnClose += (mes, e) => Console.WriteLine($"Close {e}");

                ws.Connect();
                ws.Send(new byte[] { 1 });
                Console.ReadKey();
            }
        }
    }
}
