namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_1_Statement
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
            this.rtbStatement = new System.Windows.Forms.RichTextBox();
            this.cbAgreement = new System.Windows.Forms.CheckBox();
            this.btNext = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // rtbStatement
            // 
            this.rtbStatement.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.rtbStatement.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.rtbStatement.Location = new System.Drawing.Point(23, 12);
            this.rtbStatement.Name = "rtbStatement";
            this.rtbStatement.Size = new System.Drawing.Size(534, 262);
            this.rtbStatement.TabIndex = 0;
            this.rtbStatement.Text = "";
            // 
            // cbAgreement
            // 
            this.cbAgreement.AutoSize = true;
            this.cbAgreement.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cbAgreement.Location = new System.Drawing.Point(23, 300);
            this.cbAgreement.Name = "cbAgreement";
            this.cbAgreement.Size = new System.Drawing.Size(61, 17);
            this.cbAgreement.TabIndex = 1;
            this.cbAgreement.Text = "I agree";
            this.cbAgreement.UseVisualStyleBackColor = true;
            this.cbAgreement.CheckedChanged += new System.EventHandler(this.cbAgreement_CheckedChanged);
            // 
            // btNext
            // 
            this.btNext.Location = new System.Drawing.Point(482, 296);
            this.btNext.Name = "btNext";
            this.btNext.Size = new System.Drawing.Size(75, 23);
            this.btNext.TabIndex = 2;
            this.btNext.Text = "Next";
            this.btNext.UseVisualStyleBackColor = true;
            this.btNext.Click += new System.EventHandler(this.btNext_Click);
            // 
            // Page_1_Statement
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.btNext);
            this.Controls.Add(this.cbAgreement);
            this.Controls.Add(this.rtbStatement);
            this.Font = new System.Drawing.Font("Segoe UI", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Name = "Page_1_Statement";
            this.Size = new System.Drawing.Size(584, 378);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.RichTextBox rtbStatement;
        private System.Windows.Forms.CheckBox cbAgreement;
        private System.Windows.Forms.Button btNext;
    }
}
