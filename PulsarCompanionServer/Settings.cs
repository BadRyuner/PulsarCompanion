using System;
using PulsarModLoader;
using PulsarModLoader.CustomGUI;
using PulsarModLoader.Utilities;
using static UnityEngine.GUILayout;

namespace PulsarCompanionServer
{
    internal sealed class Settings : ModSettingsMenu
    {
        public override string Name() => "Pulsar Companion";

        public string port = Server.PORT.Value.ToString();

        public override void Draw()
        {
            if (Button(Mod.ServerAutoStart.Value ? "Server Autostart: ON" : "Server Autostart: OFF"))
                Mod.ServerAutoStart.Value = !Mod.ServerAutoStart.Value;
            BeginHorizontal();
            {
                Label("Websocket PORT");
                port = TextField(port);
                if (Button("Change"))
                    Server.PORT.Value = (int)Convert.ToUInt32(port);
            }
            EndHorizontal();

            BeginHorizontal();
            {
                Label("Current status: ");
                Label(Server.Socket == null ? "Stopped" : "Launched");
                if (Server.Socket == null)
                {
                    if (Button("Start")) Server.Start();
                }
                else if (Button("Stop")) Server.Stop();
            }
            EndHorizontal();
            if (Button("Copy connection url"))
                Clipboard.Copy($"ws://127.0.0.1:{port}/pulsar");
        }
    }
}
