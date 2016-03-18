using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using LAMP_MigrateAssistant.Controls;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_1_Statement : UserControl
    {
        public Page_1_Statement()
        {
            InitializeComponent();
            //For debug;
            this.btNext.Enabled = true;
        }

        private void cbAgreement_CheckedChanged(object sender, EventArgs e)
        {

            if (this.cbAgreement.Checked)
            {
                this.btNext.Enabled = true;
            }
            else
            {
                this.btNext.Enabled = false;
            }
        }

        private void btNext_Click(object sender, EventArgs e)
        {
            
            Parent.Controls.Add(new Page_2_ConnectToLinux());
            Parent.Controls.Remove(this);
        }
    }
}
