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


配置CI持续集成工具gitlab-runner
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


