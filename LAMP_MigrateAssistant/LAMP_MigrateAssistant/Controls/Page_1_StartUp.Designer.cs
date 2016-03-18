namespace LAMP_MigrateAssistant.Controls
{
    partial class Page_1_StartUp
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
            this.pbStartUp = new System.Windows.Forms.PictureBox();
            ((System.ComponentModel.ISupportInitialize)(this.pbStartUp)).BeginInit();
            this.SuspendLayout();
            // 
            // btNext
            // 
            this.btNext.Location = new System.Drawing.Point(482, 296);
            this.btNext.Name = "btNext";
            this.btNext.Size = new System.Drawing.Size(75, 23);
            this.btNext.TabIndex = 3;
            this.btNext.Text = "Next";
            this.btNext.UseVisualStyleBackColor = true;
            this.btNext.Click += new System.EventHandler(this.btNext_Click);
            // 
            // pbStartUp
            // 
            this.pbStartUp.Image = global::LAMP_MigrateAssistant.Resource1.StartUp;
            this.pbStartUp.Location = new System.Drawing.Point(23, 3);
            this.pbStartUp.Name = "pbStartUp";
            this.pbStartUp.Size = new System.Drawing.Size(534, 262);
            this.pbStartUp.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pbStartUp.TabIndex = 4;
            this.pbStartUp.TabStop = false;
            // 
            // Page_1_StartUp
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.Controls.Add(this.pbStartUp);
            this.Controls.Add(this.btNext);
            this.Name = "Page_1_StartUp";
            this.Size = new System.Drawing.Size(584, 378);
            ((System.ComponentModel.ISupportInitialize)(this.pbStartUp)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btNext;
        private System.Windows.Forms.PictureBox pbStartUp;
    }
}
