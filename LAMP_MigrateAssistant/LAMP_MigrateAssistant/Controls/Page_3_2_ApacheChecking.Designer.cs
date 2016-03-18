namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_3_2_ApacheChecking
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
            this.gbMigrationcandidates = new System.Windows.Forms.GroupBox();
            this.apacheSitesListBox = new System.Windows.Forms.CheckedListBox();
            this.label1 = new System.Windows.Forms.Label();
            this.btBack = new System.Windows.Forms.Button();
            this.btNext = new System.Windows.Forms.Button();
            this.gbMigrationcandidates.SuspendLayout();
            this.SuspendLayout();
            // 
            // gbMigrationcandidates
            // 
            this.gbMigrationcandidates.Controls.Add(this.apacheSitesListBox);
            this.gbMigrationcandidates.Controls.Add(this.label1);
            this.gbMigrationcandidates.Location = new System.Drawing.Point(22, 17);
            this.gbMigrationcandidates.Name = "gbMigrationcandidates";
            this.gbMigrationcandidates.Size = new System.Drawing.Size(537, 273);
            this.gbMigrationcandidates.TabIndex = 0;
            this.gbMigrationcandidates.TabStop = false;
            this.gbMigrationcandidates.Text = "Migration Candidates";
            // 
            // apacheSitesListBox
            // 
            this.apacheSitesListBox.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.apacheSitesListBox.CheckOnClick = true;
            this.apacheSitesListBox.FormattingEnabled = true;
            this.apacheSitesListBox.Location = new System.Drawing.Point(26, 69);
            this.apacheSitesListBox.Name = "apacheSitesListBox";
            this.apacheSitesListBox.Size = new System.Drawing.Size(479, 195);
            this.apacheSitesListBox.TabIndex = 1;
            this.apacheSitesListBox.ItemCheck += new System.Windows.Forms.ItemCheckEventHandler(this.apacheSitesListBox_SelectedIndexChanged);
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(6, 31);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(525, 53);
            this.label1.TabIndex = 0;
            this.label1.Text = "We detected the following websites as migration candidates. Select the one you wo" +
    "uld like to migrate to Azure Websites.";
            // 
            // btBack
            // 
            this.btBack.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btBack.Location = new System.Drawing.Point(401, 296);
            this.btBack.Name = "btBack";
            this.btBack.Size = new System.Drawing.Size(75, 23);
            this.btBack.TabIndex = 26;
            this.btBack.Text = "Back";
            this.btBack.UseVisualStyleBackColor = true;
            this.btBack.Click += new System.EventHandler(this.btBack_Click);
            // 
            // btNext
            // 
            this.btNext.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btNext.Location = new System.Drawing.Point(484, 296);
            this.btNext.Name = "btNext";
            this.btNext.Size = new System.Drawing.Size(75, 23);
            this.btNext.TabIndex = 25;
            this.btNext.Text = "Next";
            this.btNext.UseVisualStyleBackColor = true;
            this.btNext.Click += new System.EventHandler(this.btNext_Click);
            // 
            // Page_3_2_ApacheChecking
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.btBack);
            this.Controls.Add(this.gbMigrationcandidates);
            this.Controls.Add(this.btNext);
            this.Name = "Page_3_2_ApacheChecking";
            this.Size = new System.Drawing.Size(584, 378);
            this.gbMigrationcandidates.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox gbMigrationcandidates;
        private System.Windows.Forms.Button btBack;
        private System.Windows.Forms.Button btNext;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckedListBox apacheSitesListBox;
    }
}
