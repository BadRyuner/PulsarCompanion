using HarmonyLib;
using PulsarModLoader.Utilities;
using System;

namespace PulsarCompanionServer
{
    [HarmonyPatch(typeof(PLServer), nameof(PLServer.AddToShipLog))]
    internal sealed class PatchShipLog
    {
        private static void Postfix()
        {
            try
            {
                if (Server.Socket != null && Server.Mode == Mode.ListenLogs)
                {
                    Server.Instance.SendLogs();
                }
            }
            catch (Exception e)
            {
#if DEBUG
                Messaging.Notification("Unexpected thing +_+");
                Logger.Info(e.ToString());
#endif
            }
        }
    }
}
