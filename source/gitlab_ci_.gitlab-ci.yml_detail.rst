.. _gitlab_ci_.gitlab-ci.yml_detail:

GitLab CI流水线配置文件.gitlab-ci.yml详解
=================================================

.. contents:: 目录

本文讲解在 :ref:`GitLab的汉化与CI持续集成gitlab-runner的配置 <configure_gitlab_i18n_and_create_gitlab_ci_with_gitlab_runner>` 的基础上，对GitLab CI流水线配置文件 ``.gitlab-ci.yml`` 进行详细的介绍。





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
    
GitLab WEB网站地址： http://192.168.56.14


之前我们配置的 ``bluelog`` 的4#流水线已经 **已通过** 了：

.. image:: ./_static/images/gitlab_cicd-pipeline_detail.png

可以发现其 ``build`` 、``Test`` 、``Deploy`` 三个阶段的任务都执行成功！

而流水线执行的具体过程都是由 ``.gitlab-ci.yml`` 配置文件定义的，本文详细讲解 ``.gitlab-ci.yml`` 配置文件的使用。

GitLab CI介绍
-------------------------------------------------

- GitLab提交持续集成服务，当你在项目根目录中添加 ``.gitlab-ci.yml`` 文件，并配置项目的运行器( ``GitLab Runner`` )，那么后续的每次提交都会触发CI流水线( ``pipeline`` )的执行。

- ``.gitlab-ci.yml`` 文件告诉运行器需要做哪些事情，默认情况下，流水线有 ``build`` 、``test`` 、``deploy`` 三个阶段，即 ``构建`` 、``测试`` 、``部署`` ，未被使用的阶段将会被自动忽略。

- 如果一切运行正常（没有非零返回值），您将获得与提交相关联的漂亮绿色复选标记(如下图所示)。这样可以在查看代码之前轻松查看提交是否导致任何测试失败。

.. image:: ./_static/images/gitlab_cicd_green_checkmark.png 

- 大多数项目使用GitLab的CI服务来运行测试套件，以便开发人员在破坏某些内容时可以立即获得反馈。使用持续交付和持续部署将测试代码自动部署到模拟环境和生产环境的趋势越来越明显。

- 由于将 ``.gitlab-ci.yml`` 文件存放在仓库中进行版本控制，使用单一的配置文件来控制流水线，具有读访问权限的每个人都可以查看内容，从而使其更有吸引力地改进和查看构建脚本。旧的版本也能构建成功，forks项目也容易使用CI，分支可以有不同的流水线和作业。

-  ``.gitlab-ci.yml`` 定义每个项目的流水线的结构和顺序，由以下两个因素决定：
  
  - GiTlab Runner运行器使用的执行器( ``executor`` )，执行器常用的 ``Shell`` 、 ``Docker`` 、``Kubernets`` ， 我们当前仅使用 ``Shell`` 执行器，后续再使用其他执行器。
  - 遇到进程成功或失败时等条件时做出的决定。

- 可以在 `Getting started with GitLab CI/CD <https://docs.gitlab.com/ce/ci/quick_start/README.html>`_ 查看到流水线的简单示例。
- 可以在 `GitLab CI/CD Examples <https://docs.gitlab.com/ce/ci/examples/README.html>`_ 查看更多的流水线示例。
- 在流水线脚本中可以使用预定义的全局变量，详细可查看 `GitLab CI/CD Variables <https://docs.gitlab.com/ce/ci/variables/README.html>`_ 。
- 企业级的 ``.gitlab-ci.yml`` 示例可查看 https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml 。
- Job作业是 ``.gitlab-ci.yml`` 文件的基本元素，每个作业至少有 ``script`` 子句，在流水线中可以定义任意多个作业。
- 每个作业必须具有唯一的名称，但有一些保留的关键字不能用作作业名称，保留关键字( ``reserved keywords`` )有  ``image`` 、 ``services`` 、 ``stages`` 、 ``types`` 、 ``before_script`` 、 ``after_script`` 、 ``variables`` 、 ``cache`` 。

``.gitlab-ci.yml`` 配置参数
-------------------------------------------------


+---------------+-------------------------------------------------------+
|   关键字      |                描述                                   |
+---------------+-------------------------------------------------------+
|   script      |                必须参数，运行器需要执行的脚本         |
+---------------+-------------------------------------------------------+
|   image       |                使用Docker image镜像                   |
+---------------+-------------------------------------------------------+
|  services     |                使用Docker services镜像                |
+---------------+-------------------------------------------------------+
| before_script |                作业执行前需要执行的命令               |
+---------------+-------------------------------------------------------+
| after_script  |                作业执行后需要执行的命令               |
+---------------+-------------------------------------------------------+
|    stages     |                定义流水线所有的阶段                   |
+---------------+-------------------------------------------------------+
|    stage      |        定义作业所处流水线的阶段(默认test阶段)         |
+---------------+-------------------------------------------------------+
|     only      |                限制作业在什么时候创建                 |
+---------------+-------------------------------------------------------+
|    except     |                限制作业在什么时候不创建               |
+---------------+-------------------------------------------------------+
|     tags      |            作用使用的Runner运行器的标签列表           |
+---------------+-------------------------------------------------------+
| allow_failure |       允许作业失败，失败的作业不影响提交的状态        |
+---------------+-------------------------------------------------------+
|     when      |                  什么时候运行作业                     |
+---------------+-------------------------------------------------------+
|  environment  |                  作用部署的环境名称                   |
+---------------+-------------------------------------------------------+
|     cache     |          指定需要在job之间缓存的文件或目录            |
+---------------+-------------------------------------------------------+
|   artifacts   | 归档文件列表，指定成功后应附加到job的文件和目录的列表 |
+---------------+-------------------------------------------------------+
|  dependencies |  当前作业依赖的其他作业，你可以使用依赖作业的归档文件 |
+---------------+-------------------------------------------------------+
|   coverage    |                 作业的代码覆盖率                      |
+---------------+-------------------------------------------------------+
|     retry     |              作业失败时，可以自动执行多少次           |
+---------------+-------------------------------------------------------+
|   parallel    |                 指定并行运行的作业实例                |
+---------------+-------------------------------------------------------+
|   trigger     |                 定义下游流水线的触发器                |
+---------------+-------------------------------------------------------+
|   include     |                 作业加载其他YAML文件                  |
+---------------+-------------------------------------------------------+
|   extends     |                 控制实体从哪里继承                    |
+---------------+-------------------------------------------------------+
|     pages     |                 上传GitLab Pages的结果                |
+---------------+-------------------------------------------------------+
|     retry     |              作业失败时，可以自动执行多少次           |
+---------------+-------------------------------------------------------+
|   variables   |                    定义环境变量                       |
+---------------+-------------------------------------------------------+


参数详解
-------------------------------------------------

``script``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``script`` 是作业中唯一必须的关键字参数，是运行器需要执行的脚本，如::

    build1:
      script:
        - echo "Do your build here"
        - uname -a

表示build1作业需要执行的命令是输出"Do your build here"。

.. WARNING:: Sometimes, script commands will need to be wrapped in single or double quotes. For example, commands that contain a colon (:) need to be wrapped in quotes so that the YAML parser knows to interpret the whole thing as a string rather than a “key: value” pair. Be careful when using special characters: :, {, }, \[, \], ,, &, \*, #, ?, \|, -, <, >, =, !, %, @, \`. 即使用冒号时应使用引号包裹起来，使用特殊字符时需要特别注意！！！注意如果要输出冒号字符，冒号后面不能紧接空格！！！

``image``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``image`` 指定使用Docker镜像。如 ``iamge:name`` ，暂时忽略。

``services``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``services`` 指定使用Docker镜像服务。如 ``services:name`` ，暂时忽略。

``before_script``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``before_script`` 用于定义在所有作业之前需要执行的命令，比如更新代码、安装依赖、打印调试信息之类的事情。

示例::

    before_script:
      - echo "Before script section"
      - echo "For example you might run an update here or install a build dependency"
      - echo "Or perhaps you might print out some debugging details"


``after_script``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``after_script`` 用于定义在所有作业(即使失败)之后需要执行的命令，比如清空工作空间。

示例::

    after_script:
      - echo "After script section"
      - echo "For example you might do some cleanup here"

.. Important::

    - before_script和script在一个上下文中是串行执行的，after_script是独立执行的，即after_script与before_script/script的上下文环境不同。
    - after_script会将当前工作目录设置为默认值。
    - 由于after_script是分离的上下文，在after_script中无法看到在before_script和script中所做的修改:
    
        - 在before_script和script中的命名别名、导出变量，对after_script不可见；
        - before_script和script在工作树之外安装的软件，对after_script不可见。
    
    - 你可以在作业中定义before_script，after_script，也可以将其定义为顶级元素，定义为顶级元素将为每一个任务都执行相应阶段的脚本或命令。作业级会覆盖全局级的定义。

示例::

    before_script:
      - echo "Before script section"
      - echo "For example you might run an update here or install a build dependency"
      - echo "Or perhaps you might print out some debugging details"
    
    after_script:
      - echo "After script section"
      - echo "For example you might do some cleanup here"
    
    build1:
      stage: build
      before_script:
        - echo "Before script in build stage that overwrited the globally defined before_script"
        - echo "Install cloc:A tool to count lines of code in various languages from a given directory."
        - yum install cloc -y
      after_script:
        - echo "After script in build stage that overwrited the globally defined after_script"
        - cloc --version
        - cloc .
      script:
        - echo "Do your build here"
        - cloc --version
        - cloc .
      tags:
        - bluelog

将修改上传提交，查看作业build1的控制台输出：

.. image:: ./_static/images/job_before_script_overwrited_global_before_script.png
.. image:: ./_static/images/job_after_script_overwrited_global_after_script.png

可以发现build1作业的 ``before_script`` 和 ``after_script`` 将全局的 ``before_script`` 和 ``after_script`` 覆盖了。


``stages``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``stages`` 定义流水线全局可使用的阶段，阶段允许有灵活的多级管道，阶段元素的排序定义了作业执行的顺序。

- 相同 ``stage`` 阶段的作业并行运行。
- 默认情况下，上一阶段的作业全部运行成功后才执行下一阶段的作业。
- 默认有三个阶段， ``build`` 、``test`` 、``deploy`` 三个阶段，即 ``构建`` 、``测试`` 、``部署`` 。
- 如果一个作业未定义  ``stage`` 阶段，则作业使用 ``test`` 测试阶段。
- 默认情况下，任何一个前置的作业失败了，commit提交会标记为failed并且下一个stages的作业都不会执行。

``stage``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``stage`` 定义流水线中每个作业所处的阶段，处于相同阶段的作业并行执行。

示例::

    # This file is a template, and might need editing before it works on your project.
    # see https://docs.gitlab.com/ce/ci/yaml/README.html for all available options
    
    
    before_script:
      - echo "Before script section"
      - echo "For example you might run an update here or install a build dependency"
      - echo "Or perhaps you might print out some debugging details"
    
    after_script:
      - echo "After script section"
      - echo "For example you might do some cleanup here"
    
    stages:
      - build
      - code_check
      - test
      - deploy
      
    build1:
      stage: build
      before_script:
        - echo "Before script in build stage that overwrited the globally defined before_script"
        - echo "Install cloc:A tool to count lines of code in various languages from a given directory."
        - yum install cloc -y
      after_script:
        - echo "After script in build stage that overwrited the globally defined after_script"
        - cloc --version
        - cloc .
      script:
        - echo "Do your build here"
        - cloc --version
        - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        

我们增加一个 ``code_check`` 阶段，该阶段有一个作业 ``find Bugs`` ，该作业主要是先安装Flake8，然后使用Flake8对Python代码进行规范检查。

.. image:: ./_static/images/job_code_check_failed.png

由于Flake8检查到了Python代码中的缺陷，导致find Bugs作业失败！这样可以控制开发人员提交有坏味道的代码到仓库中。

另外，在上一个流水线中，Test阶段的作业test1和test2是并行执行的，如下图所示：

.. image:: ./_static/images/test_jobs_are_executed_in_parallel.png

本次(pipeline #7)流水线由于在作业 ``find Bugs`` 检查不通过，导致整个流水线运行失败，后续的作业不会执行：

.. image:: ./_static/images/code_check_failed_no_jobs_of_further_stage_are_executed.png

.. Attention:: 

    默认情况下，GitLab Runner运行器每次只执行一个作业，只有当满足以下条件之一时，才会真正的并行执行:
    
        - 作业运行在不同的运行器上；
        - 你修改了运行器的 ``concurrent`` 设置，默认情况下 ``concurrent = 1`` 。 

``only`` 和 ``except``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``only`` 和 ``except`` 用于在创建作业时对作业的限制策略。

- ``only`` 定义了哪些分支或标签(branches and tags)的作业会运行
- ``except``  定义了哪些分支或标签(branches and tags)的作业不会运行

下面是策略规则：

- ``only`` 和 ``except`` 可同时使用，如果在一个作业中同时定义了 ``only`` 和 ``except`` ，则以 ``only`` 为准，跳过 ``except`` 。
- ``only`` 和 ``except`` 可以使用正则表达式。
- ``only`` 和 ``except`` 允许指定用于过滤forks作业的存储库路径。
- ``only`` 和 ``except`` 中可以使用特殊的关键字，如 ``branches`` 、 ``tags`` 、 ``api`` 、 ``external`` 、 ``pipelines`` 、 ``pushes`` 、 ``schedules`` 、 ``triggers`` 、 ``web`` 、 ``merge_requests`` 、 ``chats`` 等。

在下面这个例子中，job将只会运行以 ``issue-`` 开始的refs(分支)，然而except中设置将被跳过::

    job:
      # use regexp
      only:
        - /^issue-.*$/
      # use special keyword
      except:
        - branches

匹配模式默认是大小写敏感的(case-sensitive)，使用 ``i`` 标志，如 ``/pattern/i`` 可以使匹配模式大小写不敏感::

    job:
      # use regexp
      only:
        - /^issue-.*$/i
      # use special keyword
      except:
        - branches







参考：

- `Getting started with GitLab CI/CD <https://docs.gitlab.com/ce/ci/quick_start/README.html>`_
- `GitLab CI/CD Pipeline Configuration Reference  <https://docs.gitlab.com/ce/ci/yaml/README.html>`_
- `Gitlab CI yaml官方配置文件翻译 <https://segmentfault.com/a/1190000010442764>`_
- `GitLab Runner Advanced configuration <https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-shells>`_
- `Why we're replacing GitLab CI jobs with .gitlab-ci.yml <https://about.gitlab.com/2015/05/06/why-were-replacing-gitlab-ci-jobs-with-gitlab-ci-dot-yml/>`_
- `GitLab CI/CD Examples <https://docs.gitlab.com/ce/ci/examples/README.html>`_
- `GitLab CI/CD Variables <https://docs.gitlab.com/ce/ci/variables/README.html>`_
- `企业级.gitlab-ci.yml示例 <https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml>`_

