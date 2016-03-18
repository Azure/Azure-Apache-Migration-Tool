using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using LAMP_MigrateAssistant.Controls;
using LAMP_MigrateAssistant.Helper;
using LAMP_MigrateAssistant.Models;

namespace LAMP_MigrateAssistant
{
    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
             
            this.panelContent.Controls.Add(new Page_1_StartUp());
            this.panelHead.BackColor = Color.FromArgb(1, 164, 239);
            this.panelBottom.BackColor = Color.FromArgb(1, 164, 239);
        }

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (Global.sshHelper != null)
            {
                if (Global.sshHelper._connected != false)
                {
                    try
                    {
                        Global.sshHelper.runSudoCMD("rm -rf " + Global.homeFolder + "/aamt");
                        Global.sshHelper.runSudoCMD("rm " + Global.homeFolder + "/aamt.tar.gz");
                    }
                    catch (Exception ex)
                    {
                        //Do nothing
                        return;
                    }
                    
                }

            }

        }
    }
}
