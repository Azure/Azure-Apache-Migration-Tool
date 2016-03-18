using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LAMP_MigrateAssistant.Helper;

namespace LAMP_MigrateAssistant.Models
{
    static class Global
    {
        private static string _apacheConfig = "";

        public static string ApacheConfig
        {
            get { return _apacheConfig; }
            set { _apacheConfig = value; }
        }

        public static string[] ApacheConfigs = { "/etc/apache2/apache2.conf", "/etc/httpd/conf/httpd.conf", "/etc/apache2/httpd.conf", "/etc/xxx.conf" };

        public static List<ApacheSite> ApacheSiteList = new List<ApacheSite>();

        public static SSHHelper sshHelper;
        public static string homeFolder = "";
        public static string subfolder = "aamt";
        public static UserProfile userInfo;
    }



    public class ApacheSite
    {
        private string _siteName;
        public string SiteName
        {
            get { return _siteName; }
            set { _siteName = value; }
        }
        private int _siteId;

        public int SiteId
        {
            get { return _siteId; }
            set { _siteId = value; }
        }
      
        public bool IsMigCandidate = false;

        private bool _ifHasDB;
        public bool ifHasDB
        {
            get { return _ifHasDB; }
            set { _ifHasDB = value; }
        }

        public override string ToString()
        {
            return this.SiteName;
        }

    }
    public class UserProfile
    {
        private string _host;
        private string _username;
        private string _password;
        private string _port;

        public UserProfile(string host,string port,string username,string password)
        {
            _host = host;
            _port = port;
            _username = username;
            _password = password;
        }
        public string Host
        {
            get { return _host; }
            set { _host = value; }
        }
        public string Username
        {
            get { return _username; }
            set { _username = value; }
        }
        public string Password
        {
            get { return _password; }
            set { _password = value; }
        }

        public string Port
        {
            get { return _port; }
            set { _port = value; }
        }
    }
}
