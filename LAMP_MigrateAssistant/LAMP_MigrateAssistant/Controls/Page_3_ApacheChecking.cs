using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using LAMP_MigrateAssistant.Helper;
using System.IO;
using Renci.SshNet;
using System.Threading;
using LAMP_MigrateAssistant.Models;
using System.Text.RegularExpressions;
using System.Reflection;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_3_ApacheChecking : UserControl
    {
        private BackgroundWorker _worker;
        private string _content="";
        private const string srcgzname = "LAMP_MigrateAssistant.aamt.tar.gz";
        private const string dstgzname = "/aamt.tar.gz";
        private string conf_find_sh = "[ -f {0} ] && echo \"found\" || echo \"Not found\"";
        private string listsites_sh = "{0}/listsites {1} {2}";

        public Page_3_ApacheChecking()
        {
            InitializeComponent();
            this.rtbContent.Text = "";
            this.btNext.Enabled = false;
            this.pbBusyStatue.Visible = false;
            this.btCheck.Enabled = false;

            if (Global.ApacheConfig != null)
            {
                SetApacheConfig();
            }
            
        }
        private void btNext_Click(object sender, EventArgs e)
        {

            Parent.Controls.Add(new Page_3_2_ApacheChecking());
            Parent.Controls.Remove(this);
        }

        private void btStartChecn_Click(object sender, EventArgs e)
        {
           

            if (!String.IsNullOrEmpty(tbApacheConfig.Text))
            {
                Global.ApacheConfig = tbApacheConfig.Text;
                Global.ApacheConfigs[cbLinuxDistro.SelectedIndex] = tbApacheConfig.Text;
            }
            string cmd = String.Format(conf_find_sh, Global.ApacheConfig);
            string configTest = Global.sshHelper.runSudoCMD(cmd);
            if (configTest.TrimEnd('\n') == "Not found")
            {
                MessageBox.Show("The Apache configure file <"+Global.ApacheConfig+"> is not found!",
                        System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            this._worker = new BackgroundWorker();
            this.pbBusyStatue.Visible = true;
            bool isPassed = false;
            this.lbMessage.Text = "Checking and finding your Apache sites...";
            this.rtbContent.Text = "";

            _worker.DoWork += (object doWorkSender, DoWorkEventArgs doWorkEventArgs) =>
            {
                
                isPassed = CheckAndParseApacheSite();
            };

            _worker.RunWorkerCompleted += (object runWorkerCompletedSender, RunWorkerCompletedEventArgs runWorkerCompletedEventArgs) =>
            {
                if (runWorkerCompletedEventArgs.Error != null)
                {
                    string message = runWorkerCompletedEventArgs.Error != null ? runWorkerCompletedEventArgs.Error.Message : "Could not connect to the computer specified with the credentials supplied.";
                    MessageBox.Show(message,
                        System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);


                }
                else
                {

                    this.rtbContent.Text = _content;
                    this.rtbContent.SelectionStart = this.rtbContent.Text.Length;
                    this.rtbContent.ScrollToCaret();

                    this.pbBusyStatue.Visible = false;
                    if (isPassed) { this.btNext.Enabled = true; }
                    

                }
            };
            _worker.RunWorkerAsync();
        }

        private List<ApacheSite> GetApacheSitesInfo()
        {
            var siteList = new List<ApacheSite>();
            string folder = Global.homeFolder + "/" + Global.subfolder;
            string cmd = String.Format(listsites_sh, folder,Global.homeFolder,Global.ApacheConfig);
            string result = Global.sshHelper.runSudoCMD(cmd);
            var lines = result.TrimEnd('\n').Split('\n');
            if (lines.Length < 0)
            {
                MessageBox.Show("Sorry, I can't find any website here.");
            }
            else{

                for (int i = 0;i < lines.Length; i = i + 1)
                {
                var siteInfo = new ApacheSite();
                    //                siteInfo.SiteId = i + 1;
                    siteInfo.SiteId = i;
                    siteInfo.SiteName = lines[i];
                siteList.Add(siteInfo);
                }


            }
            return siteList;



        }

        private bool CheckAndParseApacheSite(){
            string message = "Perl Scripts will be uploaded to your Linux Host, do you agree?";
            string title = "Agree";
            _content = "";
            MessageBoxButtons buttons = MessageBoxButtons.YesNo;


            

            DialogResult result = MessageBox.Show(message, title, buttons, MessageBoxIcon.Question);
            if (result == DialogResult.Yes)
            {
                //                Global.sshHelper.UploadFile("aamt.tar.gz",Global.homeFolder);
                Global.sshHelper.UploadFile(Assembly.GetExecutingAssembly().GetManifestResourceStream(srcgzname), Global.homeFolder+dstgzname);
                string cmd = String.Format("tar -xvf {0}{1}",Global.homeFolder,dstgzname);
                _content += Global.sshHelper.runSudoCMD(cmd);
                if (String.IsNullOrEmpty(_content.TrimEnd('\n')))
                {
                    _content += "Error, please check the prerequisites.";
                    return false;
                }
                else
                {
                    _content += "Passed!";
                }

// in order to fix the scp permission error on some system when uploading the publis profile.
                cmd = String.Format("sudo chown {0} {1}/aamt", Global.userInfo.Username,Global.homeFolder);
                Global.sshHelper.runSudoCMD(cmd);
// in order to fix the scp permission error on some system when uploading the publis profile.

                Global.ApacheSiteList = GetApacheSitesInfo();
                return true;
                
            }
            else if (result == DialogResult.No)
            {
                MessageBox.Show("Thanks, Bye!");
                Application.Exit();
                return false;
            }
            else
            {
                // Do something
                return false;
            }
        }

        private void cbLinuxDistro_SelectedIndexChanged(object sender, EventArgs e)
        {
            this.btCheck.Enabled = true;
            tbApacheConfig.Text = Global.ApacheConfigs[cbLinuxDistro.SelectedIndex];
        }
        private void SetApacheConfig()
        {
            this.tbApacheConfig.Text = Global.ApacheConfig;
            int i = 0;
            foreach (String configfile in Global.ApacheConfigs)
                {
                if (Global.ApacheConfig == configfile)
                {
                    cbLinuxDistro.SelectedIndex = i;
                    break;
                }
                i++;
            }
        }

        private void btBack_Click(object sender, EventArgs e)
        {
            Parent.Controls.Add(new Page_2_ConnectToLinux());
            Parent.Controls.Remove(this);
        }

                
    }
}
