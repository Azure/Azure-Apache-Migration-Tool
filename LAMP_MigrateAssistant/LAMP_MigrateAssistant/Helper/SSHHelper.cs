using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Renci.SshNet;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace LAMP_MigrateAssistant.Helper
{
    public class SSHHelper
    {
        public SSHHelper(string serverAddr, string port, string userName, string password)
        {
            _serverAddr = serverAddr;
            _password = password;
            _port = port;
            _username = userName;
            
            int portNum;
            bool success = int.TryParse(port, out portNum);

            if(success){
                _sshConnection = new SshClient(serverAddr, portNum, userName, password);
                _scpConnection = new ScpClient(serverAddr, portNum, userName, password);
            }
        }

        private string _serverAddr;
        public string _password;
        private string _port;
        public string _username;
        public bool _connected= false;
        private SshClient _sshConnection;
        private ScpClient _scpConnection;
        public ShellStream m_sshStream;

        public bool TryConnect()
        {
            try
            {
                _sshConnection.Connect();
                _connected = true;
                m_sshStream = _sshConnection.CreateShellStream("dumb", 80, 24, 800, 600, 1024);
            }
            catch (Exception e)
            {
                throw (e);
            }
            return true;
        }
        public void sshClienPreConnect()
        {
            //pre connect
            if (!_sshConnection.IsConnected)
            {
                try
                {
                    _sshConnection.Connect();
                }
                catch (Exception e)
                {
                    throw (e);
                }
            }
        }
        public void scpClienPreConnect()
        {
            if (!_scpConnection.IsConnected)
            {
                try
                {
                    _scpConnection.Connect();
                }
                catch (Exception e)
                {
                    throw (e);
                }
            }

        }
        public string runSudoCMD(string cmd)
        {
            sshClienPreConnect();
            string sudoCMD = "echo \"" + this._password + "\" | sudo -S " + cmd;
            var command = _sshConnection.RunCommand(sudoCMD);
            if (command.Error.Contains("tty"))
            {
                Exception ex=new Exception(command.Error);
                throw(ex);
            }
            return command.Result;
        }

        public bool UploadFile(string fileName,string desPath){
            scpClienPreConnect();
            //Ugly Design
            var filePath = new System.IO.FileInfo(fileName);
            if (!filePath.Exists)
            {
                filePath = new System.IO.FileInfo(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, fileName));
            }

            try
            {
                 _scpConnection.Upload(filePath, desPath);
            }
            catch (Exception e)
            {
                throw (e);
            }
            return true;

        }
        public bool UploadFile(Stream instream, string desPath)
        {
            scpClienPreConnect();
            //Ugly Design
            
            try
            {
                _scpConnection.Upload(instream, desPath);
            }
            catch (Exception e)
            {
                throw (e);
            }
            return true;

        }

        public bool DownloadFile(string sourceFilePath, string fileName)
        {
            scpClienPreConnect();
            var desFilePath = new System.IO.FileInfo(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, fileName));            //Clean destination folder
            if(desFilePath.Exists)
            {
                desFilePath.Delete();
            }
            try
            {
                _scpConnection.Download(sourceFilePath+fileName,desFilePath);
            }
            catch (Exception e)
            {
                Debug.WriteLine(e.Message);
                return false;
            }
            return true;

        }
    }
}
