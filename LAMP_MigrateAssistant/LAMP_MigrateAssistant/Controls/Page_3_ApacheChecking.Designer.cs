namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_3_ApacheChecking
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Page_3_ApacheChecking));
            this.btNext = new System.Windows.Forms.Button();
            this.btCheck = new System.Windows.Forms.Button();
            this.lbMessage = new System.Windows.Forms.Label();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.cbLinuxDistro = new System.Windows.Forms.ComboBox();
            this.tbApacheConfig = new System.Windows.Forms.TextBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.rtbContent = new System.Windows.Forms.RichTextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.pbBusyStatue = new System.Windows.Forms.PictureBox();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.btBack = new System.Windows.Forms.Button();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).BeginInit();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // btNext
            // 
            this.btNext.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btNext.Location = new System.Drawing.Point(482, 296);
            this.btNext.Name = "btNext";
            this.btNext.Size = new System.Drawing.Size(75, 23);
            this.btNext.TabIndex = 1;
            this.btNext.Text = "Next";
            this.btNext.UseVisualStyleBackColor = true;
            this.btNext.Click += new System.EventHandler(this.btNext_Click);
            // 
            // btCheck
            // 
            this.btCheck.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btCheck.Location = new System.Drawing.Point(440, 44);
            this.btCheck.Name = "btCheck";
            this.btCheck.Size = new System.Drawing.Size(88, 23);
            this.btCheck.TabIndex = 2;
            this.btCheck.Text = "Strat Check";
            this.btCheck.UseVisualStyleBackColor = true;
            this.btCheck.Click += new System.EventHandler(this.btStartChecn_Click);
            // 
            // lbMessage
            // 
            this.lbMessage.AutoSize = true;
            this.lbMessage.Location = new System.Drawing.Point(20, 356);
            this.lbMessage.Name = "lbMessage";
            this.lbMessage.Size = new System.Drawing.Size(0, 13);
            this.lbMessage.TabIndex = 5;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(10, 22);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(129, 13);
            this.label1.TabIndex = 6;
            this.label1.Text = "Please select Linux distro:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(10, 49);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(190, 13);
            this.label2.TabIndex = 7;
            this.label2.Text = "Please enter the Apache configure file:";
            // 
            // cbLinuxDistro
            // 
            this.cbLinuxDistro.FormattingEnabled = true;
            this.cbLinuxDistro.Items.AddRange(new object[] {
            "Debian/Ubuntu",
            "RedHat/CentOS",
            "OpenSUSE",
            "Other"});
            this.cbLinuxDistro.Location = new System.Drawing.Point(206, 19);
            this.cbLinuxDistro.Name = "cbLinuxDistro";
            this.cbLinuxDistro.Size = new System.Drawing.Size(228, 21);
            this.cbLinuxDistro.TabIndex = 8;
            this.cbLinuxDistro.SelectedIndexChanged += new System.EventHandler(this.cbLinuxDistro_SelectedIndexChanged);
            // 
            // tbApacheConfig
            // 
            this.tbApacheConfig.Location = new System.Drawing.Point(206, 46);
            this.tbApacheConfig.Name = "tbApacheConfig";
            this.tbApacheConfig.Size = new System.Drawing.Size(228, 20);
            this.tbApacheConfig.TabIndex = 9;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.label2);
            this.groupBox1.Controls.Add(this.tbApacheConfig);
            this.groupBox1.Controls.Add(this.btCheck);
            this.groupBox1.Controls.Add(this.cbLinuxDistro);
            this.groupBox1.Controls.Add(this.label1);
            this.groupBox1.Location = new System.Drawing.Point(23, 17);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(534, 82);
            this.groupBox1.TabIndex = 10;
            this.groupBox1.TabStop = false;
            // 
            // rtbContent
            // 
            this.rtbContent.AcceptsTab = true;
            this.rtbContent.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.rtbContent.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.rtbContent.Location = new System.Drawing.Point(6, 19);
            this.rtbContent.Name = "rtbContent";
            this.rtbContent.Size = new System.Drawing.Size(522, 150);
            this.rtbContent.TabIndex = 0;
            this.rtbContent.Text = "";
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(275, 105);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(0, 13);
            this.label3.TabIndex = 10;
            // 
            // pbBusyStatue
            // 
            this.pbBusyStatue.Image = ((System.Drawing.Image)(resources.GetObject("pbBusyStatue.Image")));
            this.pbBusyStatue.Location = new System.Drawing.Point(23, 296);
            this.pbBusyStatue.Name = "pbBusyStatue";
            this.pbBusyStatue.Size = new System.Drawing.Size(35, 35);
            this.pbBusyStatue.SizeMode = System.Windows.Forms.PictureBoxSizeMode.CenterImage;
            this.pbBusyStatue.TabIndex = 22;
            this.pbBusyStatue.TabStop = false;
            this.pbBusyStatue.Visible = false;
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.rtbContent);
            this.groupBox3.Location = new System.Drawing.Point(23, 105);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(534, 180);
            this.groupBox3.TabIndex = 23;
            this.groupBox3.TabStop = false;
            // 
            // btBack
            // 
            this.btBack.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btBack.Location = new System.Drawing.Point(401, 296);
            this.btBack.Name = "btBack";
            this.btBack.Size = new System.Drawing.Size(75, 23);
            this.btBack.TabIndex = 24;
            this.btBack.Text = "Back";
            this.btBack.UseVisualStyleBackColor = true;
            this.btBack.Click += new System.EventHandler(this.btBack_Click);
            // 
            // Page_3_ApacheChecking
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.btBack);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.pbBusyStatue);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.lbMessage);
            this.Controls.Add(this.btNext);
            this.Name = "Page_3_ApacheChecking";
            this.Size = new System.Drawing.Size(584, 378);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).EndInit();
            this.groupBox3.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btNext;
        private System.Windows.Forms.Button btCheck;
        private System.Windows.Forms.Label lbMessage;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.ComboBox cbLinuxDistro;
        private System.Windows.Forms.TextBox tbApacheConfig;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.RichTextBox rtbContent;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.PictureBox pbBusyStatue;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.Button btBack;
    }
}
