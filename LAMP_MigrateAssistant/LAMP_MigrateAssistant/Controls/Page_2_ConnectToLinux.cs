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
using System.Diagnostics;
using LAMP_MigrateAssistant.Models;
using System.Text.RegularExpressions;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_2_ConnectToLinux : UserControl
    {
        private BackgroundWorker _worker;
        public Page_2_ConnectToLinux()
        {
            InitializeComponent();
            
            this.lbMessage.Text = "Connect to your Linux server!";

            if (Global.userInfo != null)
            {
                this.tbServerAddr.Text = Global.userInfo.Host;
                this.tbUserName.Text = Global.userInfo.Username;
                this.tbPassword.Text = Global.userInfo.Password;
                this.tbPort.Text = Global.userInfo.Port;
            }
       
        }

        private void btNext_Click(object sender, EventArgs e)
        {
            Global.userInfo = new UserProfile(tbServerAddr.Text, tbPort.Text, tbUserName.Text, tbPassword.Text);
            Parent.Controls.Add(new Page_3_ApacheChecking());
            Parent.Controls.Remove(this);
        }

        private void btConnect_Click(object sender, EventArgs e)
        {
            this.pbBusyStatue.Visible = true;
            _worker = new BackgroundWorker();
            Global.sshHelper = new SSHHelper(tbServerAddr.Text, tbPort.Text, tbUserName.Text, tbPassword.Text);
            this.lbMessage.Text = "Connecting...";
            _worker.DoWork += (object doWorkSender, DoWorkEventArgs doWorkEventArgs) =>
            {
                try
                {
                    Global.sshHelper.TryConnect();
                }
                catch (Exception ex)
                {
                    //MessageBox.Show(ex.Message, System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    throw ex;
                    //doWorkEventArgs.Result = ex.Message;
                }
            };

            _worker.RunWorkerCompleted += (object runWorkerCompletedSender, RunWorkerCompletedEventArgs runWorkerCompletedEventArgs) =>
            {
                if (runWorkerCompletedEventArgs.Error != null)
                {
                    string message = runWorkerCompletedEventArgs.Error != null ? runWorkerCompletedEventArgs.Error.Message : "Could not connect to the computer specified with the credentials supplied.";
                    MessageBox.Show(message,
                        System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                    this.lbMessage.Text = "Connected failed!";
                    this.pbBusyStatue.Visible = false;
                    return;
                }
                else
                {

                    try
                    {
                        string result = Global.sshHelper.runSudoCMD("echo $HOME");
                        Global.homeFolder = Regex.Replace(result, @"\t|\n|\r", ""); 
                    }
                    catch (Exception ex)
                    {
                        this.lbMessage.Text = "Connected! But got error to run command.";
                        this.pbBusyStatue.Visible = false;
                        MessageBox.Show(ex.Message,
                                System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return;
                    }

                    this.lbMessage.Text = "Connected!";
                }

                this.btNext.Enabled = true;
                this.pbBusyStatue.Visible = false;
            };
            _worker.RunWorkerAsync();
        }
    }
}
