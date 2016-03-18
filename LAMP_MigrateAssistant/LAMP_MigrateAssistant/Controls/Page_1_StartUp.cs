using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace LAMP_MigrateAssistant.Controls
{
    public partial class Page_1_StartUp : UserControl
    {
        public Page_1_StartUp()
        {
            InitializeComponent();
        }

        private void btNext_Click(object sender, EventArgs e)
        {
            Parent.Controls.Add(new Page_2_ConnectToLinux());
            Parent.Controls.Remove(this);
        }
    }
}
