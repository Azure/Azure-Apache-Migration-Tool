namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_5_Migration
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
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Page_5_Migration));
            this.btExit = new System.Windows.Forms.Button();
            this.lbMessage = new System.Windows.Forms.Label();
            this.btStart = new System.Windows.Forms.Button();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.rtbStatus = new System.Windows.Forms.RichTextBox();
            this.linkLabel1 = new System.Windows.Forms.LinkLabel();
            this.btMigrateNewOne = new System.Windows.Forms.Button();
            this.pbBusyStatue = new System.Windows.Forms.PictureBox();
            this.btBack = new System.Windows.Forms.Button();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).BeginInit();
            this.SuspendLayout();
            // 
            // btExit
            // 
            this.btExit.Location = new System.Drawing.Point(482, 296);
            this.btExit.Name = "btExit";
            this.btExit.Size = new System.Drawing.Size(75, 23);
            this.btExit.TabIndex = 0;
            this.btExit.Text = "Exit";
            this.btExit.UseVisualStyleBackColor = true;
            this.btExit.Click += new System.EventHandler(this.btExit_Click);
            // 
            // lbMessage
            // 
            this.lbMessage.AutoSize = true;
            this.lbMessage.Location = new System.Drawing.Point(20, 356);
            this.lbMessage.Name = "lbMessage";
            this.lbMessage.Size = new System.Drawing.Size(50, 13);
            this.lbMessage.TabIndex = 4;
            this.lbMessage.Text = "Message";
            // 
            // btStart
            // 
            this.btStart.Location = new System.Drawing.Point(9, 19);
            this.btStart.Name = "btStart";
            this.btStart.Size = new System.Drawing.Size(75, 23);
            this.btStart.TabIndex = 6;
            this.btStart.Text = "Start";
            this.btStart.UseVisualStyleBackColor = true;
            this.btStart.Click += new System.EventHandler(this.btStart_Click);
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.pbBusyStatue);
            this.groupBox1.Controls.Add(this.rtbStatus);
            this.groupBox1.Controls.Add(this.btStart);
            this.groupBox1.Location = new System.Drawing.Point(14, 29);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(553, 261);
            this.groupBox1.TabIndex = 7;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Migrate Your Site";
            // 
            // rtbStatus
            // 
            this.rtbStatus.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.rtbStatus.Location = new System.Drawing.Point(9, 48);
            this.rtbStatus.Name = "rtbStatus";
            this.rtbStatus.Size = new System.Drawing.Size(534, 207);
            this.rtbStatus.TabIndex = 7;
            this.rtbStatus.Text = "";
            // 
            // linkLabel1
            // 
            this.linkLabel1.AutoSize = true;
            this.linkLabel1.Location = new System.Drawing.Point(20, 301);
            this.linkLabel1.Name = "linkLabel1";
            this.linkLabel1.Size = new System.Drawing.Size(55, 13);
            this.linkLabel1.TabIndex = 22;
            this.linkLabel1.TabStop = true;
            this.linkLabel1.Text = "linkLabel1";
            this.linkLabel1.Visible = false;
            this.linkLabel1.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkLabel1_LinkClicked);
            // 
            // btMigrateNewOne
            // 
            this.btMigrateNewOne.Location = new System.Drawing.Point(211, 296);
            this.btMigrateNewOne.Name = "btMigrateNewOne";
            this.btMigrateNewOne.Size = new System.Drawing.Size(139, 23);
            this.btMigrateNewOne.TabIndex = 23;
            this.btMigrateNewOne.Text = "Migrate Another One";
            this.btMigrateNewOne.UseVisualStyleBackColor = true;
            this.btMigrateNewOne.Click += new System.EventHandler(this.button1_Click);
            // 
            // pbBusyStatue
            // 
            this.pbBusyStatue.Image = ((System.Drawing.Image)(resources.GetObject("pbBusyStatue.Image")));
            this.pbBusyStatue.Location = new System.Drawing.Point(106, 22);
            this.pbBusyStatue.Name = "pbBusyStatue";
            this.pbBusyStatue.Size = new System.Drawing.Size(20, 20);
            this.pbBusyStatue.SizeMode = System.Windows.Forms.PictureBoxSizeMode.AutoSize;
            this.pbBusyStatue.TabIndex = 21;
            this.pbBusyStatue.TabStop = false;
            this.pbBusyStatue.Visible = false;
            // 
            // btBack
            // 
            this.btBack.Location = new System.Drawing.Point(401, 296);
            this.btBack.Name = "btBack";
            this.btBack.Size = new System.Drawing.Size(75, 23);
            this.btBack.TabIndex = 24;
            this.btBack.Text = "Back";
            this.btBack.UseVisualStyleBackColor = true;
            this.btBack.Click += new System.EventHandler(this.btBack_Click);
            // 
            // Page_5_Migration
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.btBack);
            this.Controls.Add(this.btMigrateNewOne);
            this.Controls.Add(this.linkLabel1);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.lbMessage);
            this.Controls.Add(this.btExit);
            this.Name = "Page_5_Migration";
            this.Size = new System.Drawing.Size(584, 378);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbBusyStatue)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btExit;
        private System.Windows.Forms.Label lbMessage;
        private System.Windows.Forms.Button btStart;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.RichTextBox rtbStatus;
        private System.Windows.Forms.PictureBox pbBusyStatue;
        private System.Windows.Forms.LinkLabel linkLabel1;
        private System.Windows.Forms.Button btMigrateNewOne;
        private System.Windows.Forms.Button btBack;
    }
}
