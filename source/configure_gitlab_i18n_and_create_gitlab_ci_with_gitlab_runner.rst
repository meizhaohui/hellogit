.. _configure_gitlab_i18n_and_create_gitlab_ci_with_gitlab_runner:

GitLab的汉化与CI持续集成gitlab-runner的配置
=================================================

.. contents:: 目录

本文讲解在 :ref:`CentOS7安装GitLab(使用外部Nginx配置) <centos7_install_gitlab_with_external_nginx>` 的基础上，对GitLab进行汉化，并配置CI持续集成工具gitlab-runner。





实验环境
-------------------------------------------------

- server服务端: 操作系统为CentOS 7.6，IP:192.168.56.14， git:2.16.5。

查看server服务端信息::

    [root@server ~]# cat /etc/centos-release
    CentOS Linux release 7.6.1810 (Core) 
    [root@server ~]# ip a show|grep 192
    inet 192.168.56.14/24 brd 192.168.56.255 scope global noprefixroute enp0s3
    [root@server ~]# git --version
    git version 2.16.5
    
GitLab用户信息::

    账号            密码
    root            1234567890
    meizhaohui      1234567890
    
- 虚拟机因为重启了，重新检查一下GitLab能否正常运行。

GitLab环境检查
-------------------------------------------------

进行检查::

    [root@server ~]# systemctl status nginx
    ● nginx.service - The nginx HTTP and reverse proxy server
       Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
       Active: active (running) since Thu 2019-06-27 19:58:19 CST; 57min ago
      Process: 13664 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
      Process: 13660 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
      Process: 13659 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
     Main PID: 13666 (nginx)
        Tasks: 2
       Memory: 10.5M
       CGroup: /system.slice/nginx.service
               ├─13666 nginx: master process /usr/sbin/nginx
               └─13667 nginx: worker process

    Jun 27 19:58:18 server.hopewait systemd[1]: Starting The nginx HTTP and reverse proxy server...
    Jun 27 19:58:19 server.hopewait nginx[13660]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    Jun 27 19:58:19 server.hopewait nginx[13660]: nginx: configuration file /etc/nginx/nginx.conf test is successful
    Jun 27 19:58:19 server.hopewait systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
    Jun 27 19:58:19 server.hopewait systemd[1]: Started The nginx HTTP and reverse proxy server.
    
Nginx服务正常运行，访问GitLab服务 http://192.168.56.14 ，发现可以正常访问：

.. image:: ./_static/images/gitlab_login_page.png

我们使用meizhaohui这个账号来下载hellopython项目::

    D:\Desktop                                            
    $ git clone git@192.168.56.14:higit/hellopython.git   
    Cloning into 'hellopython'...                         
    remote: Enumerating objects: 9, done.                 
    Receiving objects: 100% (9/9), done.    (9/9)         
    remote: Counting objects: 100% (9/9), done.           
    remote: Compressing objects: 100% (3/3), done.        
    remote: Total 9 (delta 0), reused 0 (delta 0)         

说明仍然可以下载，GitLab运行正常。

GitLab汉化
-------------------------------------------------

下面我们开始今天的主题，进行GitLab的汉化和CI的配置。

查看GitLab版本::

    [root@server ~]# cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
    11.10.0

查看GitLab中文社区官方仓库 https://gitlab.com/xhang/gitlab ， 检查对应的汉化包版本信息：

.. image:: ./_static/images/gitlab_stable_zh.png

我们下载GitLab版本对应的汉化包，11-10-stable-zh这个版本::

    [root@server ~]#  git clone https://gitlab.com/xhang/gitlab.git -b 11-10-stable-zh
    Cloning into 'gitlab'...
    remote: warning: ignoring extra bitmap file: /var/opt/gitlab/git-data/repositories/@pools/04/ad/04ad22d7630382dd5ece1410d2d8a131c44bdf54b53eb6b22a0276994b836d53.git/objects/pack/pack-573496940d56eadcba5a8d435e5b0f2345c9f918.pack
    remote: Enumerating objects: 979008, done.
    remote: Counting objects: 100% (979008/979008), done.
    remote: Compressing objects: 100% (203291/203291), done.
    remote: Total 979008 (delta 764750), reused 977616 (delta 763404)
    Receiving objects: 100% (979008/979008), 400.57 MiB | 36.88 MiB/s, done.
    Resolving deltas: 100% (764750/764750), done.

下载完后，查看的汉化包信息::

    [root@server ~]# ls -lad gitlab/
    drwxr-xr-x. 29 root root 4096 Jun 27 21:33 gitlab/
    [root@server ~]# cd gitlab/
    [root@server gitlab]# git remote -v
    origin  https://gitlab.com/xhang/gitlab.git (fetch)
    origin  https://gitlab.com/xhang/gitlab.git (push)
    [root@server gitlab]# git branch
    * 11-10-stable-zh

停止GitLab相关服务::

    [root@server ~]# gitlab-ctl stop
    ok: down: alertmanager: 0s, normally up
    ok: down: gitaly: 0s, normally up
    ok: down: gitlab-monitor: 0s, normally up
    ok: down: gitlab-workhorse: 0s, normally up
    ok: down: logrotate: 1s, normally up
    ok: down: node-exporter: 0s, normally up
    ok: down: postgres-exporter: 1s, normally up
    ok: down: postgresql: 0s, normally up
    ok: down: prometheus: 0s, normally up
    ok: down: redis: 0s, normally up
    ok: down: redis-exporter: 0s, normally up
    ok: down: sidekiq: 0s, normally up
    ok: down: unicorn: 0s, normally up
    [root@server ~]# systemctl stop gitlab-runsvdir
    [root@server ~]# systemctl stop nginx
    [root@server ~]# ps -ef|grep gitlab
    root     26384 13568  0 21:46 pts/0    00:00:00 grep --color=auto gitlab
    [root@server ~]# ps -ef|grep nginx
    root     26386 13568  0 21:46 pts/0    00:00:00 grep --color=auto nginx

说明GitLab相关服务已经停止。

备份 ``/opt/gitlab/embedded/service/gitlab-rails/`` 文件夹，防止后续操作失败导致GitLab无法运行::

    [root@server ~]# cp -rf /opt/gitlab/embedded/service/gitlab-rails/ /opt/gitlab/embedded/service/gitlab-rails.bak
    
    # 检查是否备份成功
    [root@server ~]# ls -lad /opt/gitlab/embedded/service/gitlab-rails*
    drwxr-xr-x 24 root root 4096 Jun 23 14:56 /opt/gitlab/embedded/service/gitlab-rails
    drwxr-xr-x 24 root root 4096 Jun 27 21:49 /opt/gitlab/embedded/service/gitlab-rails.bak
    [root@server ~]# du -sh /opt/gitlab/embedded/service/gitlab-rails* 
    253M    /opt/gitlab/embedded/service/gitlab-rails
    253M    /opt/gitlab/embedded/service/gitlab-rails.bak