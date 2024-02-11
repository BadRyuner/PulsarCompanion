using PulsarModLoader;
using PulsarModLoader.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Server;

namespace PulsarCompanionServer
{
    internal sealed class Server : WebSocketBehavior
    {
        internal static Server Instance;
        internal static SaveValue<int> PORT = new SaveValue<int>("WebsocketPORT", 7894);
        internal static WebSocketServer Socket;
        internal static Mode Mode;

        private static MemoryStream Buffer = new MemoryStream(1024 * 4);
        private static BinaryWriter Writer = new BinaryWriter(Buffer);

        public Server() { Instance = this; }

        internal static void Start()
        {
            if (Socket != null)
                Socket.Stop();

            Socket = new WebSocketServer(PORT.Value);
            Socket.AddWebSocketService<Server>("/pulsar");
            Socket.Start();
        }

        internal static void Stop()
        {
            Socket.Stop();
            Socket = null;
        }

        public override void OnOpen()
        {
            Messaging.Notification("PulsarCompanion: Connected");
        }

        public override void OnMessage(MessageEventArgs e)
        {
            //if (e.RawData.Length > 1) throw new Exception($"e.RawData.Length = {e.RawData.Length} != 1");
            
            byte b = e.RawData[0];

            Mode callback = (Mode)b;
#if DEBUG
            Messaging.Notification($"{e.RawData.Length} : {callback.ToString()}");
#endif

            if (b > 100) // no state changes
            {
                var ship = PLEncounterManager.Instance.PlayerShip;
                if (callback == Mode.ClickOC)
                {
                    ship.photonView.RPC("SetReactorOCStatus", PhotonTargets.All, new object[] { !ship.Reactor_OCActive });
                }
                else if (callback == Mode.ChangedEngBar || callback == Mode.ChangedSciBar || callback == Mode.ChangedShiBar 
                    || callback == Mode.ChangedWeaBar || callback == Mode.ChangedTotBar)
                {
                    var value = BitConverter.ToSingle(e.RawData, 1);
                    PLServer.Instance.photonView.RPC("SetShipPowerLevel", PhotonTargets.MasterClient, new object[]
                    {
                        ship.ShipID,
                        (int)(b - 102),
                        value,
                        true
                    });
                }
                return;
            }

            Mode = callback;

            if (Mode == Mode.RequestMapData)
            {
                SendMapData();
                Mode = Mode.ListenMapUpdates;
            }
            else if (Mode == Mode.RequestLogs)
            {
                SendLogs();
                Mode = Mode.ListenLogs;
            }
        }

        private static byte[] Cached_NA = Encoding.UTF8.GetBytes("N/A");
        private static byte[] Cached_INMELTDOWN = Encoding.UTF8.GetBytes("IN MELTDOWN");
        private static byte[] Cached_CRITICAL = Encoding.UTF8.GetBytes("CRITICAL");
        private static byte[] Cached_TEMPHIGH = Encoding.UTF8.GetBytes("TEMP HIGH");
        private static byte[] Cached_OK = Encoding.UTF8.GetBytes("OK");

        private static byte[] Cached_ONLINE = Encoding.UTF8.GetBytes("ONLINE");
        private static byte[] Cached_OFFLINE = Encoding.UTF8.GetBytes("OFFLINE");

        private static byte[] Cached_0dot0 = Encoding.UTF8.GetBytes("0.0");

        internal void SendCaptainScreen(PLCaptainScreen self)
        {
            ResetBuffer();
            Writer.Write((byte)1); // update_status id

            var myship = self.MyScreenHubBase.OptionalShipInfo;
            for(int i = 0; i < 2; i++)
            {
                var ship = i == 0 ? myship : self.selectedEnemyShip;
                if (i == 1)
                {
                    byte ok = ship == null ? (byte)0 : (byte)1;
                    Writer.Write(ok);
                    if (ok == 0) break;
                }

                Writer.WriteUTF8(ship.ShipName); // todo: add cache?

                for (int x = 0; x < 4; x++)
                {
                    try
                    {
                        var sys = ship.GetSystemFromID(x);
                        if (sys != null)
                        {
                            Writer.Write((byte)sys.Health);
                            Writer.Write((byte)sys.MaxHealth);
                            Writer.Write((byte)(sys.IsOnFire() ? 1 : 0));
                        }
                        else
                            Writer.Write((byte)120); // -
                    }
                    catch
                    {
                        Messaging.Notification("CANT GET SYS WITH ID " + x);
                        Writer.Write((byte)120); // -
                    }
                }

                Writer.WriteUTF8(self.ShldRight[i].text);
                Writer.WriteUTF8(self.HullRight[i].text);

                if (ship.IsInfected)
                    Writer.WriteArray(Cached_NA);
                else if (ship.IsReactorInMeltdown())
                    Writer.WriteArray(Cached_INMELTDOWN);
                else if (ship.IsReactorTempCritical())
                    Writer.WriteArray(Cached_CRITICAL);
                else if (ship.IsReactorOverheated())
                    Writer.WriteArray(Cached_OFFLINE);
                else if (ship.MyStats?.ReactorTempCurrent / ship.MyStats?.ReactorTempMax >= 0.75f)
                    Writer.WriteArray(Cached_TEMPHIGH);
                else
                    Writer.WriteArray(Cached_OK);

                if (ship.IsInfected)
                    Writer.WriteArray(Cached_NA);
                else if (ship.IsQuantumShieldActive)
                    Writer.WriteArray(Cached_ONLINE);
                else
                    Writer.WriteArray(Cached_OFFLINE);

                if (ship.LifeSupportSystem == null)
                    Writer.WriteArray(Cached_0dot0);
                else
                    Writer.WriteUTF8(ship.LifeSupportSystem.OxygenLevelDeltaSmooth.ToString("F1"));
            }

            SendBuffer();
        }

        internal static CachedUTF8Dictionary ReactorNames = new CachedUTF8Dictionary();
        internal void SendEngScreen(PLEngineerReactorScreen self)
        {
            ResetBuffer();

            var reactor = self.MyReactor;
            var stats = reactor.m_ShipStats;

            Writer.Write((byte)2); // update_eng_screen id

            Writer.WriteArray(ReactorNames.Get(self.TitleLabel.text));
            Writer.Write(stats.ReactorTempMax);
            Writer.Write(stats.ReactorTempCurrent);
            Writer.Write((byte)Mathf.FloorToInt(Mathf.Clamp01(1f - self.MyScreenHubBase.OptionalShipInfo.CoreInstability) * 100f));
            Writer.Write(self.MyScreenHubBase.OptionalShipInfo.Reactor_OCActive ? (byte)1 : (byte)0);

            for (int i = 0; i <= 4; i++)
            {
                //Writer.Write(stats.GetMaxUsageOfConduitID(i));
                Writer.Write(PLReactor.GetPowerLevelOfType(stats, i)); // usage
                Writer.Write(self.m_EditableBar[i].MyLimit); // slider
            }

            SendBuffer();
        }

        private void SendMapData()
        {
            ResetBuffer();
            Writer.Write((byte)10);
            var dict = PLGlobal.Instance.Galaxy.AllSectorInfos.Where(kv => PLStarmap.ShouldShowSector(kv.Value));
            Writer.Write(dict.Count());
            foreach (var sec in dict)
            {
                var val = sec.Value;
                Writer.Write(val.m_Position.x);
                Writer.Write(val.m_Position.y);
                Writer.Write(val.ID);
                Writer.Write(val.Type);
                switch(val.VisualIndication)
                {
                    case ESectorVisualIndication.EXOTIC1:
                    case ESectorVisualIndication.EXOTIC2:
                    case ESectorVisualIndication.EXOTIC3:
                    case ESectorVisualIndication.EXOTIC4:
                    case ESectorVisualIndication.EXOTIC5:
                    case ESectorVisualIndication.EXOTIC6:
                    case ESectorVisualIndication.EXOTIC7: Writer.Write((byte)0); break;

                    case ESectorVisualIndication.GENERAL_STORE: Writer.Write((byte)1); break;

                    case ESectorVisualIndication.AOG_HUB:
                    case ESectorVisualIndication.COLONIAL_HUB:
                    case ESectorVisualIndication.CORNELIA_HUB:
                    case ESectorVisualIndication.DESERT_HUB:
                    case ESectorVisualIndication.PT_HUB: Writer.Write((byte)2); break;

                    case ESectorVisualIndication.GWG: Writer.Write((byte)4); break;

                    default: 
                        if (val.MissionSpecificID != 0)
                            Writer.Write((byte)3); 
                        else
                            Writer.Write((byte)5);
                        break;
                }
                Writer.Write((byte)val.MySPI.Faction);
                Writer.WriteUTF8(val.Name);
            }

            SendBuffer();
        }

        public void SendLogs()
        {
            ResetBuffer();

            Writer.Write((byte)4); // update_logs id

            Writer.WriteLongUTF8(PLServer.Instance.ShipLog.Replace('<', '[').Replace('>', ']').Replace("FF'", string.Empty).Replace("'", string.Empty));
            Writer.WriteLongUTF8(PLServer.Instance.ShipLogRight.Replace('<', '[').Replace('>', ']').Replace("FF'", string.Empty).Replace("'", string.Empty));

            SendBuffer();
        }

        private void SendBuffer()
        {
            var len = Buffer.Position;
            Buffer.Position = 0;
            this.SendAsync(Buffer, (int)len, Okay);
        }

        private static void Okay(bool b) { }

        private static void ResetBuffer()
        {
            Buffer.Position = 0;
        }
    }

    internal enum Mode : byte
    {
        ListenCaptainScreen = 1,
        ListenReactor = 2,
        ListenScience = 3,

        RequestLogs = 4,
        ListenLogs = 5,

        RequestMapData = 10,
        ListenMapUpdates = 11,

        ClickOC = 101,
        ChangedEngBar = 102,
        ChangedSciBar = 103,
        ChangedShiBar = 104,
        ChangedWeaBar = 105,
        ChangedTotBar = 106,
    }

    internal static class Extensions
    {
        public static void WriteUTF8(this BinaryWriter bw, string str)
        {
            if (str.IsNullOrEmpty())
            {
                bw.Write((short)0);
                return;
            }
            var name = Encoding.UTF8.GetBytes(str);
            bw.Write((short)name.Length);
            bw.Write(name);
        }

        public static void WriteLongUTF8(this BinaryWriter bw, string str)
        {
            if (str.IsNullOrEmpty())
            {
                bw.Write((int)0);
                return;
            }
            var name = Encoding.UTF8.GetBytes(str);
            bw.Write((int)name.Length);
            bw.Write(name);
        }

        public static void WriteArray(this BinaryWriter bw, byte[] bytes)
        {
            bw.Write((short)bytes.Length);
            bw.Write(bytes);
        }
    }
}
