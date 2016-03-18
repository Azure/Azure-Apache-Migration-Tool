using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using Renci.SshNet;
using System.Threading;
using LAMP_MigrateAssistant.Models;
using System.Text.RegularExpressions;
using LAMP_MigrateAssistant.Helper;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_3_2_ApacheChecking : UserControl
    {
        public Page_3_2_ApacheChecking()
        {
            InitializeComponent();
            this.apacheSitesListBox.Items.Clear();
            foreach (var item in Global.ApacheSiteList)
            {
                this.apacheSitesListBox.Items.Add(item.ToString());
            }
            this.btNext.Enabled = false;
        }

        private void btNext_Click(object sender, EventArgs e)
        {
            bool isSelected = false;
            foreach(var item in Global.ApacheSiteList)
            {
                item.IsMigCandidate = false;
            }

            foreach (int item in apacheSitesListBox.CheckedIndices)
            {
                Global.ApacheSiteList[item].IsMigCandidate = true;
                isSelected = true;
            }

            if (isSelected)
            {
                Parent.Controls.Add(new Page_4_2_ChoosePublishSettings());
                Parent.Controls.Remove(this);
            }
            else
            {
                MessageBox.Show("Please select one website you want to migrate!",
                        System.Windows.Forms.Application.ProductName, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }

        }

        private void btBack_Click(object sender, EventArgs e)
        {
            Parent.Controls.Add(new Page_3_ApacheChecking());
            Parent.Controls.Remove(this);
        }

        private void apacheSitesListBox_SelectedIndexChanged(object sender, ItemCheckEventArgs e)
        {

            this.btNext.Enabled = true;
            if (e.NewValue == CheckState.Checked)
            {
                foreach (int i in apacheSitesListBox.CheckedIndices)
                    apacheSitesListBox.SetItemCheckState(i, CheckState.Unchecked);
            }

        }
    }
}
