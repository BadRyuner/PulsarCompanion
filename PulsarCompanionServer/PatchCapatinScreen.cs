using System;
using HarmonyLib;
using PulsarModLoader.Utilities;

namespace PulsarCompanionServer
{
    [HarmonyPatch(typeof(PLCaptainScreen), nameof(PLCaptainsChair.Update))]
    static class PatchCapatinScreen
    {
        static void Postfix(PLCaptainScreen __instance)
        {
            try
            {
                if (Server.Socket != null && Server.Mode == Mode.ListenCaptainScreen && __instance.MyScreenHubBase?.OptionalShipInfo?.GetIsPlayerShip() == true && !__instance.firstFrame)
                {
                    Server.Instance.SendCaptainScreen(__instance);
                }
            }
            catch(Exception e)
            {
#if DEBUG
                Messaging.Notification("Unexpected thing +_+");
                Logger.Info(e.ToString());
#endif
            }
        }
    }
}
