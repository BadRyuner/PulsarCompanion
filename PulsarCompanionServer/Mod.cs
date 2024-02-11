using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using PulsarModLoader;

namespace PulsarCompanionServer
{
    public sealed class Mod : PulsarMod
    {
        internal static SaveValue<bool> ServerAutoStart = new SaveValue<bool>("ServerAutoStart", false);

        public override string HarmonyIdentifier() => "Badryuner.PulsarCompanion";
        public override string Name => "Pulsar Companion";
        public override string Author => "Badryuner";
        public override string Version => "1.0";
        public override int MPRequirements => 0;

        public Mod()
        {
            if (ServerAutoStart.Value)
                Server.Start();
        }

        public override bool CanBeDisabled() => false;
    }
}
