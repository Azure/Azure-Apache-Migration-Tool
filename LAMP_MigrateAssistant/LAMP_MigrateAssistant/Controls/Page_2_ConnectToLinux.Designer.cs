namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_2_ConnectToLinux
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Page_2_ConnectToLinux));
            this.lbServerAddr = new System.Windows.Forms.Label();
            this.lbPort = new System.Windows.Forms.Label();
            this.lbUserName = new System.Windows.Forms.Label();
            this.lbPassword = new System.Windows.Forms.Label();
            this.tbServerAddr = new System.Windows.Forms.TextBox();
            this.tbPort = new System.Windows.Forms.TextBox();
            this.tbUserName = new System.Windows.Forms.TextBox();
            this.tbPassword = new System.Windows.Forms.TextBox();
            this.btConnect = new System.Windows.Forms.Button();
            this.btNext = new System.Windows.Forms.Button();
            this.lbMessage = new System.Windows.Forms.Label();
            this.pictureBox1 = new System.Windows.Forms.PictureBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.pbBusyStatue = new System.Windows.Forms.PictureBox();
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).BeginInit();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).BeginInit();
            this.SuspendLayout();
            // 
            // lbServerAddr
            // 
            this.lbServerAddr.AutoSize = true;
            this.lbServerAddr.Location = new System.Drawing.Point(17, 22);
            this.lbServerAddr.Name = "lbServerAddr";
            this.lbServerAddr.Size = new System.Drawing.Size(82, 13);
            this.lbServerAddr.TabIndex = 0;
            this.lbServerAddr.Text = "Server Address";
            // 
            // lbPort
            // 
            this.lbPort.AutoSize = true;
            this.lbPort.Location = new System.Drawing.Point(17, 46);
            this.lbPort.Name = "lbPort";
            this.lbPort.Size = new System.Drawing.Size(28, 13);
            this.lbPort.TabIndex = 1;
            this.lbPort.Text = "Port";
            // 
            // lbUserName
            // 
            this.lbUserName.AutoSize = true;
            this.lbUserName.Location = new System.Drawing.Point(17, 70);
            this.lbUserName.Name = "lbUserName";
            this.lbUserName.Size = new System.Drawing.Size(62, 13);
            this.lbUserName.TabIndex = 2;
            this.lbUserName.Text = "User Name";
            // 
            // lbPassword
            // 
            this.lbPassword.AutoSize = true;
            this.lbPassword.Location = new System.Drawing.Point(17, 94);
            this.lbPassword.Name = "lbPassword";
            this.lbPassword.Size = new System.Drawing.Size(56, 13);
            this.lbPassword.TabIndex = 3;
            this.lbPassword.Text = "Password";
            // 
            // tbServerAddr
            // 
            this.tbServerAddr.Location = new System.Drawing.Point(114, 19);
            this.tbServerAddr.Name = "tbServerAddr";
            this.tbServerAddr.Size = new System.Drawing.Size(180, 22);
            this.tbServerAddr.TabIndex = 4;
            // 
            // tbPort
            // 
            this.tbPort.Location = new System.Drawing.Point(114, 43);
            this.tbPort.Name = "tbPort";
            this.tbPort.Size = new System.Drawing.Size(180, 22);
            this.tbPort.TabIndex = 5;
            this.tbPort.Text = "22";
            // 
            // tbUserName
            // 
            this.tbUserName.Location = new System.Drawing.Point(114, 67);
            this.tbUserName.Name = "tbUserName";
            this.tbUserName.Size = new System.Drawing.Size(180, 22);
            this.tbUserName.TabIndex = 6;
            // 
            // tbPassword
            // 
            this.tbPassword.Location = new System.Drawing.Point(114, 91);
            this.tbPassword.Name = "tbPassword";
            this.tbPassword.PasswordChar = '●';
            this.tbPassword.Size = new System.Drawing.Size(180, 22);
            this.tbPassword.TabIndex = 7;
            // 
            // btConnect
            // 
            this.btConnect.Location = new System.Drawing.Point(219, 117);
            this.btConnect.Name = "btConnect";
            this.btConnect.Size = new System.Drawing.Size(75, 23);
            this.btConnect.TabIndex = 8;
            this.btConnect.Text = "Connect";
            this.btConnect.UseVisualStyleBackColor = true;
            this.btConnect.Click += new System.EventHandler(this.btConnect_Click);
            // 
            // btNext
            // 
            this.btNext.Enabled = false;
            this.btNext.Location = new System.Drawing.Point(482, 296);
            this.btNext.Name = "btNext";
            this.btNext.Size = new System.Drawing.Size(75, 23);
            this.btNext.TabIndex = 9;
            this.btNext.Text = "Next";
            this.btNext.UseVisualStyleBackColor = true;
            this.btNext.Click += new System.EventHandler(this.btNext_Click);
            // 
            // lbMessage
            // 
            this.lbMessage.AutoSize = true;
            this.lbMessage.Location = new System.Drawing.Point(20, 356);
            this.lbMessage.Name = "lbMessage";
            this.lbMessage.Size = new System.Drawing.Size(50, 13);
            this.lbMessage.TabIndex = 10;
            this.lbMessage.Text = "Message";
            // 
            // pictureBox1
            // 
            this.pictureBox1.Image = ((System.Drawing.Image)(resources.GetObject("pictureBox1.Image")));
            this.pictureBox1.InitialImage = null;
            this.pictureBox1.Location = new System.Drawing.Point(424, 87);
            this.pictureBox1.Name = "pictureBox1";
            this.pictureBox1.Size = new System.Drawing.Size(80, 80);
            this.pictureBox1.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pictureBox1.TabIndex = 11;
            this.pictureBox1.TabStop = false;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.tbPort);
            this.groupBox1.Controls.Add(this.lbServerAddr);
            this.groupBox1.Controls.Add(this.lbPort);
            this.groupBox1.Controls.Add(this.lbUserName);
            this.groupBox1.Controls.Add(this.btConnect);
            this.groupBox1.Controls.Add(this.lbPassword);
            this.groupBox1.Controls.Add(this.tbPassword);
            this.groupBox1.Controls.Add(this.tbServerAddr);
            this.groupBox1.Controls.Add(this.tbUserName);
            this.groupBox1.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.groupBox1.Location = new System.Drawing.Point(64, 60);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(300, 146);
            this.groupBox1.TabIndex = 12;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Linux Host";
            // 
            // pbBusyStatue
            // 
            this.pbBusyStatue.Image = ((System.Drawing.Image)(resources.GetObject("pbBusyStatue.Image")));
            this.pbBusyStatue.Location = new System.Drawing.Point(23, 296);
            this.pbBusyStatue.Name = "pbBusyStatue";
            this.pbBusyStatue.Size = new System.Drawing.Size(35, 35);
            this.pbBusyStatue.SizeMode = System.Windows.Forms.PictureBoxSizeMode.CenterImage;
            this.pbBusyStatue.TabIndex = 21;
            this.pbBusyStatue.TabStop = false;
            this.pbBusyStatue.Visible = false;
            // 
            // Page_2_ConnectToLinux
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.pbBusyStatue);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.pictureBox1);
            this.Controls.Add(this.lbMessage);
            this.Controls.Add(this.btNext);
            this.Name = "Page_2_ConnectToLinux";
            this.Size = new System.Drawing.Size(584, 378);
            ((System.ComponentModel.ISupportInitialize)(this.pictureBox1)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Label lbServerAddr;
        private System.Windows.Forms.Label lbPort;
        private System.Windows.Forms.Label lbUserName;
        private System.Windows.Forms.Label lbPassword;
        private System.Windows.Forms.TextBox tbServerAddr;
        private System.Windows.Forms.TextBox tbPort;
        private System.Windows.Forms.TextBox tbUserName;
        private System.Windows.Forms.TextBox tbPassword;
        private System.Windows.Forms.Button btConnect;
        private System.Windows.Forms.Button btNext;
        private System.Windows.Forms.Label lbMessage;
        private System.Windows.Forms.PictureBox pictureBox1;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.PictureBox pbBusyStatue;
    }
}
