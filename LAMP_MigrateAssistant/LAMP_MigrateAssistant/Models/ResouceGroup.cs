using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LAMP_MigrateAssistant.Models
{
    public class ResouceGroupList
    {
        public List<ResouceGroup> value { get; set; }
    }

    public class ResouceGroup{
        public string id { get; set; }
        public string name { get; set; }
        public string location { get; set; }
        public Properties properties { get; set; } 

    }

    public class Properties {
        public string provisioningState {get; set;}
    }


    public class ReouceList
    {
        public List<Resouce> value { get; set; }
    }
    public class Resouce{
        public string id { get; set; }
        public string name { get; set; }
        public string type { get; set; }
        public string location { get; set; }
        public List<Dictionary<string, string>> tags { get; set; }
        public List<Dictionary<string, string>> plan { get; set; }
    }
}
