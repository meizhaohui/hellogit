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

去除cp的别名，复制gitlab汉化包中的文件到 ``/opt/gitlab/embedded/service/gitlab-rails/`` 目录下::

    [root@server ~]# alias cp
    alias cp='cp -i'
    [root@server ~]# unalias cp
    [root@server ~]# cp -rf gitlab/* /opt/gitlab/embedded/service/gitlab-rails/
    cp: cannot overwrite non-directory ‘/opt/gitlab/embedded/service/gitlab-rails/log’ with directory ‘gitlab/log’
    cp: cannot overwrite non-directory ‘/opt/gitlab/embedded/service/gitlab-rails/tmp’ with directory ‘gitlab/tmp’

使配置生效::

    [root@server ~]# systemctl start gitlab-runsvdir
    [root@server ~]# gitlab-ctl reconfigure
    ...... 执行剧本，忽略
    Running handlers:
    Running handlers complete
    Chef Client finished, 5/609 resources updated in 01 minutes 10 seconds
    gitlab Reconfigured!
    [root@server ~]# 

启动GitLab和Nginx::

    [root@server ~]# gitlab-ctl start
    ok: run: alertmanager: (pid 22346) 697s
    ok: run: gitaly: (pid 22326) 697s
    ok: run: gitlab-monitor: (pid 22340) 697s
    ok: run: gitlab-workhorse: (pid 22334) 697s
    ok: run: logrotate: (pid 22336) 697s
    ok: run: node-exporter: (pid 22338) 697s
    ok: run: postgres-exporter: (pid 22348) 697s
    ok: run: postgresql: (pid 22328) 697s
    ok: run: prometheus: (pid 22344) 697s
    ok: run: redis: (pid 22324) 697s
    ok: run: redis-exporter: (pid 22342) 697s
    ok: run: sidekiq: (pid 22332) 697s
    ok: run: unicorn: (pid 22330) 697s
    [root@server ~]# systemctl start nginx
    [root@server ~]# 


访问GitLab服务 http://192.168.56.14 ，发现可以正常访问，并显示中文的页面：

.. image:: ./_static/images/gitlab_chinese_login_page.png

点击右上角的个人图标，在弹出的下拉选项中点击  ``Settings`` 进入到 ``Settings`` 设置界面：

.. image:: ./_static/images/gitlab_setting.png

点击左侧的 ``preferences`` 标签页，进入到个人偏好设置界面，下拉到 ``Localization`` 本地化的位置：

.. image:: ./_static/images/gitlab_preferences.png

点击 ``Language`` 语言下拉框选择 "简体中文"，并将周一设置为每周的第一天，并点击 ``Save changes`` 保存修改：

.. image:: ./_static/images/gitlab_change_language.png

保存后，按F5刷新一下页面，可以看到页面显示已经变成中文了：

.. image:: ./_static/images/gitlab_preferences_chinese.png

修改图像时，保存时，提示 "Request failed with status code 500" 异常，查看日志信息::

    [root@server ~]# tail -f /var/log/nginx/gitlab_error.log 
    2019/06/29 19:13:07 [crit] 24457#0: *206 open() "/var/lib/nginx/tmp/client_body/0000000001" failed (13: Permission denied), client: 192.168.56.1, server: 192.168.56.14, request: "POST /profile HTTP/1.1", host: "192.168.56.14", referrer: "http://192.168.56.14/profile"
    2019/06/29 19:13:51 [crit] 24457#0: *207 open() "/var/lib/nginx/tmp/client_body/0000000002" failed (13: Permission denied), client: 192.168.56.1, server: 192.168.56.14, request: "POST /profile HTTP/1.1", host: "192.168.56.14", referrer: "http://192.168.56.14/profile"
    2019/06/29 19:15:37 [crit] 24457#0: *212 open() "/var/lib/nginx/tmp/client_body/0000000003" failed (13: Permission denied), client: 192.168.56.1, server: 192.168.56.14, request: "POST /profile HTTP/1.1", host: "192.168.56.14", referrer: "http://192.168.56.14/profile"

发现权限不够，我们查看一下相关目录的权限::

    [root@server ~]# ls -lah /var/lib/nginx/tmp/
    total 0
    drwx------. 7 root  root 78 May 10 16:10 .
    drwx------. 3 root  root 17 May 10 16:10 ..
    drwx------. 2 nginx root  6 Jun 22 23:04 client_body
    drwx------. 2 nginx root  6 Jun 22 23:04 fastcgi
    drwx------. 2 nginx root  6 Jun 22 23:04 proxy
    drwx------. 2 nginx root  6 Jun 22 23:04 scgi
    drwx------. 2 nginx root  6 Jun 22 23:04 uwsgi
    
    [root@server ~]# ls -lad /var/lib/nginx/tmp/
    drwx------. 7 root root 78 May 10 16:10 /var/lib/nginx/tmp/
    [root@server ~]# chmod 755 /var/lib/nginx/tmp/
    [root@server ~]# ls -lad /var/lib/nginx/tmp/  
    drwxr-xr-x. 7 root root 78 May 10 16:10 /var/lib/nginx/tmp/
    
    [root@server ~]# ls -lahd /var/lib/nginx/
    drwx------. 3 root root 17 May 10 16:10 /var/lib/nginx/
    [root@server ~]# chmod 755 /var/lib/nginx
    [root@server ~]# ls -lahd /var/lib/nginx/
    drwxr-xr-x. 3 root root 17 May 10 16:10 /var/lib/nginx/
    [root@server ~]# ls -lad /var/lib/
    drwxr-xr-x. 33 root root 4096 Jun 23 20:18 /var/lib/

将 ``/var/lib/nginx/`` 和 ``/var/lib/nginx/tmp/`` 目录增加rx权限，再上传图像能够正常修改成功！可以看看很酷的头像：

.. image:: ./_static/images/gitlab_admin_icon.png

我们将"meizhaohui"这个账号设置为管理员，后期可以直接使用这个账号登陆操作GitLab。

设置后，使用"meizhaohui"登陆，设置头像等属性！


配置CI/CD
-------------------------------------------------

我们新建一个博客项目 ``bluelog`` ，并将博客项目的代码上传入库::

    D:\data\github_tmp\higit
    $ git clone git@192.168.56.14:higit/bluelog.git
    Cloning into 'bluelog'...
    warning: You appear to have cloned an empty repository.
    D:\data\github_tmp\higit
    $ git clone git@192.168.56.14:higit/bluelog.git
    Cloning into 'bluelog'...
    warning: You appear to have cloned an empty repository.
    
    D:\data\github_tmp\higit
    $ ls
    bluelog/
    
    D:\data\github_tmp\higit
    $ ls
    bluelog/
    
    D:\data\github_tmp\higit
    $ cd bluelog\
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git diff
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git status
    On branch master
    
    No commits yet
    
    Untracked files:
      (use "git add <file>..." to include in what will be committed)
    
            .flaskenv
            .gitignore
            LICENSE
            Pipfile
            Pipfile.lock
            README.md
            README_origin.md
            bluelog/
            logs/
    
    nothing added to commit but untracked files present (use "git add" to track)
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git add -A
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git commit -m"upload bluelog code"
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git push origin master:master
    Enumerating objects: 1115, done.
    Counting objects: 100% (1115/1115), done.
    Delta compression using up to 12 threads
    Compressing objects: 100% (1040/1040), done.
    Writing objects: 100% (1115/1115), 3.99 MiB | 5.91 MiB/s, done.
    Total 1115 (delta 261), reused 0 (delta 0)
    remote: Resolving deltas: 100% (261/261), done.
    To 192.168.56.14:higit/bluelog.git
     * [new branch]      master -> master
     
上传完成后，查看 ``bluelog`` 项目：

.. image:: ./_static/images/gitlab_bluelog_project.png

我们点击"配置CD/CD"按钮：

.. image:: ./_static/images/gitlab_configure_ci_cd.png

我们点击"选择一个GitLab CI Yaml模板"：

.. image:: ./_static/images/gitlab_cicd_template.png

选择 ``Bash`` 模板：

.. image:: ./_static/images/gitlab_cicd_bash_template.png

会自动加入Bash模板的内容，我们点击"提交修改"按钮进行提交，并检查CI/CD中的流水线工程：

.. image:: ./_static/images/gitlab_cicd-pipeline.png

发现流水线任务的状态是 ``"卡住(stuck)"`` ``"等待中"``，说明我们的流水线配置还不正确，没能正确的运行。

.. image:: ./_static/images/gitlab_cicd_job_stuck.png

提示 ``作业卡住了，请检查运行器`` ，我们查看具体哪个JOB卡住了：

.. image:: ./_static/images/gitlab_cicd_build_stuck.png

我们查看build这个作业的详情页面：

.. image:: ./_static/images/gitlab_cicd_build_stuck_detail.png

可以看到提示 ``由于您没有任何可以运行此作业的活跃运行器，因此作业卡住了。转到 Runner页面`` ，说明我们没有配置运行器，我们点击"Runner页面"跳转到运行器配置页面：

.. image:: ./_static/images/gitlab_cicd_gitlab_runner_page.png

终于到了GitLab Runner界面了，这个就是我们接下来要重点讲的 ``GitLab Runner`` ，也就是 ``运行器`` ！

什么是GitLab Runner
-------------------------------------------------

- Runner是一个执行任务的进程。您可以根据需要配置任意数量的Runner。 
- Runner可以放在不同的用户、服务器，甚至本地机器上。

- 每个Runner可以处于以下状态中的其中一种：

    - ``active`` Runner已启用，随时可以处理新作业
    - ``paused`` Runner已暂停，暂时不会接受新的作业

- 要开始使用作业，您可以向项目添加特定的运行器或使用共享的运行器。

- 可以设置 ``专用Runner`` 、 ``共享Runner`` 、 ``群组Runner`` 。

- 手动设置专用Runner的步骤：

    - 安装 GitLab Runner
    - 在Runner设置时指定URL
    - 在Runner设置时使用注册令牌
    - 启动Runner
    
- GiTLab Runner就是运行器，类似于Jenkins，可以为我们执行一些CI持续集成、构建的脚本任务，运行器具有执行脚本、调度、协调的工作能力。

接下来我们为blog项目 ``bluelog`` 设置一个专用运行器 ``blog`` 。

安装GitLab Runner运行器
-------------------------------------------------

`Install GitLab Runner <https://docs.gitlab.com/runner/install/>`_ 官方文档指出：

    GitLab Runner can be installed and used on GNU/Linux, macOS, FreeBSD, and Windows. There are three ways to install it. Use Docker, download a binary manually, or use a repository for rpm/deb packages. Below you can find information on the different installation methods.

即GitLab Runner可以通过二进制文件安装、Docker镜像安装、包仓库安装。

我们使用通过第三种方式包仓库安装，即添加Yum源来进行安装。

添加官方YUM源::

    [root@server ~]# curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | sudo bash
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100  6753    0  6753    0     0   3420      0 --:--:--  0:00:01 --:--:--  3419
    Detected operating system as centos/7.
    Checking for curl...
    Detected curl...
    Downloading repository file: https://packages.gitlab.com/install/repositories/runner/gitlab-runner/config_file.repo?os=centos&dist=7&source=script
    done.
    Installing pygpgme to verify GPG signatures...
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.cn99.com
     * centos-sclo-rh: ap.stykers.moe
     * extras: ap.stykers.moe
     * updates: ap.stykers.moe
    base                                                                                                                          | 3.6 kB  00:00:00     
    centos-sclo-rh                                                                                                                | 3.0 kB  00:00:00     
    docker-ce-stable                                                                                                              | 3.5 kB  00:00:00     
    epel                                                                                                                          | 5.3 kB  00:00:00 
    
    extras                                                                                                                        | 3.4 kB  00:00:00     
    gitlab-ce                                                                                                                     | 2.9 kB  00:00:00     
    ius                                                                                                                           | 1.3 kB  00:00:00     
    mariadb                                                                                                                       | 2.9 kB  00:00:00     
    runner_gitlab-runner-source/signature                                                                                         |  836 B  00:00:00     
    Retrieving key from https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    Importing GPG key 0xE15E78F4:
     Userid     : "GitLab B.V. (package repository signing key) <packages@gitlab.com>"
     Fingerprint: 1a4c 919d b987 d435 9396 38b9 1421 9a96 e15e 78f4
     From       : https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    Retrieving key from https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-366915F31B487241.pub.gpg
    runner_gitlab-runner-source/signature                                                                                         |  951 B  00:00:00 !!! 
    updates                                                                                                                       | 3.4 kB  00:00:00    
    (1/6): epel/x86_64/updateinfo                                                                                                 | 977 kB  00:00:01    
    (2/6): docker-ce-stable/x86_64/primary_db                                                                                     |  29 kB  00:00:02    
    (3/6): ius/x86_64/primary                                                                                                     | 123 kB  00:00:03    
    (4/6): gitlab-ce/7/primary_db                                                                                                 | 2.9 MB  00:00:06    
    (5/6): updates/7/x86_64/primary_db                                                                                            | 6.4 MB  00:00:07    
    (6/6): epel/x86_64/primary_db                               73% [====================================-             ] 1.0 MB/s |  13 MB  00:00:04 ETA
    Installing yum-utils...
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.cn99.com
     * centos-sclo-rh: ap.stykers.moe
     * extras: ap.stykers.moe
     * updates: ap.stykers.moe
    Package yum-utils-1.1.31-50.el7.noarch already installed and latest version
    Nothing to do
    Generating yum cache for runner_gitlab-runner...
    Importing GPG key 0xE15E78F4:
     Userid     : "GitLab B.V. (package repository signing key) <packages@gitlab.com>"
     Fingerprint: 1a4c 919d b987 d435 9396 38b9 1421 9a96 e15e 78f4
     From       : https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    Generating yum cache for runner_gitlab-runner-source...
    
    The repository is setup! You can now install packages.

查看Yum源中有哪些版本::

    [root@server ~]# yum search --showduplicates gitlab-runner
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.cn99.com
     * centos-sclo-rh: ap.stykers.moe
     * extras: ap.stykers.moe
     * updates: ap.stykers.moe
    ============================================================ N/S matched: gitlab-runner =============================================================
    gitlab-runner-10.0.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.0.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.0.2-1.x86_64 : GitLab Runner
    gitlab-runner-10.1.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.1.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.2.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.2.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.3.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.3.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.4.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.5.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.6.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.6.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.7.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.7.1-1.x86_64 : GitLab Runner
    gitlab-runner-10.7.2-1.x86_64 : GitLab Runner
    gitlab-runner-10.7.4-1.x86_64 : GitLab Runner
    gitlab-runner-10.8.0-1.x86_64 : GitLab Runner
    gitlab-runner-10.8.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.0.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.0.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.1.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.1.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.2.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.2.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.2.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.3.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.3.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.3.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.4.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.4.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.4.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.5.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.5.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.6.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.6.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.7.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.8.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.9.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.9.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.9.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.10.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.10.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.11.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.11.1-1.x86_64 : GitLab Runner
    gitlab-runner-11.11.2-1.x86_64 : GitLab Runner
    gitlab-runner-11.11.3-1.x86_64 : GitLab Runner
    gitlab-runner-12.0.0-1.x86_64 : GitLab Runner
    gitlab-runner-12.0.1-1.x86_64 : GitLab Runner
    
      Name and summary matches only, use "search all" for everything.

我们安装与GitLab大版本相同的GitLab Runner::

    [root@server ~]# cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
    11.10.6
    [root@server ~]# yum search --showduplicates gitlab-runner|grep 11.10
    gitlab-runner-11.10.0-1.x86_64 : GitLab Runner
    gitlab-runner-11.10.1-1.x86_64 : GitLab Runner
    
    [root@server ~]# yum install gitlab-runner-11.10.0 -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.cn99.com
     * centos-sclo-rh: ap.stykers.moe
     * extras: ap.stykers.moe
     * updates: ap.stykers.moe
    Resolving Dependencies
    --> Running transaction check
    ---> Package gitlab-runner.x86_64 0:11.10.0-1 will be installed
    --> Finished Dependency Resolution
    
    Dependencies Resolved
    
    =====================================================================================================================================================
     Package                             Arch                         Version                           Repository                                  Size
    =====================================================================================================================================================
    Installing:
     gitlab-runner                       x86_64                       11.10.0-1                         runner_gitlab-runner                        31 M
    
    Transaction Summary
    =====================================================================================================================================================
    Install  1 Package
    
    Total download size: 31 M
    Installed size: 52 M
    Downloading packages:
    gitlab-runner-11.10.0-1.x86_64.rpm                           0% [                                                  ]  64 kB/s | 169 kB  00:08:08 ETA 
    gitlab-runner-11.10.0-1.x86_64.rpm                          14% [=======                                           ]  54 kB/s | 4.6 MB  00:08:14 ETA 
    gitlab-runner-11.10.0-1.x86_64.rpm                          19% [=========-     gitlab-runner-11.10.0-1.x86_64.rpm                          19% [=========-     gitlab-runner-11.10.0-1.x8 28% [====-           ]  60 kB/s | 8.7 MB   06:13 ETA 
    gitlab-runner-11.10.0-1.x8 36% [=====-          ]  36 kB/s |  11 MB   09:12 ETA 
    gitlab-runner-11.10.0-1.x86_64.rpm                          45% [======================-                           ]  65 kB/s |  14 MB  00:04:18 ETA 
    gitlab-runner-11.10.0-1.x86_64.rpm                          63% [===============================-                  ]  89 kB/s |  19 MB  00:02:09 ETA 
    gitlab-runner-11.10.0-1.x86_64.rpm                          83% [=========================================-        ] 136 kB/s |  26 MB  00:00:36 ETA 
    warning: /var/cache/yum/x86_64/7/runner_gitlab-runner/packages/gitlab-runner-11.10.0-1.x86_64.rpm: Header V4 RSA/SHA512 Signature, key ID 880721d4: NOKEY
    Public key for gitlab-runner-11.10.0-1.x86_64.rpm is not installed
    gitlab-runner-11.10.0-1.x86_64.rpm                                                                                            |  31 MB  00:06:50     
    Retrieving key from https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    Importing GPG key 0xE15E78F4:
     Userid     : "GitLab B.V. (package repository signing key) <packages@gitlab.com>"
     Fingerprint: 1a4c 919d b987 d435 9396 38b9 1421 9a96 e15e 78f4
     From       : https://packages.gitlab.com/runner/gitlab-runner/gpgkey
    Retrieving key from https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-366915F31B487241.pub.gpg
    Importing GPG key 0x880721D4:
     Userid     : "GitLab, Inc. <support@gitlab.com>"
     Fingerprint: 3018 3ac2 c4e2 3a40 9efb e705 9ce4 5abc 8807 21d4
     From       : https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-366915F31B487241.pub.gpg
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : gitlab-runner-11.10.0-1.x86_64                                                                                                    1/1 
    GitLab Runner: creating gitlab-runner...
    Runtime platform                                    arch=amd64 os=linux pid=19979 revision=3001a600 version=11.10.0
    gitlab-runner: Service is not running.
    Runtime platform                                    arch=amd64 os=linux pid=19985 revision=3001a600 version=11.10.0
    gitlab-ci-multi-runner: Service is not running.
    Runtime platform                                    arch=amd64 os=linux pid=20004 revision=3001a600 version=11.10.0
    Runtime platform                                    arch=amd64 os=linux pid=20039 revision=3001a600 version=11.10.0
    Clearing docker cache...
      Verifying  : gitlab-runner-11.10.0-1.x86_64                                                                                                    1/1 
    
    Installed:
      gitlab-runner.x86_64 0:11.10.0-1                                                                                                                   
    
    Complete!

查看gitlab-runner版本信息及帮助信息::

    [root@server ~]# gitlab-runner --version
    Version:      11.10.0
    Git revision: 3001a600
    Git branch:   11-10-stable
    GO version:   go1.8.7
    Built:        2019-04-19T09:48:55+0000
    OS/Arch:      linux/amd64
    [root@server ~]# gitlab-runner --help
    NAME:
       gitlab-runner - a GitLab Runner
    
    USAGE:
       gitlab-runner [global options] command [command options] [arguments...]
    
    VERSION:
       11.10.0 (3001a600)
    
    AUTHOR:
       GitLab Inc. <support@gitlab.com>
    
    COMMANDS:
         exec                  execute a build locally
         list                  List all configured runners
         run                   run multi runner service
         register              register a new runner
         install               install service
         uninstall             uninstall service
         start                 start service
         stop                  stop service
         restart               restart service
         status                get status of a service
         run-single            start single runner
         unregister            unregister specific runner
         verify                verify all registered runners
         artifacts-downloader  download and extract build artifacts (internal)
         artifacts-uploader    create and upload build artifacts (internal)
         cache-archiver        create and upload cache artifacts (internal)
         cache-extractor       download and extract cache artifacts (internal)
         cache-init            changed permissions for cache paths (internal)
         health-check          check health for a specific address
         help, h               Shows a list of commands or help for one command
    
    GLOBAL OPTIONS:
       --cpuprofile value           write cpu profile to file [$CPU_PROFILE]
       --debug                      debug mode [$DEBUG]
       --log-format value           Choose log format (options: runner, text, json) [$LOG_FORMAT]
       --log-level value, -l value  Log level (options: debug, info, warn, error, fatal, panic) [$LOG_LEVEL]
       --help, -h                   show help
       --version, -v                print the version



