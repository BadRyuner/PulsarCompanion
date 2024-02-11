using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PulsarCompanionServer
{
    internal sealed class CachedUTF8Dictionary
    {
        private Dictionary<string, byte[]> Dict = new Dictionary<string, byte[]>(4);

        internal byte[] Get(string text)
        {
            if (Dict.TryGetValue(text, out var bytes))
                return bytes;
            bytes = Encoding.UTF8.GetBytes(text);
            Dict.Add(text, bytes);
            return bytes;
        }
    }
}
