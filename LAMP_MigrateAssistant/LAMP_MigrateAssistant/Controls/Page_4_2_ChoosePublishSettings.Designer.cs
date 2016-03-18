namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_4_2_ChoosePublishSettings
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
            this.btNext = new System.Windows.Forms.Button();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.btChoose = new System.Windows.Forms.Button();
            this.tbPSLocation = new System.Windows.Forms.TextBox();
            this.btBack = new System.Windows.Forms.Button();
            this.groupBox1.SuspendLayout();
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
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.btChoose);
            this.groupBox1.Controls.Add(this.tbPSLocation);
            this.groupBox1.Location = new System.Drawing.Point(25, 112);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(532, 74);
            this.groupBox1.TabIndex = 23;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Upload .PublishSettings";
            // 
            // btChoose
            // 
            this.btChoose.Location = new System.Drawing.Point(438, 45);
            this.btChoose.Name = "btChoose";
            this.btChoose.Size = new System.Drawing.Size(88, 23);
            this.btChoose.TabIndex = 23;
            this.btChoose.Text = "Choose..";
            this.btChoose.UseVisualStyleBackColor = true;
            this.btChoose.Click += new System.EventHandler(this.btChoose_Click);
            // 
            // tbPSLocation
            // 
            this.tbPSLocation.Location = new System.Drawing.Point(6, 21);
            this.tbPSLocation.Name = "tbPSLocation";
            this.tbPSLocation.Size = new System.Drawing.Size(520, 20);
            this.tbPSLocation.TabIndex = 22;
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
            // Page_4_2_ChoosePublishSettings
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.btBack);
            this.Controls.Add(this.groupBox1);
            this.Controls.Add(this.btNext);
            this.Name = "Page_4_2_ChoosePublishSettings";
            this.Size = new System.Drawing.Size(584, 378);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btNext;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button btChoose;
        private System.Windows.Forms.TextBox tbPSLocation;
        private System.Windows.Forms.Button btBack;
    }
}
