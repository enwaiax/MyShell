import subprocess
import paramiko
import os
import logging
import sys
import argparse
import json


current_path = os.path.abspath(os.path.dirname(__file__))

# define a common logger class
class Logger(object):
    def __init__(self, name):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        log_format = logging.Formatter('[%(asctime)s][%(levelname)s][%(lineno)4d] <%(name)s> %(message)s',
                                       r'%Y-%m-%dT%H:%M:%S%z')
        console = logging.StreamHandler()
        console.setFormatter(log_format)
        self.logger.addHandler(console)
        console.close()

    def debug(self, message):
        self.logger.debug(message)

    def info(self, message):
        self.logger.info(message)

    def warning(self, message):
        self.logger.warning(message)

    def error(self, message):
        self.logger.error(message)

    def critical(self, message):
        self.logger.critical(message)


class controlHost:
    def __init__(self, host, username, password=None, port=22, private_key=None):
        self.logger = Logger(self.__class__.__name__)
        self.host = host
        self.password = password
        self.pkey = private_key
        if not password and not private_key:
            self.logger.error("password or private_key must be set")
            sys.exit(1)
        if private_key:
            self.pkey = paramiko.RSAKey.from_private_key_file(private_key)
        self.ssh = controlHost.__sshConn(
            self.host, username, self.password, self.pkey, int(port))
        self.sftp = self.__sftpConn()

    def close(self):
        if hasattr(self.ssh, "close"):
            self.ssh.close()

    @staticmethod
    def __sshConn(host, username, password, pkey, port):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            ssh.connect(hostname=host, port=int(port),
                        username=username, password=password, pkey=pkey)
        except:
            print(f'Fail to connect {host}')
        return ssh

    def __sftpConn(self):
        transport = self.ssh.get_transport()
        sftp = paramiko.SFTPClient.from_transport(transport)
        return sftp

    def exeCommand(self, cmd, timeout=300):
        _, stdout, stderr = self.ssh.exec_command(cmd, timeout=timeout)
        try:
            channel = stdout.channel
            exit_code = channel.recv_exit_status()
            stdout = stdout.read().strip().decode(encoding='utf-8')
            stderr = stderr.read().strip().decode(encoding='utf-8')
            result = {"stdout": stdout,
                      "stderr": stderr, "exit_code": exit_code}
            return result
        except Exception as e:
            self.logger.error(f'Fail to execute command {cmd} on {self.host}')
            self.logger.error(e)
            sys.exit(1)

    def sftpFile(self, localpath, remotepath, action):
        try:
            if action == 'put':
                dirname = os.path.dirname(remotepath)
                self.exeCommand("mkdir -p %s" % dirname)
                self.sftp.put(localpath, remotepath)
                return {"status": 1, "message": 'sftp %s %s success!' % (self.host, action)}
            elif action == "get":
                dirname = os.path.dirname(localpath)
                if not os.path.exists(dirname):
                    os.makedirs(dirname)
                self.sftp.get(remotepath, localpath)
                return {"status": 1, "stdout": 'sftp %s %s success!' % (self.host, action), "stderr": ""}
        except Exception as e:
            return {"status": 0, "stderr": 'sftp %s %s failed %s' % (self.host, action, str(e)), "stdout": ""}

    @staticmethod
    def iter_local_path(abs_path):
        result = set([])
        for j in os.walk(abs_path):
            print(j)
            base_path = j[0]
            file_list = j[2]
            for k in file_list:
                p = os.path.join(base_path, k)
                result.add(p)
        return result

    def iter_remote_path(self, abs_path):
        result = set([])
        try:
            stat = str(self.sftp.lstat(abs_path))
            print('stat', stat)
        except FileNotFoundError:
            return result
        else:
            if stat.startswith("d"):
                file_list = self.exeCommand("ls %s" % abs_path)["stdout"].decode(
                    encoding='utf-8').strip().splitlines()
                for j in file_list:
                    p = os.path.join(abs_path, j)
                    result.update(self.iter_remote_path(p))
            else:
                result.add(abs_path)
        return result


class runLocal:
    # run command on localhost
    def __init__(self):
        self.logger = Logger(self.__class__.__name__)

    def run(self, cmd):
        try:
            self.logger.info(f'run command: {cmd}')
            p = subprocess.Popen(
                cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = p.communicate()
            self.stdout = stdout.decode('utf-8')
            self.stderr = stderr.decode('utf-8')
            exit_code = p.returncode
            if exit_code != 0:
                self.logger.error(f'Fail to run command {cmd}')
                self.logger.error(f'exit code: {exit_code}')
                self.logger.error(f'stdout: {self.stdout}')
                self.logger.error(f'stderr: {self.stderr}')
                sys.exit(1)
            return self.stdout
        except Exception as e:
            self.logger.error(f'Fail to run command {cmd}')
            self.logger.error(e)
            sys.exit(1)
