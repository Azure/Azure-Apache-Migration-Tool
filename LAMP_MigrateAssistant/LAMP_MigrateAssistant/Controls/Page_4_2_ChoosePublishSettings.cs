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
using LAMP_MigrateAssistant.Models;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_4_2_ChoosePublishSettings : UserControl
    {
        public Page_4_2_ChoosePublishSettings()
        {
            InitializeComponent();
            this.btNext.Enabled = false;
        }

        private BackgroundWorker _worker;
        private string _publishSettingsFileName;

        private void btNext_Click(object sender, EventArgs e)
        {
            //ugly
            if (Global.sshHelper.UploadFile(this.tbPSLocation.Text, Global.homeFolder+"/aamt/"))
            {
                this.btNext.Enabled = true;
            }
            else
            {
                MessageBox.Show("Upload failed! Please check SSH connectino!");
                return;
            }

            Parent.Controls.Add(new Page_5_Migration(_publishSettingsFileName));
            Parent.Controls.Remove(this);
        }

        private void btChoose_Click(object sender, EventArgs e)
        {
            OpenFileDialog choofdlog = new OpenFileDialog();
            choofdlog.Filter = "PublishSetting File (*.PublishSettings)| *.PublishSettings";
            choofdlog.FilterIndex = 1;
            choofdlog.Multiselect = false;

            if (choofdlog.ShowDialog() == DialogResult.OK)
            {
                this.tbPSLocation.Text = choofdlog.FileName;
                _publishSettingsFileName = choofdlog.SafeFileName;
                this.btNext.Enabled = true;

            }
        }


        private void btBack_Click(object sender, EventArgs e)
        {
            Parent.Controls.Add(new Page_3_2_ApacheChecking());
            Parent.Controls.Remove(this);
        }
    }
}
