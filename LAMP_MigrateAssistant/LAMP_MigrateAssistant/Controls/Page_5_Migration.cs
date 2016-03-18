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
using System.Diagnostics;
using LAMP_MigrateAssistant.Models;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_5_Migration : UserControl
    {
        private string deploysite_sh = "{0}/deploysite {1} {2} {3} {4}";

        public Page_5_Migration(string publishsettings)
        {
            InitializeComponent();
            _publishsettings = publishsettings;
            this.btStart.Enabled = true;
            this.btMigrateNewOne.Visible = false;

        }
        private string _publishsettings;
        private BackgroundWorker _worker;

        private void btExit_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void btStart_Click(object sender, EventArgs e)
        {
            _worker = new BackgroundWorker();
            this.btStart.Enabled = false;
            this.btBack.Enabled = false;
            this.btExit.Enabled = false;
            this.lbMessage.Text = "Migrating...";
            this.pbBusyStatue.Visible = true;
            string result = "";
            _worker.DoWork += (object doWorkSender, DoWorkEventArgs doWorkEventArgs) =>
            {
                result += RunMigrateScript();
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
                    this.rtbStatus.Text = result;
                    this.rtbStatus.SelectionStart = this.rtbStatus.Text.Length;
                    this.rtbStatus.ScrollToCaret();
                    this.lbMessage.Text = "Done!";
                    this.pbBusyStatue.Visible = false;

                    var linkString = _publishsettings.Substring(0, _publishsettings.LastIndexOf('.'));
                    this.linkLabel1.Visible = true;
                    this.linkLabel1.Text = linkString;
                    LinkLabel.Link link = new LinkLabel.Link();
                    link.LinkData = "Http://" + linkString;
                    linkLabel1.Links.Add(link);
                    this.btMigrateNewOne.Visible = true;
                    this.btBack.Enabled = true ;
                    this.btExit.Enabled = true ;
                }

            };
            _worker.RunWorkerAsync();

        }

        private string RunMigrateScript()
        {
            string result = "";
            string id = "";
            foreach (var item in Global.ApacheSiteList)
            {
                if (item.IsMigCandidate) { id = item.SiteId.ToString(); };
            }
            string folder = Global.homeFolder + "/" + Global.subfolder;
            string cmd = String.Format(deploysite_sh, folder, Global.homeFolder, Global.ApacheConfig, id, _publishsettings);
            result += Global.sshHelper.runSudoCMD(cmd);
            //CleanUp();

            return result;
        }

        private void CleanUp() {

            Global.sshHelper.runSudoCMD("rm -rf " + Global.homeFolder + "/aamt/test01");
            Global.sshHelper.runSudoCMD("rm aamt.tar.gz");
        }


  
        private void linkLabel1_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            ProcessStartInfo sInfo = new ProcessStartInfo(e.Link.LinkData.ToString());
            Process.Start(sInfo);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            Parent.Controls.Add(new Page_3_2_ApacheChecking());
            Parent.Controls.Remove(this);
        }

        private void btBack_Click(object sender, EventArgs e)
        {

            Parent.Controls.Add(new Page_4_2_ChoosePublishSettings());
            Parent.Controls.Remove(this);
        }
    }
}
