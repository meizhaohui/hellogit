.. _install_python:

Git的安装
======================

.. contents:: 目录

本文讲解在CentOS7中安装较高版本的git分布式版本控制系统。

实验环境：

- server服务端: 操作系统为CentOS 7.6，IP:192.168.56.14。
- client客户端: 操作系统为CentOS 7.6，IP:192.168.56.15。

查看server服务端信息::

    [root@server ~]# cat /etc/centos-release
    CentOS Linux release 7.6.1810 (Core) 
    [root@server ~]# ip a show|grep 192
    inet 192.168.56.14/24 brd 192.168.56.255 scope global noprefixroute enp0s3

查看client客户端信息::

    [root@client ~]# cat /etc/centos-release
    CentOS Linux release 7.6.1810 (Core) 
    [root@client ~]# ip a show |grep 192
        inet 192.168.56.15/24 brd 192.168.56.255 scope global noprefixroute enp0s3
    
不使用第三方源安装git
----------------------------------------

使用yum安装git，不使用第三方源安装git，是较低版本的git::

    [root@server ~]# yum install git -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.huaweicloud.com
     * centos-sclo-rh: mirrors.huaweicloud.com
     * extras: mirrors.tuna.tsinghua.edu.cn
     * updates: mirrors.huaweicloud.com
    updates/7/x86_64/primary_db                                                                                  | 5.0 MB  00:00:04     
    Resolving Dependencies
    --> Running transaction check
    ---> Package git.x86_64 0:1.8.3.1-20.el7 will be installed
    --> Processing Dependency: perl-Git = 1.8.3.1-20.el7 for package: git-1.8.3.1-20.el7.x86_64
    --> Processing Dependency: perl(Git) for package: git-1.8.3.1-20.el7.x86_64
    --> Running transaction check
    ---> Package perl-Git.noarch 0:1.8.3.1-20.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                       Arch                        Version                               Repository                    Size
    ====================================================================================================================================
    Installing:
     git                           x86_64                      1.8.3.1-20.el7                        updates                      4.4 M
    Installing for dependencies:
     perl-Git                      noarch                      1.8.3.1-20.el7                        updates                       55 k

    Transaction Summary
    ====================================================================================================================================
    Install  1 Package (+1 Dependent package)

    Total download size: 4.4 M
    Installed size: 22 M
    Downloading packages:
    (1/2): perl-Git-1.8.3.1-20.el7.noarch.rpm                                                                    |  55 kB  00:00:01     
    (2/2): git-1.8.3.1-20.el7.x86_64.rpm                                                                         | 4.4 MB  00:00:04     
    ------------------------------------------------------------------------------------------------------------------------------------
    Total                                                                                               1.1 MB/s | 4.4 MB  00:00:04     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : git-1.8.3.1-20.el7.x86_64                                                                                        1/2 
      Installing : perl-Git-1.8.3.1-20.el7.noarch                                                                                   2/2 
      Verifying  : perl-Git-1.8.3.1-20.el7.noarch                                                                                   1/2 
      Verifying  : git-1.8.3.1-20.el7.x86_64                                                                                        2/2 

    Installed:
      git.x86_64 0:1.8.3.1-20.el7                                                                                                       

    Dependency Installed:
      perl-Git.noarch 0:1.8.3.1-20.el7                                                                                                  

    Complete!
    [root@server ~]# 
    
查看git版本::

    [root@server ~]# git --version
    git version 1.8.3.1

可以发现git版本是1.8.3.1，而当前(2019年6月4日)官方上面最新版本的git是2.21版本，因此我们通过第三方源将git升级到高版本。

安装依赖包
------------------------------------------------

安装依赖包::

    [root@server ~]# yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel autoconf gcc -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.huaweicloud.com
     * centos-sclo-rh: mirrors.huaweicloud.com
     * extras: mirrors.tuna.tsinghua.edu.cn
     * updates: mirrors.huaweicloud.com
    Package libcurl-devel-7.29.0-51.el7.x86_64 already installed and latest version
    Package expat-devel-2.1.0-10.el7_3.x86_64 already installed and latest version
    Package gettext-devel-0.19.8.1-2.el7.x86_64 already installed and latest version
    Package 1:openssl-devel-1.0.2k-16.el7_6.1.x86_64 already installed and latest version
    Package zlib-devel-1.2.7-18.el7.x86_64 already installed and latest version
    Package autoconf-2.69-11.el7.noarch already installed and latest version
    Package gcc-4.8.5-36.el7_6.2.x86_64 already installed and latest version
    Nothing to do

- 安装第三方源

参考:https://git-scm.com/download/linux
    
安装epel-release源::

    [root@server ~]# rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    Retrieving https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    Preparing...                          ################################# [100%]
            package epel-release-7-11.noarch is already installed
        
安装ius-release源::

    [root@server ~]# rpm -ivh https://centos7.iuscommunity.org/ius-release.rpm --force
    Retrieving https://centos7.iuscommunity.org/ius-release.rpm
    warning: /var/tmp/rpm-tmp.lWVMsi: Header V4 RSA/SHA256 Signature, key ID 4b274df2: NOKEY
    Preparing...                          ################################# [100%]
    Updating / installing...
       1:ius-release-2-1.el7.ius          ################################# [100%]

查看git2u的信息页::

    [root@server ~]# yum info git2u
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.tuna.tsinghua.edu.cn
     * centos-sclo-rh: mirrors.huaweicloud.com
     * extras: mirrors.tuna.tsinghua.edu.cn
     * updates: mirrors.tuna.tsinghua.edu.cn
    Available Packages
    Name        : git2u
    Arch        : x86_64
    Version     : 2.16.5
    Release     : 1.ius.centos7
    Size        : 1.1 M
    Repo        : ius/x86_64
    Summary     : Fast Version Control System
    URL         : https://git-scm.com
    License     : GPLv2
    Description : Git is a fast, scalable, distributed revision control system with an
                : unusually rich command set that provides both high-level operations
                : and full access to internals.
                : 
                : The git rpm installs common set of tools which are usually using with
                : small amount of dependencies. To install all git packages, including
                : tools for integrating with other SCMs, install the git-all meta-package.

通过第三方库安装git
------------------------------------------------

安装git2u::

    [root@server ~]# yum install git2u -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.neusoft.edu.cn
     * centos-sclo-rh: mirrors.neusoft.edu.cn
     * epel: fedora.cs.nctu.edu.tw
     * extras: mirrors.neusoft.edu.cn
     * updates: mirrors.cn99.com
    Resolving Dependencies
    --> Running transaction check
    ---> Package git2u.x86_64 0:2.16.5-1.ius.el7 will be installed
    --> Processing Dependency: git2u-perl-Git = 2.16.5-1.ius.el7 for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Processing Dependency: git2u-core-doc = 2.16.5-1.ius.el7 for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Processing Dependency: git2u-core = 2.16.5-1.ius.el7 for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Processing Dependency: perl(Git::I18N) for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Processing Dependency: perl(Git) for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Processing Dependency: libsecret-1.so.0()(64bit) for package: git2u-2.16.5-1.ius.el7.x86_64
    --> Running transaction check
    ---> Package git2u-core.x86_64 0:2.16.5-1.ius.el7 will be installed
    ---> Package git2u-core-doc.noarch 0:2.16.5-1.ius.el7 will be installed
    ---> Package git2u-perl-Git.noarch 0:2.16.5-1.ius.el7 will be installed
    ---> Package libsecret.x86_64 0:0.18.6-1.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                            Arch                       Version                               Repository                Size
    ====================================================================================================================================
    Installing:
     git2u                              x86_64                     2.16.5-1.ius.el7                      ius                      1.1 M
    Installing for dependencies:
     git2u-core                         x86_64                     2.16.5-1.ius.el7                      ius                      5.5 M
     git2u-core-doc                     noarch                     2.16.5-1.ius.el7                      ius                      2.4 M
     git2u-perl-Git                     noarch                     2.16.5-1.ius.el7                      ius                       68 k
     libsecret                          x86_64                     0.18.6-1.el7                          base                     153 k

    Transaction Summary
    ====================================================================================================================================
    Install  1 Package (+4 Dependent packages)

查看git版本::

    [root@server ~]# git --version
    git version 2.16.5

查看git是否支持http和https协议::

    [root@server ~]# find / -name 'git*'|grep git-remote-http
    /usr/libexec/git-core/git-remote-http
    /usr/libexec/git-core/git-remote-https

说明git支持http和https协议，说明git安装成功！


创建git用户并配置密钥
-------------------------------------------

创建git用户::

    [root@server ~]# useradd git
    [root@server ~]# cat /etc/passwd|grep git
    git:x:1001:1001::/home/git:/bin/bash

设置git账户的密码::

    [root@server ~]# echo "hellogit" |passwd --stdin git
    Changing password for user git.
    passwd: all authentication tokens updated successfully.

说明: ``--stdin`` 参数表明从标准输入或管道中读入新密码。

切换到git账户，并创建密钥::

    [root@server git]# su git
    [git@server ~]$ whoami
    git
    [git@server ~]$ pwd
    /home/git     
    [git@server ~]$ ssh-keygen 
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/git/.ssh/id_rsa): 
    Created directory '/home/git/.ssh'.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /home/git/.ssh/id_rsa.
    Your public key has been saved in /home/git/.ssh/id_rsa.pub.
    The key fingerprint is:
    SHA256:IahNqm2BLRFt0hFS6A0MxD5NX04iWt2Iw6CvFWH38Xg git@server.hopewait
    The key's randomart image is:
    +---[RSA 2048]----+
    |OBOo+ +          |
    |+B+X * B         |
    |=oO * O E        |
    | X O . + .       |
    |o O .   S        |
    | * .             |
    |o o              |
    | .               |
    |                 |
    +----[SHA256]-----+

创建 ``~/.ssh/authorized_keys`` 文件,用于存放用户公钥，并设置仅git可读写权限::

    [git@server ~]$ ls -lah .ssh/
    total 8.0K
    drwx------. 2 git git   38 Jun  4 21:45 .
    drwx------. 3 git git   74 Jun  4 21:45 ..
    -rw-------. 1 git git 1.7K Jun  4 21:45 id_rsa
    -rw-r--r--. 1 git git  401 Jun  4 21:45 id_rsa.pub
    [git@server ~]$ touch ~/.ssh/authorized_keys
    [git@server ~]$ ls -lah ~/.ssh/authorized_keys 
    -rw-rw-r--. 1 git git 0 Jun  4 21:47 /home/git/.ssh/authorized_keys
    [git@server ~]$ chmod 600 ~/.ssh/authorized_keys 
    [git@server ~]$ ls -lah ~/.ssh/
    total 8.0K
    drwx------. 2 git git   61 Jun  4 21:47 .
    drwx------. 3 git git   74 Jun  4 21:45 ..
    -rw-------. 1 git git    0 Jun  4 21:47 authorized_keys
    -rw-------. 1 git git 1.7K Jun  4 21:45 id_rsa
    -rw-r--r--. 1 git git  401 Jun  4 21:45 id_rsa.pub   
    
创建第一个git仓库
-------------------------------------------   
    
在git家目录下面创建gitrepos目录存放git仓库文件::
   
    [git@server ~]$ mkdir gitrepos
    [git@server ~]$ cd gitrepos/
    
初始化空仓库firstrepo.git::

    [git@server gitrepos]$ git init --bare firstrepo.git
    Initialized empty Git repository in /home/git/gitrepos/firstrepo.git/
    [git@server gitrepos]$ ls -lah
    total 0
    drwxrwxr-x. 3 git git  27 Jun  4 21:52 .
    drwx------. 4 git git  90 Jun  4 21:52 ..
    drwxrwxr-x. 7 git git 119 Jun  4 21:52 firstrepo.git
    [git@server gitrepos]$ tree firstrepo.git/
    firstrepo.git/
    |-- branches
    |-- config
    |-- description
    |-- HEAD
    |-- hooks
    |   |-- applypatch-msg.sample
    |   |-- commit-msg.sample
    |   |-- fsmonitor-watchman.sample
    |   |-- post-update.sample
    |   |-- pre-applypatch.sample
    |   |-- pre-commit.sample
    |   |-- prepare-commit-msg.sample
    |   |-- pre-push.sample
    |   |-- pre-rebase.sample
    |   |-- pre-receive.sample
    |   `-- update.sample
    |-- info
    |   `-- exclude
    |-- objects
    |   |-- info
    |   `-- pack
    `-- refs
        |-- heads
        `-- tags

    9 directories, 15 files
    [git@server gitrepos]$ 

   
客户端对git仓库下载和修改
-------------------------------------

配置客户端的密钥::

    [root@client ~]# ssh-keygen 
    Generating public/private rsa key pair.
    Enter file in which to save the key (/root/.ssh/id_rsa): 
    Created directory '/root/.ssh'.
    Enter passphrase (empty for no passphrase): 
    Enter same passphrase again: 
    Your identification has been saved in /root/.ssh/id_rsa.
    Your public key has been saved in /root/.ssh/id_rsa.pub.
    The key fingerprint is:
    SHA256:yZdAm2A3Ca873kziiZgKpue9jtNimStNiTSNXWwEWtQ root@client.hopewait
    The key's randomart image is:
    +---[RSA 2048]----+
    |  .+=.+.+.       |
    |  o  E =.+       |
    | .+ o   =        |
    | + o   o o .     |
    |....  . S o      |
    |. o    . .       |
    |.+ +  + .        |
    |= O=.+ B         |
    |o**==.+ o        |
    +----[SHA256]-----+
    [root@client ~]# ls -lah ~/.ssh/
    total 12K
    drwx------.  2 root root   38 Jun  4 21:59 .
    dr-xr-x---. 13 root root 4.0K Jun  4 21:59 ..
    -rw-------.  1 root root 1.7K Jun  4 21:59 id_rsa
    -rw-r--r--.  1 root root  402 Jun  4 21:59 id_rsa.pub

用ssh-copy-id将公钥复制到服务端主机中::

    [root@client ~]# ssh-copy-id 
    Usage: /usr/bin/ssh-copy-id [-h|-?|-f|-n] [-i [identity_file]] [-p port] [[-o <ssh -o options>] ...] [user@]hostname
            -f: force mode -- copy keys without trying to check if they are already installed
            -n: dry run    -- no keys are actually copied
            -h|-?: print this help
    [root@client ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub git@192.168.56.14
    /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
    The authenticity of host '192.168.56.14 (192.168.56.14)' can't be established.
    ECDSA key fingerprint is SHA256:7rw7b1vOEC5UmjDAbdIJ6SCK4aoGk5e+48vi3ubjdjE.
    ECDSA key fingerprint is MD5:96:39:70:28:72:73:f5:34:61:6f:b6:37:da:90:58:48.
    Are you sure you want to continue connecting (yes/no)? yes
    /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    git@192.168.56.14's password:      <------- 说明：此处需要输入git账号的密码"hellogit"，输入错误的话，需要重新输入
    Permission denied, please try again.
    git@192.168.56.14's password: 

    Number of key(s) added: 1

    Now try logging into the machine, with:   "ssh 'git@192.168.56.14'"
    and check to make sure that only the key(s) you wanted were added.

    [root@client ~]# 

在服务端可以发现 ``.ssh/authorized_keys`` 中已经多出来新的数据::

    [git@server ~]$ cat ~/.ssh/authorized_keys 
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmMWCxoQNJodtcxktr3tO2QIV+xv8s2qqXlPcgKpFc7nBMAMXQYCKuImxY5CN9Y8Q2y17T3StlELQIlBjnE6HQ5MmyOXcQ7DVpcISKmRcrgmctnya0q/KZO3gFFminTC9pIoGcfsuRRKPgnjZDmrAQmo/pr1olAePim7Tzi9HzB+g4Rhun/LSFpIOuMinFGERm7B+nXtigcL6ilRBcgM8yA98/t0duLoLi+XVSCu1YEL7SLRVgZrXfSL1i17pDuFwzPS0jvrq9vi0Xu7LlzjA2AwZExj0lSiKCP7LILPt/w05qd4M/K0FW1Q7W277wyvojyLBUejzjR58uczkVdS8D root@client.hopewait
    [git@server ~]$ 


客户端下载 ``firstrepo.git`` 仓库中文件::

    [root@client ~]# git clone git@192.168.39.138:/home/git/gitrepos/firstrepo.git
    Cloning into 'firstrepo'...
    ^C
    [root@client ~]# git clone git@192.168.56.14:/home/git/gitrepos/firstrepo.git 
    Cloning into 'firstrepo'...
    warning: You appear to have cloned an empty repository.
    [root@client ~]# ls
    anaconda-ks.cfg  firstrepo
    
设置客户端git用户名和邮件地址，用于后面向服务端提交时的用户日志信息::

    [root@client firstrepo]# git config --global --list
    fatal: unable to read config file '/root/.gitconfig': No such file or directory
    [root@client firstrepo]# git config --global user.name "Zhaohui Mei"
    [root@client firstrepo]# git config --global user.email "mzh.whut@gmail.com"
    [root@client firstrepo]# git config --global --list
    user.name=Zhaohui Mei
    user.email=mzh.whut@gmail.com

向仓库中添加文件，并提交::

    [root@client ~]# cd firstrepo/
    [root@client firstrepo]# ls
    [root@client firstrepo]# ls -lah
    total 4.0K
    drwxr-xr-x.  3 root root   18 Jun  4 22:14 .
    dr-xr-x---. 13 root root 4.0K Jun  4 22:14 ..
    drwxr-xr-x.  7 root root  119 Jun  4 22:14 .git
    [root@client firstrepo]# git remote -v
    origin  git@192.168.56.14:/home/git/gitrepos/firstrepo.git (fetch)
    origin  git@192.168.56.14:/home/git/gitrepos/firstrepo.git (push)
    [root@client firstrepo]# git branch
    [root@client firstrepo]# echo "hello,git" > README
    [root@client firstrepo]# git diff
    [root@client firstrepo]# git status
    On branch master

    No commits yet

    Untracked files:
      (use "git add <file>..." to include in what will be committed)

            README

    nothing added to commit but untracked files present (use "git add" to track) 

    [root@client firstrepo]# git add README 
    [root@client firstrepo]# git commit -m"add the first file"
    [master (root-commit) e25d3d4] add the first file
     1 file changed, 1 insertion(+)
     create mode 100644 README
    [root@client firstrepo]# git push origin master:master
    Counting objects: 3, done.
    Writing objects: 100% (3/3), 227 bytes | 227.00 KiB/s, done.
    Total 3 (delta 0), reused 0 (delta 0)
    To 192.168.56.14:/home/git/gitrepos/firstrepo.git
     * [new branch]      master -> master
    [root@client firstrepo]# git pull
    Already up to date.
    [root@client firstrepo]# git log
    commit e25d3d4b2a161201a20334653b42e803f5f16505 (HEAD -> master, origin/master)
    Author: Zhaohui Mei <mzh.whut@gmail.com>
    Date:   Tue Jun 4 22:22:39 2019 +0800

        add the first file
    [root@client firstrepo]#

在服务端也可以查看到刚才提交的修改::

    [git@server firstrepo.git]$ git log
    commit e25d3d4b2a161201a20334653b42e803f5f16505 (HEAD -> master)
    Author: Zhaohui Mei <mzh.whut@gmail.com>
    Date:   Tue Jun 4 22:22:39 2019 +0800

        add the first file
    [git@server firstrepo.git]$


参考文献


Download for Linux and Unix  https://www.git-scm.com/download/linux

创建版本库 https://www.liaoxuefeng.com/wiki/896043488029600/896827951938304
