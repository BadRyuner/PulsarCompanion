using System;
using HarmonyLib;
using PulsarModLoader.Utilities;

namespace PulsarCompanionServer
{
    [HarmonyPatch(typeof(PLEngineerReactorScreen), nameof(PLEngineerReactorScreen.Update))]
    internal sealed class PatchReactorScreen
    {
        internal static void Postfix(PLEngineerReactorScreen __instance)
        {
            try
            {
                if (Server.Socket != null && Server.Mode == Mode.ListenReactor && __instance.MyScreenHubBase?.OptionalShipInfo?.GetIsPlayerShip() == true)
                {
                    Server.Instance.SendEngScreen(__instance);
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
