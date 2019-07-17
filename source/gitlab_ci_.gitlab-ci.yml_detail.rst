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

- ``only`` 和 ``except`` 可同时使用，如果在一个作业中同时定义了 ``only`` 和 ``except`` ，则同时 ``only``  ``except`` 进行过滤(注意，不是忽略  ``except`` 条件) 。
- ``only`` 和 ``except`` 可以使用正则表达式。
- ``only`` 和 ``except`` 允许指定用于过滤forks作业的存储库路径。
- ``only`` 和 ``except`` 中可以使用特殊的关键字，如 ``branches`` 、 ``tags`` 、 ``api`` 、 ``external`` 、 ``pipelines`` 、 ``pushes`` 、 ``schedules`` 、 ``triggers`` 、 ``web`` 、 ``merge_requests`` 、 ``chats`` 等。

``only`` 和 ``except`` 中可以使用特殊的关键字：

+----------------+---------------------------------------------------------------+
|     关键字     |                          描述释义                             |
+----------------+---------------------------------------------------------------+
|    branches    |                    当一个分支被push上来                       |
+----------------+---------------------------------------------------------------+
|     tags       |         当一个打了tag标记的Release被提交时                    |
+----------------+---------------------------------------------------------------+
|      api       |   当一个pipline被第二个piplines api所触发调起(不是触发器API)  |
+----------------+---------------------------------------------------------------+
|    external    |         当使用了GitLab以外的外部CI服务，如Jenkins             |
+----------------+---------------------------------------------------------------+
|   pipelines    | 针对多项目触发器而言，当使用CI_JOB_TOKEN，                    |
|                | 并使用gitlab所提供的api创建多个pipelines的时候                |
+----------------+---------------------------------------------------------------+
|    pushes      |            当pipeline被用户的git push操作所触发的时候         |
+----------------+---------------------------------------------------------------+
|   schedules    |           针对预定好的pipline计划而言（每日构建一类）         |
+----------------+---------------------------------------------------------------+
|   triggers     |               用触发器token创建piplines的时候                 |
+----------------+---------------------------------------------------------------+
|      web       |  在GitLab WEB页面上Pipelines标签页下，按下run pipline的时候   |
+----------------+---------------------------------------------------------------+
| merge_requests |                 当合并请求创建或更新的时候                    |
+----------------+---------------------------------------------------------------+
|       chats    |                当使用GitLab ChatOps 创建作业的时候            |
+----------------+---------------------------------------------------------------+


在下面这个例子中，job将只会运行以 ``issue-`` 开始的refs(分支)，然而except中指定分支不能执行，所以这个job将不会执行::

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

下面这个示例，仅当指定标记的tags的refs引用，或者通过API触发器的构建、或者流水线计划调度的构建才会运行::

    job:
      # use special keywords
      only:
        - tags
        - triggers
        - schedules

仓库的路径(repository path)只能用于父级仓库执行作业，不能用于forks::

    job:
      only:
        - branches@gitlab-org/gitlab-ce
      except:
        - master@gitlab-org/gitlab-ce
        - /^release/.*$/@gitlab-org/gitlab-ce

上面这个例子，将会在所有分支执行，但 **不会在** master主干以及以release/开头的分支上执行。

- 当一个作业没有定义 ``only`` 规则时，其默认为 ``only: ['branches', 'tags']`` 。
- 如果一个作业没有定义 ``except`` 规则时，则默认 ``except`` 规则为空。

下面这个两个例子是等价的::

    job:
      script: echo 'test'

转换后::

    job:
      script: echo 'test'
      only: ['branches', 'tags']

.. Attention::

    关于正则表达式使用的说明：
    
    - 因为 ``@`` 用于表示ref的存储库路径的开头，所以在正则表达式中匹配包含 ``@`` 字符的ref名称需要使用十六进制字符代码 ``\x40`` 。
    - 仅标签和分支名称才能使用正则表达式匹配，仓库路径按字面意义匹配。
    - 如果使用正则表达式匹配标签或分支名称，则匹配模式的整个引用部分都是正则表达式。
    - 正则表达式必须以 ``/`` 开头和结尾，即 ``/regular expressions/`` ，因此， ``issue-/.*/`` 不会匹配以 ``issue-`` 开头的标签或分支。
    - 可以在正则表达式中使用锚点 ``^$`` ，用来匹配开头或结尾，如 ``/^issue-.*$/`` 与 ``/^issue-/`` 等价， 但  ``/issue/`` 却可以匹配名称为 ``severe-issues`` 的分支，所以正则表达式的使用要谨慎！

``only`` 和 ``except`` 高级用法
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``only`` 和 ``except`` 支持高级策略，``refs`` 、 ``variables`` 、 ``changes`` 、 ``kubernetes`` 四个关键字可以使用。
- 如果同时使用多个关键字，中间的逻辑是 ``逻辑与AND`` 。


``only:refs/except:refs``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``refs`` 策略可以使用 ``only`` 和 ``except`` 基本用法中的关键字。

下面这个例子中，deploy作业仅当流水线是计划作业或者在master主干运行::

    deploy:
      only:
        refs:
          - master
          - schedules



``only:kubernetes/except:kubernetes``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``kubernetes`` 策略仅支持 ``active`` 关键字。

下面这个例子中，deploy作业仅当kubernetes服务启动后才会运行::

    deploy:
      only:
        kubernetes: active

``only:variables/except:variables``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``variables`` 关键字用来定义变量表达式，你可以使用预定义变量、项目、组、环境变量来评估一个作业是否需要创建或运行。

下面这个例子使用了变量表达式::

    deploy:
      script: cap staging deploy
      only:
        refs:
          - branches
        variables:
          - $RELEASE == "staging"
          - $STAGING

下面这个例子，会根据提交日志信息来排除某些作业::

    end-to-end:
      script: rake test:end-to-end
      except:
        variables:
          - $CI_COMMIT_MESSAGE =~ /skip-end-to-end-tests/

``only:changes/except:changes``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``changes`` 策略表明一个作业只有在使用 ``git push`` 事件使文件发生变化时执行。

下面这个例子中，deploy作业仅当流水线是计划作业或者在master主干运行::

    docker build:
      script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
      only:
        changes:
          - Dockerfile
          - docker/scripts/*
          - dockerfiles/**/*
          - more_scripts/*.{rb,py,sh}

上面这个例子中，一旦 ``Dockerfile`` 文件发生变化，或者 ``docker/scripts/`` 目录下的文件发生变化，或者 ``dockerfiles/`` 目录下的文件或目录发生变化，或者 ``more_scripts/`` 目录下 ``rb,py,sh`` 等脚本文件发生变化时，就会触发Docker构建。

- 也可以使用 ``glob模式匹配`` 来匹配根目录下的文件，或者任何目录下的文件。

如下示例::

    test:
      script: npm run test
      only:
        changes:
          - "*.json"
          - "**/*.sql"

.. Attention::

    在上面的示例中，``glob模式匹配`` 的字符串需要使用双引号包裹起来，否则会导致 ``.gitlab-ci.yml`` 解析错误。

下面这个例子，当md文件发生变化时，会忽略CI作业::

    build:
      script: npm run build
      except:
        changes:
          - "*.md"


.. Warning::

    记录一下官网说明中使用 ``change`` 时需要注意的两点：
    
    - Using changes with new branches and tags：When pushing a new branch or a new tag to GitLab, the policy always evaluates to true and GitLab will create a job. This feature is not connected with merge requests yet and, because GitLab is creating pipelines before a user can create a merge request, it is unknown what the target branch is at this point.
    - Using changes with merge_requests：With pipelines for merge requests, it is possible to define a job to be created based on files modified in a merge request.

在合并请求中使用 ``change`` 策略::

    docker build service one:
      script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
      only:
        refs:
          - merge_requests
        changes:
          - Dockerfile
          - service-one/**/*

上面这个例子中，一旦合并请求中修改了 ``Dockerfile`` 文件或者修改了 ``service`` 目录下的文件，都会触发Docker构建。

``only`` 和 ``except`` 综合示例
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

我们将 ``bluelog`` 项目的描述和主题进行修改：

.. image:: ./_static/images/project_description_tags.png

并创建三个分支 ``issue-pylint`` 、``Issue-flake8`` 和 ``severe-issues`` ：

.. image:: ./_static/images/project_three_branches.png

刚新增的三个分支，自动继承了master主干的CI RUNNER，因为Flake8检查代码质量没通过，流水线都失败了：

.. image:: ./_static/images/project_three_branches_pipeline_failed.png

**为了便于测试，将"meizhaohui"账号设置为** ``bluelog`` **项目的主程序员！**

现在朝 ``.gitlab-ci.yml`` 文件中增加 ``only`` 和 ``except`` 策略。


匹配 ``issue-`` 开头的分支
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


创建仅匹配 ``issue-`` 开头的分支：

.. image:: ./_static/images/only_match_startwith_issue.png

可以发现master主干没有执行 ``find Bugs`` 作业：

.. image:: ./_static/images/master_no_find_bugs.png

为了快速测试，我们对对个作业都使用  ``only`` 和 ``except`` 策略:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 31,44,58,70,82
    
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
        # cloc .
      only:
        - /^issue-.*$/
      except:
        - master
      script:
        - echo "Do your build here"
        - cloc --version
        # - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      only:
        - /^issue-.*$/
      except:
        - branches
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      only:
        - /^issue-.*$/
      except:
        - /issue-pylint/
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      only:
        - /^issue-.*$/
      except:
        - /Issue-flake8/
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      only:
        - /^issue-.*$/
      except:
        - /severe-issues/
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog

提交后，直接入库，检查master主干，并没有触发流水线作业。

统计作业流水线作业情况：

+---------------+----------+--------+-----------+---------+---------+-----------+
|     分支      |  流水线  | build1 | find Bugs |  test1  |  test2  |  deploy1  |
+---------------+----------+--------+-----------+---------+---------+-----------+
|     master    |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+
| issue-pylint  |    #22   |  Yes   |    No     |    No   |   Yes   |    Yes    |
+---------------+----------+--------+-----------+---------+---------+-----------+
| Issue-flake8  |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+
| severe-issues |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+

.. image:: ./_static/images/gitlab_only_except_pipeline_22.png

解释上面的流水作业策略：

+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|    作业       |                     规则定义                       |                                  规则解释                                    |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|     build1    |    ``only: - /^issue-.*$/ except: - master``       |  只在以issue-开头的分支执行，不在master主干执行                              |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|   find Bugs   |  ``only: - /^issue-.*$/ except: - branches``       |  只在以issue-开头的分支执行，不在 ``branches`` 分支执行，                    |
|               |                                                    |  由于issue-pylint也是分支，所以在issue-pylint中也不会执行find Bugs作业       |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|     test1     | ``only: - /^issue-.*$/ except: - /issue-pylint/``  |  只在以issue-开头的分支执行，不在issue-pylint分支执行，                      |
|               |                                                    |  即会在除了issue-pylint分支以外的issue-开头的分支执行，也即没有分支执行      |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|     test2     | ``only: - /^issue-.*$/ except: - /Issue-flake8/``  |  只在以issue-开头的分支执行，不在Issue-flake8分支执行，                      |
|               |                                                    |  因此可以issue-pylint分支执行                                                |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+
|    deploy1    | ``only: - /^issue-.*$/ except: - /severe-issues/`` |  只在以issue-开头的分支执行，不在severe-issues分支执行                       |
|               |                                                    |  因此可以issue-pylint分支执行                                                |
+---------------+----------------------------------------------------+------------------------------------------------------------------------------+

大小写不敏感匹配
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

好，我们再将 ``only`` 语法中加入语法大小写不敏感的 ``i`` 标志！再来做一次实验，看看最终的效果。

加入语法大小写不敏感的 ``i`` 标志:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 31,44,58,70,82
   
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
        # cloc .
      only:
        - /^issue-.*$/i
      except:
        - master
      script:
        - echo "Do your build here"
        - cloc --version
        # - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      only:
        - /^issue-.*$/i
      except:
        - branches
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      only:
        - /^issue-.*$/i
      except:
        - /issue-pylint/
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      only:
        - /^issue-.*$/i
      except:
        - /Issue-flake8/
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      only:
        - /^issue-.*$/i
      except:
        - /severe-issues/
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog
    

预期效果： ``issue-pylint`` 和 ``Issue-flake8`` 分支会触发流水线执行，``master`` 主干和 ``severe-issues`` 分支不会触发流水线执行。

统计作业流水线作业情况：

+---------------+----------+--------+-----------+---------+---------+-----------+
|     分支      |  流水线  | build1 | find Bugs |  test1  |  test2  |  deploy1  |
+---------------+----------+--------+-----------+---------+---------+-----------+
|     master    |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+
| issue-pylint  |    #23   |  Yes   |    No     |    No   |   Yes   |    Yes    |
+---------------+----------+--------+-----------+---------+---------+-----------+
| Issue-flake8  |    #24   |  Yes   |    No     |   Yes   |    No   |    Yes    |
+---------------+----------+--------+-----------+---------+---------+-----------+
| severe-issues |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+

正如我们预期的一样，``issue-pylint`` 和 ``Issue-flake8`` 分支会触发流水线执行，``master`` 主干和 ``severe-issues`` 分支不会触发流水线执行：

.. image:: ./_static/images/gitlab_only_except_pipeline_23.png
.. image:: ./_static/images/gitlab_only_except_pipeline_24.png

解释上面的流水作业策略：

+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|    作业       |                     规则定义                        |                                  规则解释                                    |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     build1    |    ``only: - /^issue-.*$/i except: - master``       |  只在以issue(不区分大小写)-开头的分支执行，不在master主干执行                |
|               |                                                     |  可以在issue-pylint和Issue-flake8分支执行                                    |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|   find Bugs   |  ``only: - /^issue-.*$/i except: - branches``       |  只在以issue(不区分大小写)-开头的分支执行，不在 ``branches`` 分支执行，      |
|               |                                                     |  由于issue-pylint也是分支，所以在issue-pylint中也不会执行find Bugs作业       |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     test1     | ``only: - /^issue-.*$/i except: - /issue-pylint/``  |  只在以issue(不区分大小写)-开头的分支执行，不在issue-pylint分支执行，        |
|               |                                                     |  即会在除了issue-pylint分支以外的issue-(不区分大小写)开头的分支执行，        |
|               |                                                     |  可以在Issue-flake8分支执行                                                  |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     test2     | ``only: - /^issue-.*$/i except: - /Issue-flake8/``  |  只在以issue(不区分大小写)-开头的分支执行，不在Issue-flake8分支执行，        |
|               |                                                     |  因此可以issue-pylint分支执行                                                |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|    deploy1    | ``only: - /^issue-.*$/i except: - /severe-issues/`` |  只在以issue(不区分大小写)-开头的分支执行，不在severe-issues分支执行         |
|               |                                                     |  可以在issue-pylint和Issue-flake8分支执行                                    |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+

我们再将 ``only`` 语法中将 ``/^issue-.*$/`` 改为 ``/issue/i`` ！再来做一次实验，看看最终的效果。

不区分大小写匹配issue字符：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 31,44,58,70,82
   
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
        # cloc .
      only:
        - /issue/i
      except:
        - master
      script:
        - echo "Do your build here"
        - cloc --version
        # - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      only:
        - /issue/i
      except:
        - branches
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      only:
        - /issue/i
      except:
        - /issue-pylint/
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      only:
        - /issue/i
      except:
        - /Issue-flake8/
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      only:
        - /issue/i
      except:
        - /severe-issues/
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog


预期效果：不区分大小写，``issue-pylint`` 、 ``Issue-flake8`` 和 ``severe-issues`` 分支分支会触发流水线执行，``master`` 主干不会触发流水线执行。

统计作业流水线作业情况：

+---------------+----------+--------+-----------+---------+---------+-----------+
|     分支      |  流水线  | build1 | find Bugs |  test1  |  test2  |  deploy1  |
+---------------+----------+--------+-----------+---------+---------+-----------+
|     master    |  未触发  |        |           |         |         |           |
+---------------+----------+--------+-----------+---------+---------+-----------+
| issue-pylint  |    #25   |  Yes   |    No     |    No   |   Yes   |    Yes    |
+---------------+----------+--------+-----------+---------+---------+-----------+
| Issue-flake8  |    #26   |  Yes   |    No     |   Yes   |    No   |    Yes    |
+---------------+----------+--------+-----------+---------+---------+-----------+
| severe-issues |    #27   |  Yes   |    No     |   Yes   |   Yes   |    No     |
+---------------+----------+--------+-----------+---------+---------+-----------+

正如我们预期的一样，``issue-pylint`` 、 ``Issue-flake8`` 和 ``severe-issues`` 分支会触发流水线执行，``master`` 主干不会触发流水线执行：

.. image:: ./_static/images/gitlab_only_except_pipeline_25.png
.. image:: ./_static/images/gitlab_only_except_pipeline_26.png
.. image:: ./_static/images/gitlab_only_except_pipeline_27.png

解释上面的流水作业策略：

+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|    作业       |                     规则定义                        |                                  规则解释                                    |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     build1    |    ``only: - /issue/i except: - master``            |  只在包含issue(不区分大小写)字符的分支执行，不在master主干执行               |
|               |                                                     |  因此在issue-pylint、Issue-flake8、severe-issues分支执行                     |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|   find Bugs   |  ``only: - /issue/i except: - branches``            |  只在包含issue(不区分大小写)字符的分支执行，不在 ``branches`` 分支执行，     |
|               |                                                     |  所以find Bugs作业一直不会执行                                               |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     test1     | ``only: - /issue/i except: - /issue-pylint/``       |  只在包含issue(不区分大小写)字符的分支执行，不在包含issue-pylint字符的分支   |
|               |                                                     |  执行，即会在除了issue-pylint分支以外包含issue(不区分大小写)字符的分支执行， |
|               |                                                     |  所以可以在Issue-flake8和severe-issues分支执行                               |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|     test2     | ``only: - /issue/i except: - /Issue-flake8/``       |  只在包含issue(不区分大小写)字符的分支执行，不在包含issue-flake8字符的分支   |
|               |                                                     |  执行，即会在除了issue-flake8分支以外包含issue(不区分大小写)字符的分支执行， |
|               |                                                     |  所以可以在issue-pylint和severe-issues分支执行                               |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+
|    deploy1    | ``only: - /issue/i except: - /severe-issues/``      |  只在包含issue(不区分大小写)字符的分支执行，不在包含severe-issues字符的分支  |
|               |                                                     |  执行，即会在除了severe-issues分支以外包含issue(不区分大小写)字符的分支执行, |
|               |                                                     |  所以可以在issue-pylint和Issue-flake8分支执行                                |
+---------------+-----------------------------------------------------+------------------------------------------------------------------------------+


git tag打标签的使用
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

**使用标签，可以标记提交历史上的特定点为重要提交。**

- 新建tag

``git tag -a v1.0 -m"Release v1.0"``

上面的命令我们成功创建了本地一个版本 V1.0 ,并且添加了附注信息 'Release 1.0'。

- 查看tag

``git tag``

- 显示tag附注信息

``git show v1.0``

- 提交本地tag到远程仓库

``git push origin v1.0``

- 提交本地所有tag到远程仓库

``git push origin --tags``

- 删除本地tag

``git tag -d v1.0``

- 删除远程tag

``git tag push origin :refs/tags/v1.0```

- 获取远程版本

``git fetch origin tag v1.0``

仅当tag标签提交时，才触发流水线执行
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

使用标签，可以标记提交历史上的特定点为重要提交，可以标记重要版本，如下图，是GitLab官方的Tag标签列表：

.. image:: ./_static/images/gitlab_office_tags_list.png

我们将流水线配置文件 ``.gitlab-ci.yml`` 修改为以下内容:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 31,44,58,70,82
   
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
        # cloc .
      only:
        - tags
      except:
        - master
      script:
        - echo "Do your build here"
        - cloc --version
        # - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      only:
        - tags
      except:
        - branches
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      only:
        - tags
      except:
        - /issue-pylint/
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      only:
        - tags
      except:
        - /Issue-flake8/
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      only:
        - tags
      except:
        - /severe-issues/
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog
    
查看差异::

    $ git diff                                                            
    diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml                          
    index 7f16137..8315eb0 100644                                         
    --- a/.gitlab-ci.yml                                                  
    +++ b/.gitlab-ci.yml                                                  
    @@ -28,7 +28,7 @@ build1:                                             
         - cloc --version                                                 
         # cloc .                                                         
       only:                                                              
    -    - /^issue-.*$/                                                   
    +    - tags                                                           
       except:                                                            
         - master                                                         
       script:                                                            
    @@ -41,7 +41,7 @@ build1:                                             
     find Bugs:                                                           
       stage: code_check                                                  
       only:                                                              
    -    - /^issue-.*$/                                                   
    +    - tags                                                           
       except:                                                            
         - branches                                                       
       script:                                                            
    @@ -55,7 +55,7 @@ find Bugs:                                          
     test1:                                                               
       stage: test                                                        
       only:                                                              
    -    - /^issue-.*$/                                                   
    +    - tags                                                           
       except:                                                            
         - /issue-pylint/                                                 
       script:                                                            
    @@ -67,7 +67,7 @@ test1:                                              
     test2:                                                               
       stage: test                                                        
       only:                                                              
    -    - /^issue-.*$/                                                   
    +    - tags                                                           
       except:                                                            
         - /Issue-flake8/                                                 
       script:                                                            
    @@ -79,7 +79,7 @@ test2:                                              
     deploy1:                                                             
       stage: deploy                                                      
       only:                                                              
    -    - /^issue-.*$/                                                   
    +    - tags                                                           
       except:                                                            
         - /severe-issues/                                                
       script:                                                            

提交::

    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git add -A
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git commit -m"测试tag标签触发流水线执行"
    [master eb9b468] 测试tag标签触发流水线执行
     1 file changed, 7 insertions(+), 5 deletions(-)
    
    D:\data\github_tmp\higit\bluelog (master -> origin)
    $ git push origin master:master
    Enumerating objects: 5, done.
    Counting objects: 100% (5/5), done.
    Delta compression using up to 12 threads
    Compressing objects: 100% (3/3), done.
    Writing objects: 100% (3/3), 365 bytes | 365.00 KiB/s, done.
    Total 3 (delta 2), reused 0 (delta 0)
    To 192.168.56.14:higit/bluelog.git
       1bd46f2..eb9b468  master -> master


查看是否触发流水线，可以发现没有触发流水线执行：

.. image:: ./_static/images/gitlab_submit_tags_no_trigger_pipeline.png

我们给 ``bluelog`` 打个 ``tag`` 标签，标签名称V0.1::

    D:\data\github_tmp\higit\bluelog (master -> origin)            
    $ git tag v0.1 -m"Release v0.1"                                
                                                                   
    D:\data\github_tmp\higit\bluelog (master -> origin)            
    $ git tag                                                      
    v0.1                                                           
                                                                   
    D:\data\github_tmp\higit\bluelog (master -> origin)            
    $ git push origin v0.1                                         
    Enumerating objects: 1, done.                                  
    Counting objects: 100% (1/1), done.                            
    Writing objects: 100% (1/1), 165 bytes | 165.00 KiB/s, done.   
    Total 1 (delta 0), reused 0 (delta 0)                          
    To 192.168.56.14:higit/bluelog.git                             
     * [new tag]         v0.1 -> v0.1                              

可以发现 ``bluelog`` 已经生成了一个tag版本：

.. image:: ./_static/images/gitlab_bluelog_tag_v0.1.png

在流水线列表中，也可以看#31号流水线被触发了，并且标签是v0.1:

.. image:: ./_static/images/gitlab_bluelog_pipeline_31_with_tag_v0.1.png

.. _trigger_pipeline_label:

使用流水线触发器触发流水线执行
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

我们给  ``bluelog`` 项目创建一个流水线触发器( ``Trigger`` )，在项目的 ``设置`` --> ``CI/CD`` --> ``流水线触发器`` 处增加流水线触发器：

.. image:: ./_static/images/gitlab_bluelog_add_pipeline_trigger_page.png

在"触发器描述"处填写"bluelog trigger"，然后点击"增加触发器"按钮，则会新增一个触发器:

.. image:: ./_static/images/gitlab_bluelog_trigger.png

我们修改 ``.gitlab-ci.yml`` 配置文件，将 ``build1`` 和 ``find Bugs`` 作业设置为仅 ``triggers`` 触发器能够触发执行:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 31,42
   
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
        # cloc .
      only:
        - triggers
      script:
        - echo "Do your build here"
        - cloc --version
        # - cloc .
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      only:
        - triggers
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog
        
    test1:
      stage: test
      only:
        - tags
      except:
        - /issue-pylint/
      script:
        - echo "Do a test here"
        - echo "For example run a test suite"
      tags:
        - bluelog
    
    test2:
      stage: test
      only:
        - tags
      except:
        - /Issue-flake8/
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      only:
        - tags
      except:
        - /severe-issues/
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog
    
提交修改::

    D:\data\github_tmp\higit\bluelog (master -> origin)                      
    $ git diff                                                               
    diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml                             
    index 657dc5e..921f93e 100644                                            
    --- a/.gitlab-ci.yml                                                     
    +++ b/.gitlab-ci.yml                                                     
    @@ -28,9 +28,7 @@ build1:                                                
         - cloc --version                                                    
         # cloc .                                                            
       only:                                                                 
    -    - tags                                                              
    -  except:                                                               
    -    - master                                                            
    +    - triggers                                                          
       script:                                                               
         - echo "Do your build here"                                         
         - cloc --version                                                    
    @@ -41,9 +39,7 @@ build1:                                                
     find Bugs:                                                              
       stage: code_check                                                     
       only:                                                                 
    -    - tags                                                              
    -  except:                                                               
    -    - branches                                                          
    +    - triggers                                                          
       script:                                                               
         - echo "Use Flake8 to check python code"                            
         - pip install flake8                                                
                                                                             
    D:\data\github_tmp\higit\bluelog (master -> origin)                      
    $ git add -A                                                             
                                                                             
    D:\data\github_tmp\higit\bluelog (master -> origin)                      
    $ git commit -m"使用触发器trigger触发流水线执行"                         
    [master 57f64a3] 使用触发器trigger触发流水线执行                         
     1 file changed, 2 insertions(+), 6 deletions(-)                         
                                                                             
    D:\data\github_tmp\higit\bluelog (master -> origin)                      
    $ git push origin master:master                                          
    Enumerating objects: 5, done.                                            
    Counting objects: 100% (5/5), done.                                      
    Delta compression using up to 12 threads                                 
    Compressing objects: 100% (3/3), done.                                   
    Writing objects: 100% (3/3), 361 bytes | 361.00 KiB/s, done.             
    Total 3 (delta 2), reused 0 (delta 0)                                    
    To 192.168.56.14:higit/bluelog.git                                       
       eb9b468..57f64a3  master -> master                                    
    
检查发现并没有触发流水线的执行：

.. image:: ./_static/images/gitlab_submit_triggers_no_trigger_pipeline.png
    
我们现在使用 ``curl`` 发送请求，触发流水线触发器执行::

    [root@server ~]# curl -X POST -F token=cf8a32f6f8a583263f6d042e6362d2 -F ref=master http://192.168.56.14/api/v4/projects/2/trigger/pipeline
    {"id":33,"sha":"57f64a35cad6d069dc62ddc93f0747296383826e","ref":"master","status":"pending","web_url":"http://192.168.56.14/higit/bluelog/pipelines/33","before_sha":"0000000000000000000000000000000000000000","tag":false,"yaml_errors":null,"user":{"id":2,"name":"梅朝辉","username":"meizhaohui","state":"active","avatar_url":"http://192.168.56.14/uploads/-/system/user/avatar/2/avatar.png","web_url":"http://192.168.56.14/meizhaohui"},"created_at":"2019-07-06T22:08:52.761+08:00","updated_at":"2019-07-06T22:08:53.026+08:00","started_at":null,"finished_at":null,"committed_at":null,"duration":null,"coverage":null,"detailed_status":{"icon":"status_pending","text":"等待中","label":"等待中","group":"pending","tooltip":"等待中","has_details":false,"details_path":"/higit/bluelog/pipelines/33","illustration":null,"favicon":"/assets/ci_favicons/favicon_status_pending-5bdf338420e5221ca24353b6bff1c9367189588750632e9a871b7af09ff6a2ae.png"}}

.. image:: ./_static/images/use_curl_post_gitlab_pipeline_trigger.png

可以发现流水线已经被执行，#33号流水线执行了 ``build1`` 和 ``find Bugs`` 作业，其他作业并未执行，与我们预期的相同：

.. image:: ./_static/images/use_curl_post_gitlab_pipeline_trigger_33.png

根据流水线触发器( ``Trigger`` )创建处的提示，我们也可以在依赖项目中配置触发器，依赖项目流水线结束时触发此项目重新构建。

``only`` 和 ``except`` 其他关键字的使用可参才官网文档 https://docs.gitlab.com/ce/ci/yaml/README.html#onlyexcept-basic ，此处暂时不表。

``tags``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``tags`` 关键字用于指定 ``GitLab Runner`` 运行器使用哪一个运行器来执行作业。

下面这个例子中，只有运行器注册时定义了 ``ruby`` 和 ``postgres`` 两个标签的运行器才能执行作业::

    job:
      tags:
        - ruby
        - postgres

而我们的 ``bluelog`` 项目中，所有的作业都是使用的是标签为 ``bluelog`` 的运行器::

    find Bugs:
      stage: code_check
      only:
        - triggers
      script:
        - echo "Use Flake8 to check python code"
        - pip install flake8
        - flake8 --version
        # - flake8 .
      tags:
        - bluelog

运行器标签可用于定义不同平台上运行的作业，如 ``Mac OS X Runner`` 使用 ``osx`` 标签， ``Windows Runner`` 使用 ``windows`` 标签，而 ``Linux Runner`` 使用 ``linux`` 标签:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 5,13,21
    
    windows job:
      stage:
        - build
      tags:
        - windows
      script:
        - echo Hello, %USERNAME%!
    
    osx job:
      stage:
        - build
      tags:
        - osx
      script:
        - echo "Hello, $USER!"
    
    linux job:
      stage:
        - build
      tags:
        - linux
      script:
        - echo "Hello, $USER!"


``allow_failure``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``allow_failure`` 可以用于当你想设置一个作业失败的之后并不影响后续的CI组件的时候。失败的作业不会影响到commit提交状态。
- 如果允许失败的作业失败了，则相应的作业会显示一个黄色的警告，但对流水线成功与否不产生影响。

下面的这个例子中，job1和job2将会并列进行，如果job1失败了，它也不会影响进行中的下一个阶段，因为这里有设置了 ``allow_failure: true`` :

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 5

    job1:
      stage: test
      script:
      - execute_script_that_will_fail
      allow_failure: true
    
    job2:
      stage: test
      script:
      - execute_script_that_will_succeed
    
    job3:
      stage: deploy
      script:
      - deploy_to_staging

但是如果上面的job2执行失败，那么job3则会受到影响而不会执行。

``when``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``when`` 关键字用于实现在作业失败时或发生故障时运行的作业 (when is used to implement jobs that are run in case of failure or despite the failure.)。

``when`` 可以设置以下值：

- ``on_success`` ：只有前面的阶段的所有作业都成功时才执行，这是默认值。
- ``on_failure`` ：当前面阶段的作业至少有一个失败时才执行。
- ``always`` : 无论前面的作业是否成功，一直执行本作业。
- ``manual`` ：手动执行作业，作业不会自动执行，需要人工手动点击启动作业。
- ``delayed`` : 延迟执行作业，配合 ``start_in`` 关键字一起作用， ``start_in`` 设置的值必须小于或等于1小时，``start_in`` 设置的值示例： ``10 seconds`` 、 ``30 minutes`` 、 ``1 hour`` ，前面的作业结束时计时器马上开始计时。

示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 17,28,34
   
    stages:
      - build
      - cleanup_build
      - test
      - deploy
      - cleanup
    
    build_job:
      stage: build
      script:
        - make build
    
    cleanup_build_job:
      stage: cleanup_build
      script:
        - cleanup build when failed
      when: on_failure
    
    test_job:
      stage: test
      script:
        - make test
    
    deploy_job:
      stage: deploy
      script:
        - make deploy
      when: manual
    
    cleanup_job:
      stage: cleanup
      script:
        - cleanup after jobs
      when: always
    

说明：

- 只有在 ``build_job`` 构建作业失败时，才会执行 ``cleanup_build_job`` 作业。
- 需要在GitLab Web界面手动点击，才能执行 ``deploy_job`` 部署作业。
- 无论之前的作业是否成功还是失败，``cleanup_job`` 清理作业一直会执行。

延时处理的示例:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4,5
    
    timed rollout 10%:
      stage: deploy
      script: echo 'Rolling out 10% ...'
      when: delayed
      start_in: 30 minutes

上面的例子创建了一个"timed rollout 10%"作业，会在上一个作业完成后30分钟后才开始执行。

如果你点击"Unschedule"按钮可以取消一个激活的计时器，你也可以点击"Play"按钮，立即执行延时作业。

``environment``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``environment`` 用于定义作业部署到特殊的环境中。如果指定了 ``environment`` ，并且在 ``运维`` --> ``环境`` 界面的环境列表中没有该名称下的环境，则会自动创建新环境。

在最简单的格式中，环境关键字可以定义为：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4,5

    deploy to production:
      stage: deploy
      script: git push production HEAD:master
      environment:
        name: production

上面的示例中，"deploy to production"作业将会部署代码到"production"生产环境中去。

``environment:name``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 在GitLab 8.11之前，环境的名称可以使用 ``environment: production`` 方式定义，现在推荐使用 ``name`` 关键字来定义环境的名称，就像上面的示例一样。
- ``name`` 关键字的参数可以使用任何定义的CI变量，包括预定义的变量、安全变量、以及 ``.gitlab-ci.yml`` 配置文件中定义的变量，但不能使用 ``script`` 中定义的变量(因为这里面的变量是局部变量)。
- ``environment`` 环境的名称可以包含：英文字母(letters)、数字(digits)、空格(space)、_、/、$、{、}等。常用的名称有： ``qa``、 ``staging`` 、``production`` 。

.. Attention:: 

    - 软件应用开发的经典模型有这样几个环境：开发环境(development)、集成环境(integration)、测试环境(testing)、QA验证，模拟环境(staging)、生产环境(production)。
    - 通常一个web项目都需要一个staging环境，一来给客户做演示，二来可以作为production server的一个"预演"，正式发布新功能前能及早发现问题（特别是gem的依赖问题，环境问题等）。
    - staging server可以理解为production环境的镜像，QA在staging server上对新版本做最后一轮verification, 通过后才能deploy到产品线上。staging环境 尽最大可能来模拟产品线上的环境(硬件，网络拓扑结构，数据库数据)。

``environment:url``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``environment:url`` 是可选的，用于设置环境的URL地址的按钮，通过点击按钮可以访问环境相应的URL地址。
- 下面这个例子中，如果作业都成功完成，那么会在 ``评审请求`` 和 ``环境部署`` 页面创建一个Button按钮，你点击 ``打开运行中的环境`` 按钮就可以访问环境对应的URL地址 ``https://prod.example.com`` 。

示例:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-6

    deploy to production:
      stage: deploy
      script: git push production HEAD:master
      environment:
        name: production
        url: https://prod.example.com

``environment:on_stop`` 与 ``environment:action``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``environment:on_stop`` 与 ``environment:action`` 配合使用。
- 可以通过 ``environment:on_stop`` 关键字定义一个关闭(停止)环境的作业。
- ``action`` 关键字在关闭环境的作业中定义。

下面的例子联合使用 ``environment:on_stop`` 与 ``environment:action`` 来关闭环境：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-6,11-14

    review_app:
      stage: deploy
      script: make deploy-app
      environment:
        name: review
        on_stop: stop_review_app
    
    stop_review_app:
      stage: deploy
      script: make delete-app
      when: manual
      environment:
        name: review
        action: stop

在上面的示例中，设置 ``review_app`` 作业用于部署代码到 ``review`` 评审环境中，同时在 ``on_stop`` 中指定了 ``stop_review_app`` 作业。一旦 ``review_app`` 作业成功执行，就会触发 ``when`` 关键字定义的 ``stop_review_app`` 作业。通过设置为 ``manual`` 手动，需要在GitLab WEB界面点击来允许 ``manual action`` 。

``stop_review_app`` 作业必须配合定义以下关键字：

- ``when`` ： 何时执行删除或停止环境作业
- ``environment:name`` ： 环境名称需要与上面的 ``review_app`` 作业保持一致，即 ``review`` 评审环境
- ``environment:action`` ：执行何种执行，``stop`` 停止环境
- ``stage`` ：与 ``review_app`` 作业的阶段保持一致，都是 ``deploy``

运行完成后，在 ``stop_review_app`` 作业界面需要手动点击 ``停止当前环境`` 才能启动 ``stop_review_app`` 作业的执行。 ``stop_review_app`` 作业执行完成后，会停止  ``review`` 评审环境，在 ``环境`` --> ``已停止`` 列表中可以看到 ``review`` 评审环境。


Dynamic environments 动态环境
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

正如前面讲解的，可以在环境的名称中使用变量，在 ``environment:name`` 和 ``environment:url`` 中使用变量，则可以达到动态环境的目的，动态环境需要底层应用的支持。

我们不详细展开，下面是官方的一个示例的改版:

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-6
    
    deploy as review app:
      stage: deploy
      script: make deploy
      environment:
        name: review/${CI_COMMIT_REF_NAME}
        url: https://${CI_ENVIRONMENT_SLUG}.example.com/

上面示例中的 ``${CI_COMMIT_REF_NAME}`` ``${CI_ENVIRONMENT_SLUG}`` 就是两个变量。


``cache``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``GitLab Runner v0.7.0`` 引入 ``cache`` 缓存机制。
- ``cache`` 缓存机制，可以在全局设置或者每个作业中设置。
- 从 ``GitLab 9.0`` 开始， ``cache`` 缓存机制，可以在不同的的流水线或作业之间共享数据。
- 从 ``GitLab 9.2`` 开始， 在 ``artifacts`` 工件之前恢复缓存。
- ``cache`` 缓存机制用于指定一系列的文件或文件夹在不同的流水线或作业之间共享数据，仅能使用项目工作空间( ``project workspace`` )中的路径作为缓存的路径。
- ``如果 ``cache`` 配置的路径是作业工作空间外部，则说明配置是全局的缓存，所有作业共享。
- 访问 `Cache dependencies in GitLab CI/CD <https://docs.gitlab.com/ce/ci/caching/index.html>`_ 文档来获取缓存是如何工作的以及好的实践实例的例子。
- ``cache`` 缓存机制的其他介绍请参考 https://docs.gitlab.com/ce/ci/yaml/README.html#cache 。


``artifacts``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``artifacts`` 用于指定在作业成功、失败、或者一直等状态下时，一系列的文件或文件夹附加到作业中。``artifacts`` 可以称为 ``工件``或者 ``归档文件`` 。
- 作业完成后，工件被发送到GitLab，可以在GitLab Web界面下载。
- 默认情况下，只有成功的作业才会生成工件。
- 并不是所有的 ``executor`` 执行器都支持工件。
- 工件的详细介绍可参考 `Introduction to job artifacts <https://docs.gitlab.com/ce/user/project/pipelines/job_artifacts.html>`_

``artifacts:paths``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``artifacts:paths`` 用于指定哪些文件或文件夹会被打包成工件，仅仅项目工作空间( ``project workspace`` )的路径可以使用。
- 要在不同作业间传递工作，请参数 `dependencies <https://docs.gitlab.com/ce/ci/yaml/README.html#dependencies>`_

下面示例，将目录 ``binaries/`` 和文件 ``.config`` 打包成工件：

.. code-block:: yaml
    :linenos:
    
    artifacts:
      paths:
        - binaries/
        - .config

要禁用工件传递，请使用空依赖关系定义作业：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4
    
    job:
      stage: build
      script: make build
      dependencies: []

你可以仅为打标记的release发布版本创建工作，这样可以避免临时构建产生大量的存储需求：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-5, 10-14
    
    default-job:
      script:
        - mvn test -U
      except:
        - tags
    
    release-job:
      script:
        - mvn package -U
      artifacts:
        paths:
          - target/*.war
      only:
        - tags

上面的示例中，``default-job`` 作业不会在打标记的release发布版本中执行，而 ``release-job`` 只会在打标记的release发布版本执行，并且将 ``target/*.war`` 打包成工件以供下载。


``artifacts:name``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 工件的默认名称是 ``artifacts`` ，当下载时名称是 ``artifacts.zip`` 。
- 通过 ``artifacts:name`` 关键字可以自定义工件的归档名称，这样你可以为每个工件设置独一无二的名称，归档名称可以使用预定义的变量。
- 如果分支名称中包含斜杠(比如 ``feature/my-feature`` )，推荐使用 ``$CI_COMMIT_REF_SLUG`` 代替 ``$CI_COMMIT_REF_NAME`` 作为工件名称。


使用作业名称使用工件名称：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "$CI_JOB_NAME"
        paths:
          - binaries/


使用当前分支或tag版本标签名作为工件名称：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "$CI_COMMIT_REF_NAME"
        paths:
          - binaries/


同时使用当前作业名称以及当前分支或tag版本标签名作为工件名称：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME"
        paths:
          - binaries/


同时使用当前作业阶段名称以及当前分支名称作为工件名称：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "$CI_JOB_STAGE-$CI_COMMIT_REF_NAME"
        paths:
          - binaries/

如果你使用的 **Windows系统的Batch批处理脚本** ，则需要把 ``$`` 替换成 ``%``：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "%CI_JOB_STAGE%-%CI_COMMIT_REF_NAME%"
        paths:
          - binaries/

如果你使用的 **Windows系统的PowerShell脚本** ，则需要把 ``$`` 替换成 ``$env:``：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    job:
      artifacts:
        name: "$env:CI_JOB_STAGE-$env:CI_COMMIT_REF_NAME"
        paths:
          - binaries/

``artifacts:untracked``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``artifacts:untracked`` 用于将git未加入版本库的文件作为工件文件。
- ``artifacts:untracked`` 将会忽略配置文件 ``.gitignore``。

将所有的未跟踪文件打包成工件：

.. code-block:: yaml
    :linenos:
    
    artifacts:
      untracked: true

将所有的未跟踪文件以及目录 ``binaries`` 中文件打包成工件：

.. code-block:: yaml
    :linenos:
    
    artifacts:
      untracked: true
      paths:
        - binaries/


``artifacts:when``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``artifacts:when`` 用于在作业失败时或者忽略失败时上传工件。

``artifacts:when`` 可以设置以下值：

- ``on_success`` ，默认值，当作业成功上传工件。
- ``on_failure`` ，当作业失败上传工件。
- ``always`` ，无论作业是否成功一直上传工件。

当作业失败时，上传工件：

.. code-block:: yaml
    :linenos:
    
    job:
      artifacts:
        when: on_failure

``artifacts:expire_in``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``artifacts:expire_in`` 用于设置工件的过期时间。
- 你可以点击界面上的 ``Keep`` 保持按钮，永久保存工件。
- 工件到期后，默认情况下每小时删除一次工件(通过cron作业)，并且后续不能再访问该工件。
- 工件默认有效期是30天，可以通过 ``Admin area``  --> ``Settings`` --> ``Continuous Integration and Deployment`` 设置默认的有效性时间。
- 如果你不提供时间单位的话，工作有效性的时间是以秒为单位的时间，下面是一些示例：

    - ‘42'
    - ‘3 mins 4 sec'
    - ‘2 hrs 20 min'
    - ‘2h20min'
    - ‘6 mos 1 day'
    - ‘47 yrs 6 mos and 4d'
    - ‘3 weeks and 2 days'

下面示例中工件有效期为一周：

.. code-block:: yaml
    :linenos:
    
    job:
      artifacts:
        expire_in: 1 week

``artifacts:reports``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``artifacts:reports`` 用于收集测试报告(report)，并在GitLab UI界面中显示出来。
- 无论作业是否成功，都会收集测试报告。
- 可以通过设置工件的打包路径 ``artifacts:paths`` 添加测试的报告输出文件。
- ``artifacts:reports:junit`` 可以用来收集单元测试的报告，查看 `JUnit test reports <https://docs.gitlab.com/ce/ci/junit_test_reports.html>`_ 获取更详细的信息和示例。


下面是从Ruby的RSpec测试工具中收集JUnit XML文件的示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 5-8
    
    rspec:
      stage: test
      script:
      - bundle install
      - rspec --format RspecJunitFormatter --out rspec.xml
      artifacts:
        reports:
          junit: rspec.xml

.. Note::

    如果你的测试报告是多个XML文件，你可以在一个作业中指定多个单元测试报告，GitLab会自动将他们转换成一个文件，可以像下面这样表示报告的路径：
    
    - 文件匹配模式: ``junit: rspec-*.xml``
    - 文件列表: ``junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]``
    - 混合模式：``junit: [rspec.xml, test-results/TEST-*.xml]``

下面是Go语言收集JUnit XML文件的示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 5-9
    
    ## Use https://github.com/jstemmer/go-junit-report to generate a JUnit report with go
    golang:
      stage: test
      script:
      - go get -u github.com/jstemmer/go-junit-report
      - go test -v 2>&1 | go-junit-report > report.xml
      artifacts:
        reports:
          junit: report.xml

下面是C/C++语言使用GoogleTest进行单元测试，收集JUnit XML文件的示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-7

    cpp:
      stage: test
      script:
      - gtest.exe --gtest_output="xml:report.xml"
      artifacts:
        reports:
          junit: report.xml

.. Attention::

    如果GoogleTest需要运行在多个平台(如 ``x86`` 、 ``x64`` 、``arm`` )，需要为每种平台设置唯一的报告名称，最后将结果汇总起来。

还有一些其他的报告关键字，但社区版不可用，忽略不提。


``dependencies``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``dependencies`` 依赖关键字应该与 ``artifacts`` 工件关键字联合使用，允许你在不同作业间传递工件。
- 默认情况下，会传递所有本作业之前阶段的所有工件。
- 需要在作业上下文中定义 ``dependencies`` 依赖关键字，并指出所有需要使用的前序工件的作业名称列表。 **作业列表中不能使用该作业后的作业名称** 。
- 定义空的依赖项，将下不会下载任何工件。
- 使用依赖项不会考虑前面作业的运行状态。

示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-6,11-13,18-19,24-25
    
    build:osx:
      stage: build
      script: make build:osx
      artifacts:
        paths:
          - binaries/
    
    build:linux:
      stage: build
      script: make build:linux
      artifacts:
        paths:
          - binaries/
    
    test:osx:
      stage: test
      script: make test:osx
      dependencies:
        - build:osx
    
    test:linux:
      stage: test
      script: make test:linux
      dependencies:
        - build:linux
    
    deploy:
      stage: deploy
      script: make deploy

上面示例中， ``build:osx`` 和 ``build:linux`` 两个作业定义了工件， ``test:osx`` 作业执行时，将会下载并解压  ``build:osx`` 的工件内容。相应的， ``test:linux`` 也会获取 ``build:linux`` 的工件。 ``deploy`` 作业会下载全部工件。

.. Attention::

    如果作为依赖的作业的工件过期或者被删除，那么依赖这个作业的作业将会失败。

``coverage``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``coverage`` 可以从作业的输出log中提取代码覆盖率。
- 仅支持正则表达式方式获取覆盖率。
- 字符串的前后必须使用/包含来表明一个正确的正则表达式规则。特殊字符串需要转义。

下面是一个简单的例子：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2
    
    job1:
      coverage: '/Code coverage:\d+\.\d+%/'

如在作业日志中输出了"Code coverage:80.2%"，我们使用上面的正则表达式就可以获取到代码的覆盖率。然后在作业的右上角处就会显示 ``Coverage:80.2%`` 。


``retry``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``retry`` 重试关键字用于配置当作业失败时可以重新执行的次数。
- 当作业失败时，如果配置了 ``retry`` ，那么该作业就会重试，直到允许的最大次数。
- 如果 ``retry`` 设置值为2，如果第一次重试运行成功了，那么就不会进行第二次重试。
- ``retry`` 设置值只能是0、1、2三个整数。

下面是一个简单的例子：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3
    
    test:
      script: rspec
      retry: 2

- 为了更好的控制重试次数，``retry`` 可以设置以下两个关键字：

    - ``max`` : 最大重试次数
    - ``when`` : 何时重试

下面这个例子只有当运行器系统出现故障时才能最多重试两次：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3-5
    
    test:
      script: rspec
      retry:
        max: 2
        when: runner_system_failure

如果上面例子中出现的是其他故障，那么作业不会重试。

为了针对多种重试情形，我们可以使用矩阵形式罗列出错误情形，如下示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 3-7

    test:
      script: rspec
      retry:
        max: 2
        when:
          - runner_system_failure
          - stuck_or_timeout_failure

``when`` 可以是以下值：

- ``always`` : 一直重试，默认值。
- ``unknown_failure`` ：当错误未知时重试。
- ``script_failure`` ： 脚本错误时重试。
- ``api_failure`` ： API调用错误时重试。
- ``stuck_or_timeout_failure`` ： 作业卡信或超时错误时重试。
- ``runner_system_failure`` ： 运行器系统错误(如设置工作失败)时重试。
- ``missing_dependency_failure`` ： 依赖工件丢失错误时重试。
- ``runner_unsupported`` ： 运行器不支持错误时重试。

``trigger``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``trigger`` 关键字用于多项目流水线时，定义下游的流水线工程，由于社区版本不支持此功能，不详细介绍。具体可参考 `trigger <https://docs.gitlab.com/ce/ci/yaml/README.html#trigger-premium>`_


``include``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``include`` 包含关键字可以将其他yaml文件载入到当前的 ``.gitlab-ci.yml`` 配置文件中，详情请查看官网指导 `include <https://docs.gitlab.com/ce/ci/yaml/README.html#include>`_

``extends``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``extends`` 扩展用于定义当前作业从哪里继承。
- 它是使用YAML锚点的替代方案，更加灵活、可读性强。详情请查看官网指导 `extends <https://docs.gitlab.com/ce/ci/yaml/README.html#extends>`_


``pages``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- ``pages`` 是一项特殊工作，用于将静态内容上传到GitLab，可用于为您的网站提供服务。详情请查看官网指导 `GitLab Pages <https://docs.gitlab.com/ce/user/project/pages/index.html>`_


``variables``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- 在 ``.gitlab-ci.yml`` 配置文件中可以通过 ``variables`` 关键字配置全局变量或者作业级的局部变量。
- 当 ``variables`` 关键字使用在作业层级时，它会覆盖全局变量或预定义变量。
- 可以在 ``variables`` 关键字中定义非敏感性配置。
- 全局变量可以在各个作业中作业，而作业级别的局部变量只能在该作业中使用。
- 可以在GitLab WEB界面定义一些敏感性配置变量，或者可能变动的变量。
- 在 ``script`` 中使用 ``export`` 可以导出当前可用的变量信息。
- 作业内部修改全局变量只对当前作用生效，不会影响其他作业。
- 可以使用赋值语句对全局变量或局部变量进行重新赋值。


下面这个示例定义一个全局数据库的URL地址：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 1-2

    variables:
      DATABASE_URL: "postgres://postgres@postgres/my_database"

下面修改 ``bluelog`` 项目的配置文件为如下内容：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 4-11,21-25,49-51
   
    # This file is a template, and might need editing before it works on your project.
    # see https://docs.gitlab.com/ce/ci/yaml/README.html for all available options
    
    # 定义全局变量
    variables:
      # 数据库信息
      SQLALCHEMY_DATABASE_URI: 'mysql+pymysql://root:root@localhost:3306/bluelog?charset=utf8mb4'
      # 不发送警告通知
      SQLALCHEMY_TRACK_MODIFICATIONS: "False"
      # 显示执行SQL
      SQLALCHEMY_ECHO: "True"
      
    stages:
      - build
      - code_check
      - test
      - deploy
      
    build1:
      stage: build
      variables:
        # 数据库信息
        SQLALCHEMY_DATABASE_URI: 'mysql+pymysql://root:123456@localhost:3306/bluelog?charset=utf8mb4'
        # 不显示执行SQL
        SQLALCHEMY_ECHO: "False"
      script:
        - export
        - echo "Do your build here"
        - cloc --version
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      script:
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
        - SQLALCHEMY_ECHO="Nothing"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
      tags:
        - bluelog
        
    test1:
      stage: test
      variables:
        # CKEditor富文本设置
        CKEDITOR_SERVE_LOCAL: "True"
      script:
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
        - echo -e "CKEDITOR_SERVE_LOCAL:${CKEDITOR_SERVE_LOCAL}"
      tags:
        - bluelog
    
    test2:
      stage: test
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog
    
查看各阶段的输出内容。

.. image:: ./_static/images/gitlab_bluelog_variables_job_build1.png

可以看到 ``build1`` 作业中:

- ``SQLALCHEMY_DATABASE_URI`` 已经覆盖了全局定义的 ``SQLALCHEMY_DATABASE_URI`` ，看差异数据库URL中全局是"root:root"，而作业中是"root:123456"。
- 由于作业中并没有定义 ``SQLALCHEMY_TRACK_MODIFICATIONS`` 变量，所以使用的是全局的 ``SQLALCHEMY_TRACK_MODIFICATIONS`` 变量，输出结果是"False"。
- 作业中定义的 ``SQLALCHEMY_ECHO: "False"`` 将全局的 ``SQLALCHEMY_ECHO: "True"`` 覆盖，最后显示的是"False"。

再看 ``find Bugs`` 作业：

.. image:: ./_static/images/gitlab_bluelog_variables_job_find_Bugs.png

- 因为没有定义 ``variables`` 关键字，这个作用将使用全局变量。
- 39、40、41三行输出的结果都是全局变量定义的值。
- 42行的 ``SQLALCHEMY_ECHO="Nothing"`` 对 ``SQLALCHEMY_ECHO`` 全局变量进行的重新赋值，43行打印出了赋值后的新值是"Nothing"。
- 上面两个作业说明，作业内部修改全局变量只对当前作用生效，不会影响其他作业。
- 可以使用赋值语句对全局变量或局部变量进行重新赋值。

再看 ``test1`` 作业：

.. image:: ./_static/images/gitlab_bluelog_variables_job_test1.png

- 该作业定义 ``variables`` 关键字，增加了一个 ``CKEDITOR_SERVE_LOCAL`` 变量。
- 上一个作业的修改 ``SQLALCHEMY_ECHO="Nothing"`` 对本作业显示 ``SQLALCHEMY_ECHO`` 变量没有影响，仍然会显示全局变量定义的值"True"。再一次证明了作业内部修改全局变量只对当前作用生效，不会影响其他作业。


``variables`` 变量的优先级
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

``variables`` 变量的优先级参考 `Priority of environment variables <https://docs.gitlab.com/ce/ci/variables/README.html#priority-of-environment-variables>`_


原文::

    Variables of different types can take precedence over other variables, depending on where they are defined.
    
    The order of precedence for variables is (from highest to lowest):
    
        Trigger variables or scheduled pipeline variables.
        Project-level variables or protected variables.
        Group-level variables or protected variables.
        YAML-defined job-level variables.
        YAML-defined global variables.
        Deployment variables.
        Predefined environment variables.

翻译过来，是这样的::

    不同类型的变量可以优先于其他变量，具体取决于它们的定义位置。
    
    变量的优先顺序是（从最高到最低）：
    
         触发变量或预定的流水线变量。
         项目级别变量或受保护变量。
         组级别变量或受保护变量。
         YAML定义的作业级变量。
         YAML定义的全局变量。
         部署环境变量。
         预定义的环境变量。

变量中有一些关于git策略的特殊变量，如后续几个小节，当前仅列出，后续详细补充。

使用export导出的变量示例
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

export的导出示例::

    $ export
    declare -x CI="true"
    declare -x CI_API_V4_URL="http://192.168.56.14/api/v4"
    declare -x CI_BUILDS_DIR="/root/gitlab-runner/builds"
    declare -x CI_BUILD_BEFORE_SHA="84f1f0e417d7e340770a4bb05076bf74f3231991"
    declare -x CI_BUILD_ID="128"
    declare -x CI_BUILD_NAME="build1"
    declare -x CI_BUILD_REF="a6554ffa0d2ae67c675fe9768f702f0b1bb65f5a"
    declare -x CI_BUILD_REF_NAME="master"
    declare -x CI_BUILD_REF_SLUG="master"
    declare -x CI_BUILD_STAGE="build"
    declare -x CI_BUILD_TOKEN="[MASKED]"
    declare -x CI_COMMIT_BEFORE_SHA="84f1f0e417d7e340770a4bb05076bf74f3231991"
    declare -x CI_COMMIT_DESCRIPTION=""
    declare -x CI_COMMIT_MESSAGE="全局变量与局部变量的使用
    "
    declare -x CI_COMMIT_REF_NAME="master"
    declare -x CI_COMMIT_REF_SLUG="master"
    declare -x CI_COMMIT_SHA="a6554ffa0d2ae67c675fe9768f702f0b1bb65f5a"
    declare -x CI_COMMIT_SHORT_SHA="a6554ffa"
    declare -x CI_COMMIT_TITLE="全局变量与局部变量的使用"
    declare -x CI_CONCURRENT_ID="0"
    declare -x CI_CONCURRENT_PROJECT_ID="0"
    declare -x CI_CONFIG_PATH=".gitlab-ci.yml"
    declare -x CI_JOB_ID="128"
    declare -x CI_JOB_NAME="build1"
    declare -x CI_JOB_STAGE="build"
    declare -x CI_JOB_TOKEN="[MASKED]"
    declare -x CI_JOB_URL="http://192.168.56.14/higit/bluelog/-/jobs/128"
    declare -x CI_NODE_TOTAL="1"
    declare -x CI_PAGES_DOMAIN="example.com"
    declare -x CI_PAGES_URL="http://higit.example.com/bluelog"
    declare -x CI_PIPELINE_ID="45"
    declare -x CI_PIPELINE_IID="48"
    declare -x CI_PIPELINE_SOURCE="push"
    declare -x CI_PIPELINE_URL="http://192.168.56.14/higit/bluelog/pipelines/45"
    declare -x CI_PROJECT_DIR="/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog"
    declare -x CI_PROJECT_ID="2"
    declare -x CI_PROJECT_NAME="bluelog"
    declare -x CI_PROJECT_NAMESPACE="higit"
    declare -x CI_PROJECT_PATH="higit/bluelog"
    declare -x CI_PROJECT_PATH_SLUG="higit-bluelog"
    declare -x CI_PROJECT_URL="http://192.168.56.14/higit/bluelog"
    declare -x CI_PROJECT_VISIBILITY="private"
    declare -x CI_REGISTRY_PASSWORD="[MASKED]"
    declare -x CI_REGISTRY_USER="gitlab-ci-token"
    declare -x CI_REPOSITORY_URL="http://gitlab-ci-token:[MASKED]@192.168.56.14/higit/bluelog.git"
    declare -x CI_RUNNER_DESCRIPTION="bluelog runner"
    declare -x CI_RUNNER_EXECUTABLE_ARCH="linux/amd64"
    declare -x CI_RUNNER_ID="1"
    declare -x CI_RUNNER_REVISION="3001a600"
    declare -x CI_RUNNER_TAGS="bluelog"
    declare -x CI_RUNNER_VERSION="11.10.0"
    declare -x CI_SERVER="yes"
    declare -x CI_SERVER_NAME="GitLab"
    declare -x CI_SERVER_REVISION="8a802d1c6b7"
    declare -x CI_SERVER_VERSION="11.10.6"
    declare -x CI_SERVER_VERSION_MAJOR="11"
    declare -x CI_SERVER_VERSION_MINOR="10"
    declare -x CI_SERVER_VERSION_PATCH="6"
    declare -x CI_SHARED_ENVIRONMENT="true"
    declare -x CONFIG_FILE="/etc/gitlab-runner/config.toml"
    declare -x FF_K8S_USE_ENTRYPOINT_OVER_COMMAND="true"
    declare -x FF_USE_LEGACY_GIT_CLEAN_STRATEGY="false"
    declare -x GITLAB_CI="true"
    declare -x GITLAB_FEATURES=""
    declare -x GITLAB_USER_EMAIL="mzh.whut@gmail.com"
    declare -x GITLAB_USER_ID="2"
    declare -x GITLAB_USER_LOGIN="meizhaohui"
    declare -x GITLAB_USER_NAME="梅朝辉"
    declare -x HISTCONTROL="ignoredups"
    declare -x HISTSIZE="1000"
    declare -x HOME="/root"
    declare -x HOSTNAME="server.hopewait"
    declare -x LANG="en_US.utf8"
    declare -x LC_ALL="en_US.utf8"
    declare -x LESSOPEN="||/usr/bin/lesspipe.sh %s"
    declare -x LOGNAME="root"
    declare -x LS_COLORS="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.axa=01;36:*.oga=01;36:*.spx=01;36:*.xspf=01;36:"
    declare -x MAIL="/var/spool/mail/root"
    declare -x OLDPWD="/root/gitlab-runner"
    declare -x PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin"
    declare -x PIPENV_PYPI_MIRROR="https://mirrors.aliyun.com/pypi/simple"
    declare -x PIPENV_VENV_IN_PROJECT="1"
    declare -x PWD="/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog"
    declare -x SHELL="/bin/bash"
    declare -x SHLVL="3"
    declare -x SQLALCHEMY_DATABASE_URI="mysql+pymysql://root:123456@localhost:3306/bluelog?charset=utf8mb4"
    declare -x SQLALCHEMY_ECHO="False"
    declare -x SQLALCHEMY_TRACK_MODIFICATIONS="False"
    declare -x SSH_CLIENT="192.168.56.1 51472 22"
    declare -x SSH_CONNECTION="192.168.56.1 51472 192.168.56.14 22"
    declare -x SSH_TTY="/dev/pts/0"
    declare -x TERM="linux"
    declare -x USER="root"
    declare -x XDG_RUNTIME_DIR="/run/user/0"
    declare -x XDG_SESSION_ID="41"

.. Attention::

    - 不要将敏感信息，如用户密码、Token等信息放在 ``.gitlab-ci.yml`` 配置文件中定义变量。
    - 敏感信息可以WEB配置界面添加变量，并将变量设置为 ``Protected受保护`` 或者 ``Masked`` ，设置为 ``Masked`` 的变量不会直接显示在作业日志信息中。

关闭全局层级定义的变量
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 如果你要在作业层级关闭全局层级定义的变量，可以给 ``variables`` 关键字定义一个空的 ``hash`` 。

如下示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2
    
    job_name:
      variables: {}

变量定义时使用其他变量
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 可以在变量定义时，使用其他的变量，需要使用 ``$$`` 进行转义。

看下面的示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2
    
    variables:
      LS_CMD: 'ls $FLAGS $$TMP_DIR'
      FLAGS: '-al'
    script:
      - 'eval $LS_CMD'  # will execute 'ls -al $TMP_DIR'


克隆策略Git strategy ``GIT_STRATEGY``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 你可以通过设置 ``GIT_STRATEGY`` 变量来指定GitLab Runner运行作业时使用什么样的方式来获取最新的代码，可以在全局级或作业级进行设置。
- ``GIT_STRATEGY`` 变量可以设置为 ``fetch`` 、``clone`` 、``none`` 。
- ``clone`` 是最慢的方式，这种方式会从头开始克隆仓库。
- ``fetch`` 相对来说更快一点，如果本地项目空间中存在远程仓库的克隆，只用从远程获取最新到本地，而不用从头开始克隆整个仓库(如果本地项目空间不存在远程仓库的克隆的话，则此时等同于clone，从头开始克隆远程仓库)。
- ``none`` 也是利用本地项目空间中的文件，但不会从远程获取到最新的修改数据，本地数据不是最新的。

下面我们通过修改 ``.gitlab-ci.yml`` 配置文件来查看这个现象：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 16,23,26,33,36,43,45
        
    # This file is a template, and might need editing before it works on your project.
    # see https://docs.gitlab.com/ce/ci/yaml/README.html for all available options
    
    stages:
      - build
      - code_check
      - test
      - deploy
      
    build1:
      stage: build
      script:
        - pwd
        - export
        - echo "Do your build here"
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      variables:
        GIT_STRATEGY: "fetch"
      script:
        - pwd
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
      tags:
        - bluelog
        
    test1:
      stage: test
      variables:
        GIT_STRATEGY: "clone"
      script:
        - pwd
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
      tags:
        - bluelog
    
    test2:
      stage: test
      variables:
        GIT_STRATEGY: "none"
      script:
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog

提交后，流水线触发了：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_pipeline.png

我们检查一下每个作业的log日志信息：

先看build1作业：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_pipeline_build1_job_top.png
.. image:: ./_static/images/gitlab_bluelog_git_strategy_pipeline_build1_job_bottom.png

可以看到默认情况下，会使用 ``git fetch`` 方式来获取最新的修改，并且 ``echo "GIT_STRATEGY:${GIT_STRATEGY}"`` 打印 ``${GIT_STRATEGY}`` 变量为空，也就是默认情况下GitLab并不会设置 ``GIT_STRATEGY`` 变量。

再看一下find Bugs作业：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_find_Bugs.png

此处也是直接使用现有项目空间里面的本地仓库，使用 ``git fetch`` 方式来获取最新的修改，由于在作业级中设置了 ``GIT_STRATEGY`` 变量，最后打印出打印 ``${GIT_STRATEGY}`` 变量的值为 ``fetch`` 。

再看一下test1作业：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_test1.png

因为设置了 ``GIT_STRATEGY: "clone"`` ，这个时候GitLab Runner会从头开始克隆远程仓库，最后打印出打印 ``${GIT_STRATEGY}`` 变量的值为 ``clone`` 。

再看一下test2作业：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_test2.png

因为设置了 ``GIT_STRATEGY: "none"`` ，这个时候GitLab Runner什么也不做，不会获取最新的修改，最后打印出打印 ``${GIT_STRATEGY}`` 变量的值为 ``none`` 。

我们再修改一下配置文件为下面的内容：

.. code-block:: yaml
    :linenos:
    
    # This file is a template, and might need editing before it works on your project.
    # see https://docs.gitlab.com/ce/ci/yaml/README.html for all available options
    
    stages:
      - build
      - code_check
      - test
      - deploy
      
    build1:
      stage: build
      script:
        - pwd
        - export
        - echo "Do your build here"
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
        - du -sh
        - ls -lah README.md
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      variables:
        GIT_STRATEGY: "fetch"
      script:
        - pwd
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
        - du -sh
        - ls -lah README.md
      when: manual
      tags:
        - bluelog
        
    test1:
      stage: test
      variables:
        GIT_STRATEGY: "clone"
      script:
        - pwd
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
        - du -sh
        - ls -lah README.md
      when: manual
      tags:
        - bluelog
    
    test2:
      stage: test
      variables:
        GIT_STRATEGY: "none"
      script:
        - echo "GIT_STRATEGY:${GIT_STRATEGY}"
        - du -sh
        - ls -lah README.md
      when: manual
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      script:
        - echo "Do your deploy here"
        - du -sh
        - ls -lah README.md
      when: manual
      tags:
        - bluelog
    
提交后，流水线触发了，但有build1作业后面的作业需要手动执行：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline.png

我们检查build1作业：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_build1_job_bottom.png

可以获取到整个仓库的大小，也可以读取到仓库中"README.md"文件。

假设我们此时在服务器端将 ``/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog`` 和 ``/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog.tmp`` 目录删除，并触发find Bugs作业运行：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_delete_project_workspace.png

因为设置了 ``GIT_STRATEGY: "fetch"`` ，但因为我把项目空间里面的本地仓库内容都删除了，这个时候GitLab Runner发现本地并没有远程仓库的文件，只能从头开始克隆远程仓库，最后打印出打印 ``${GIT_STRATEGY}`` 变量的值为 ``fetch`` 。

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_find_bugs_job.png

再触发test1作业运行，还是从头开始下载远程仓库：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_test1_job.png

关键一步，我们再次删除工作空间中的 ``/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog`` 和 ``/root/gitlab-runner/builds/1aXYZ5H9/0/higit/bluelog.tmp`` 目录：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_delete_project_workspace_again.png

再触发test2作业运行：

.. image:: ./_static/images/gitlab_bluelog_git_strategy_manual_pipeline_test2_job_failed.png

此时发现，GitLab Runner仅仅创建了一个目录 ``bluelog`` ，但不从远程获取数据，这个时候我们获取仓库目录数据大小为0，也查看不到README.md文件的详情，由于没有README.md文件，执行命令就报错。

- 可以看出设置 ``GIT_STRATEGY: "none"`` 可能会遇到意想不到的情况！
- 为了加快流水线工程的执行，建议使用 ``fetch`` 模式。
- 流水线的Git策略默认是 ``git fetch`` 模式。

流水线的默认Git策略，可以在项目的流水线通用设置中查看：

.. image:: ./_static/images/gitlab_bluelog_default_git_strategy.png


子模块策略Git submodule strategy ``GIT_SUBMODULE_STRATEGY``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``GIT_SUBMODULE_STRATEGY`` 类似于 ``GIT_STRATEGY`` ，当你的项目需要包含别的项目代码时，可以将别的项目作为你的项目的子模块，这个时候就可以使用 ``GIT_SUBMODULE_STRATEGY`` 。
- ``GIT_SUBMODULE_STRATEGY`` 默认取值 ``none`` ，即拉取代码时，子模块不会被引入。
- ``GIT_SUBMODULE_STRATEGY`` 可取值 ``normal`` ，意味着在只有顶级子模块会被引入。
- ``GIT_SUBMODULE_STRATEGY`` 可取值 ``recursive`` ，递归的意思，意味着所有级子模块会被引入。

子模块需要配置在 ``.gitmodules`` 配置文件中，下面是两个示例：

场景：

- 你的项目地址： ``https://gitlab.com/secret-group/my-project`` ，你可以使用 ``git clone git@gitlab.com:secret-group/my-project.git`` 检出代码。

- 你的项目依赖 ``https://gitlab.com/group/project`` ，你可以将这个模块作为项目的子模块。

子模块与本项目在同一个服务上，可以使用相对引用：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2-3
    
    [submodule "project"]
      path = project
      url = ../../group/project.git

子模块与本项目不在同一个服务上，使用相对绝对URL：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2-3
    
    [submodule "project-x"]
      path = project-x
      url = https://gitserver.com/group/project-x.git

详细可参考 `Using Git submodules with GitLab CI <https://docs.gitlab.com/ce/ci/git_submodules.html>`_

检出分支设置Git checkout ``GIT_CHECKOUT``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 当 ``GIT_STRATEGY`` 设置为 ``fetch`` 或者 ``clone`` 时，可以通过 ``GIT_CHECKOUT`` 变量设置是否需要做 ``git checkout`` 操作，如果未指定该参数，默认值为 ``true`` ，即需要做 ``git checkout`` 操作。
- 可以在全局级或作业级进行设置。
- 如果 ``GIT_CHECKOUT`` 变量设置为 ``true`` ，GitLab Runner都会将本地工作副本检出并切换到当前流水线相关的修订版本分支上。
- 如果 ``GIT_CHECKOUT`` 变量设置为 ``false`` ，那么运行器操作如下：

    - ``fetch`` 操作时，更新仓库并在当前版本上保留工作副本。
    - ``clone`` 操作时，克隆仓库并在默认分支中保留工作副本。
    
下面示例不进行自动切换到分支：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2-3
    
    variables:
      GIT_STRATEGY: clone
      GIT_CHECKOUT: "false"
    script:
      - git checkout -B master origin/master
      - git merge $CI_COMMIT_SHA


清理工作Git clean flags ``GIT_CLEAN_FLAGS``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 可以使用 ``GIT_CLEAN_FLAGS`` 变量来控制在检出源码后 ``git clean`` 的默认行为，可以在全局级或作业级进行设置。
- ``GIT_CLEAN_FLAGS`` 变量接受  ``git clean`` 命令的所有参数。
- 如果指定了 ``GIT_CHECKOUT: "false"`` ，那么 ``git clean`` 将不可用。
- ``git-clean`` : Remove untracked files from the working tree，即删除未跟踪的文件。
- ``git clean`` 命令用来从你的工作目录中删除所有没有tracked过的文件， ``git reset --hard`` 用于删除跟踪文件的修改记录。
- ``git clean -n`` 命令列出将被删除的文件。
- ``git clean -f`` 命令删除当前目录下所有没有跟踪过的文件。
- ``git clean -d`` 命令删除当前目录下所有没有跟踪过的目录。
- ``git clean -e <pattern>`` 命令排除( ``--exclude=<pattern>`` ) 某文件或目录，即不删除模式匹配的文件。
- ``git clean -ffxd`` 命令删除当前目录(包括由其他git仓库管理的子目录)下所有没有跟踪过的目录和文件。
- ``GIT_CLEAN_FLAGS`` 变量未指定时， ``git clean`` 命令的参数是 ``-ffxd`` 。
- ``GIT_CLEAN_FLAGS`` 变量指定为 ``none`` 时， ``git clean`` 命令不会执行。

下面示例用于删除未被跟踪文件和目录，但排除cache目录及目录下的文件：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2

    variables:
      GIT_CLEAN_FLAGS: -ffdx -e cache/
    script:
      - ls -al cache/


作业重试次数 Job stages attempts
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 您可以设置正在运行的作业尝试执行以下每个阶段的尝试次数。可以在全局级或作业级进行设置。
- 涉及三个变量 ``GET_SOURCES_ATTEMPTS`` 、 ``ARTIFACT_DOWNLOAD_ATTEMPTS`` 、 ``RESTORE_CACHE_ATTEMPTS`` 。
- ``GET_SOURCES_ATTEMPTS`` 变量设置获取源码的尝试次数。
- ``ARTIFACT_DOWNLOAD_ATTEMPTS`` 变量设置下载归档文件的尝试次数。
- ``RESTORE_CACHE_ATTEMPTS`` 变量设置重建缓存的尝试次数。
- 默认是1次尝试。

示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2
    
    variables:
      GET_SOURCES_ATTEMPTS: 3




浅克隆 Shallow cloning ``GIT_DEPTH``
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- GitLab 8.9中引入了试验性的特征 ``浅克隆`` ，在将来的版本中有可能改变或者完全移除。
- 可以通过设置  ``GIT_DEPTH`` 克隆深度，不详细介绍，可参考 `Shallow cloning <https://docs.gitlab.com/ce/ci/yaml/README.html#shallow-cloning>`_


废弃的关键字 ``types`` 和 ``type``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- 关键字 ``types`` 和 ``type`` 已经废弃。
- 使用 ``stages`` 阶段定义关键字代替 ``types`` 。
- 使用 ``stage`` 作业所处阶段关键字代替 ``type`` 。


使用 ``GIT_CLONE_PATH`` 自定义构建目录
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- 在默认情况下，自定义构建目录只有在GitLab Runner运行器配置文件中定义了 ``custom_build_dir`` 为 ``enabled`` 开启状态时才可使用。
- ``docker`` 、 ``kubernetes`` 运行器默认开启了此功能，而其他运行器默认不会开启此功能。
- 默认情况下，GitLab Runner运行器将仓库克隆到 ``$CI_BUILDS_DIR`` 目录下的一个名称唯一的子目录中，但有时候你的项目可能需要指定一个特殊的路径用来保存下载的仓库，这个时候就可以使用 ``GIT_CLONE_PATH`` 变量来指定克隆文件的存放目录。
- ``GIT_CLONE_PATH``  必须是 ``$CI_BUILDS_DIR`` 的子目录， ``$CI_BUILDS_DIR`` 目录各个运行器可能不同。

我们尝试在我们的SHELL运行器上去设置 ``GIT_CLONE_PATH`` 目录。

下面是官方给出的一个示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2
    
    variables:
      GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name
    
    test:
      script:
        - pwd

我们仿照这个示例修改 ``.gitlab-ci.yml`` 配置文件，并进行提交，修改后的内容如下：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 13,29
    
    # This file is a template, and might need editing before it works on your project.
    # see https://docs.gitlab.com/ce/ci/yaml/README.html for all available options
    
    # 定义全局变量
    variables:
      # 数据库信息
      SQLALCHEMY_DATABASE_URI: 'mysql+pymysql://root:root@localhost:3306/bluelog?charset=utf8mb4'
      # 不发送警告通知
      SQLALCHEMY_TRACK_MODIFICATIONS: "False"
      # 显示执行SQL
      SQLALCHEMY_ECHO: "True"
      # 设置全局构建目录
      GIT_CLONE_PATH: $CI_BUILDS_DIR/global_folder
      
    stages:
      - build
      - code_check
      - test
      - deploy
      
    build1:
      stage: build
      variables:
        # 数据库信息
        SQLALCHEMY_DATABASE_URI: 'mysql+pymysql://root:123456@localhost:3306/bluelog?charset=utf8mb4'
        # 不显示执行SQL
        SQLALCHEMY_ECHO: "False"
        # 设置全局构建目录
        GIT_CLONE_PATH: $CI_BUILDS_DIR/sub_folder
      script:
        - pwd
        - export
        - echo "Do your build here"
        - cloc --version
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
      tags:
        - bluelog
    
    find Bugs:
      stage: code_check
      script:
        - pwd
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
        - SQLALCHEMY_ECHO="Nothing"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
      tags:
        - bluelog
        
    test1:
      stage: test
      variables:
        # CKEditor富文本设置
        CKEDITOR_SERVE_LOCAL: "True"
      script:
        - pwd
        - echo -e "SQLALCHEMY_DATABASE_URI:${SQLALCHEMY_DATABASE_URI}"
        - echo -e "SQLALCHEMY_TRACK_MODIFICATIONS:${SQLALCHEMY_TRACK_MODIFICATIONS}"
        - echo -e "SQLALCHEMY_ECHO:${SQLALCHEMY_ECHO}"
        - echo -e "CKEDITOR_SERVE_LOCAL:${CKEDITOR_SERVE_LOCAL}"
      tags:
        - bluelog
    
    test2:
      stage: test
      script:
        - echo "Do another parallel test here"
        - echo "For example run a lint test"
      tags:
        - bluelog
        
    deploy1:
      stage: deploy
      script:
        - echo "Do your deploy here"
      tags:
        - bluelog
    
提交修改构建目录后，流水线执行失败：

.. image:: ./_static/images/gitlab_bluelog_custom_build_directory_failure.png

查看作业详情：

.. image:: ./_static/images/gitlab_bluelog_custom_build_directory_failure_job_details.png

可以看到提示 ``ERROR: Job failed: setting GIT_CLONE_PATH is not allowed, enable `custom_build_dir` feature``

意思是说不允许设置 ``GIT_CLONE_PATH`` 变量，需要设置 ``custom_build_dir`` 属性。

我们参考 `The [runners.custom_build_dir] section <https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section>`_ 来设置 ``custom_build_dir`` 属性。

我们查看一下GitLab Runner的配置文件内容::

    [root@server ~]# cat /etc/gitlab-runner/config.toml 
    concurrent = 1
    check_interval = 0
    
    [session_server]
      session_timeout = 1800
    
    [[runners]]
      name = "bluelog runner"
      url = "http://192.168.56.14/"
      token = "1aXYZ5H9n2y8oauWkz7D"
      executor = "shell"
      [runners.custom_build_dir]
      [runners.cache]
        [runners.cache.s3]
        [runners.cache.gcs]

我们参考示例::

    [runners.custom_build_dir]
      enabled = true

开启 ``custom_build_dir`` 属性，修改后配置文件内容如下::

    [root@server ~]# cat /etc/gitlab-runner/config.toml   
    concurrent = 1
    check_interval = 0
    
    [session_server]
      session_timeout = 1800
    
    [[runners]]
      name = "bluelog runner"
      url = "http://192.168.56.14/"
      token = "1aXYZ5H9n2y8oauWkz7D"
      executor = "shell"
      [runners.custom_build_dir]
        enabled = true
      [runners.cache]
        [runners.cache.s3]
    [runners.cache.gcs]

重新触发"build1"作业，看看效果。

此时可以看到，作业开始运行了，并且在 ``/root/gitlab-runner/builds`` 目录下生成了四个folder相关的目录::

    [root@server builds]# pwd
    /root/gitlab-runner/builds
    [root@server builds]# ls -ld *folder*
    drwxr-xr-x 5 root root 193 Jul 12 23:08 global_folder
    drwxr-xr-x 3 root root  26 Jul 12 23:08 global_folder.tmp
    drwxr-xr-x 5 root root 193 Jul 12 23:08 sub_folder
    drwxr-xr-x 3 root root  26 Jul 12 23:08 sub_folder.tmp

查看"build1"和"find Bugs"作业的详情：

.. image:: ./_static/images/gitlab_bluelog_custom_build_directory_success_build1_job_details.png

可以看到"build1"作业使用作业级定义的 ``GIT_CLONE_PATH: $CI_BUILDS_DIR/sub_folder`` ，仓库会被下载到 ``/root/gitlab-runner/builds/sub_folder`` 目录下。

.. image:: ./_static/images/gitlab_bluelog_custom_build_directory_success_find_bugs_job_details.png

可以看到"build1"作业使用全局级定义的 ``GIT_CLONE_PATH: $CI_BUILDS_DIR/global_folder`` ，仓库会被下载到 ``/root/gitlab-runner/builds/global_folder`` 目录下。

处理并发(Handling concurrency)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 当执行器配置并发数 ``concurrent`` 大于1时，有可能导致作业运行失败，因为有可能多个作业都运行在相同的目录上，GitLab Runner运行器并不会去阻止这种情形，管理员和开发人员必须遵守Runner配置的要求。
- 要避免这种情况，您可以在 ``$CI_BUILDS_DIR`` 中使用唯一路径，因为Runner公开了另外两个提供唯一并发ID的变量：

    - ``$CI_CONCURRENT_ID`` ：给定执行程序中运行的所有作业的唯一ID。
    - ``$CI_CONCURRENT_PROJECT_ID`` ：在给定执行程序和项目中运行的所有作业的唯一ID。

- 在任何场景和任何执行器中都应该运行良好的最稳定的配置是在 ``GIT_CLONE_PATH`` 中使用 ``$CI_CONCURRENT_ID`` 。 

例如：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 1-2
    
    variables:
      GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name
    
    test:
      script:
        - pwd

嵌套路径(Nested paths)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- ``GIT_CLONE_PATH`` 变量最多只能扩展一次，不支持嵌套的变量路径。

下面定义了两个变量：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 2-3
    
    variables:
      GOPATH: $CI_BUILDS_DIR/go
      GIT_CLONE_PATH: $GOPATH/src/namespace/project

``GIT_CLONE_PATH`` 变量扩展一次后，变量成了 ``$CI_BUILDS_DIR/go/src/namespace/project`` ，这个时候在路径中有一个变量，而 ``GIT_CLONE_PATH`` 变量不会再次扩展 ``$CI_BUILDS_DIR`` 导致作业运行失败。


特殊的YAML功能
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

可以使用特殊的YAML功能，如锚点( ``＆`` )，别名( ``*`` )和合并( ``<<`` )，这将使您大大降低 ``.gitlab-ci.yml`` 的复杂性。

隐藏关键字或作业
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

如果我们想暂时禁用某个作业，我们可以将该作业的所有行都注释掉，如下示例：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 1-3
    
    #hidden_job:
    #  script:
    #    - run test

更好的方法是，我们在作业名称前面增加一个点号( ``.`` )， 这样GitLab CI流水线就会自动处理忽略掉 ``.hidden_job`` 作业。

改成下面这样：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 1
    
    .hidden_job:
      script:
        - run test

锚点(Anchors)
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

- 锚点可以让你容易复制文档内容，锚点可以用来复制或继承某些属性，锚点与隐藏作业一起使用可提供作业模板。

下面的例子使用锚点和合并创建了两个作业，``test1`` 和 ``test2`` ，两个作业都是继承自隐藏作业 ``.job_template`` ，并且都有他们自己独有的工作脚本定义：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 1,8,13
    
    .job_template: &job_definition  # Hidden key that defines an anchor named 'job_definition'
      image: ruby:2.1
      services:
        - postgres
        - redis
    
    test1:
      <<: *job_definition           # Merge the contents of the 'job_definition' alias
      script:
        - test1 project
    
    test2:
      <<: *job_definition           # Merge the contents of the 'job_definition' alias
      script:
        - test2 project
    
- ``&`` 用于设置锚点名称为 ``job_definition`` ，也就是给隐藏作业设置一个锚点 ``job_definition`` 。
- ``<<`` 合并，将锚点定义的模板内容复制到当前作业的当前位置来。
- ``*`` 包含锚点的名称 ``job_definition``。

扩展后的配置文件变成下面这样：

.. code-block:: yaml
    :linenos:
    :emphasize-lines: 8-11,16-19
    
    .job_template:
      image: ruby:2.1
      services:
        - postgres
        - redis
    
    test1:
      image: ruby:2.1
      services:
        - postgres
        - redis
      script:
        - test1 project
    
    test2:
      image: ruby:2.1
      services:
        - postgres
        - redis
      script:
        - test2 project


再看另外一个示例：

.. code-block:: yaml
    :linenos:
    
    .job_template: &job_definition
      script:
        - test project
    
    .postgres_services:
      services: &postgres_definition
        - postgres
        - ruby
    
    .mysql_services:
      services: &mysql_definition
        - mysql
        - ruby
    
    test:postgres:
      <<: *job_definition
      services: *postgres_definition
    
    test:mysql:
      <<: *job_definition
      services: *mysql_definition
    
扩展后是这样的：

.. code-block:: yaml
    :linenos:
    
    .job_template:
      script:
        - test project
    
    .postgres_services:
      services:
        - postgres
        - ruby
    
    .mysql_services:
      services:
        - mysql
        - ruby
    
    test:postgres:
      script:
        - test project
      services:
        - postgres
        - ruby
    
    test:mysql:
      script:
        - test project
      services:
        - mysql
        - ruby
    
可以看到隐藏的关键字或者作业可以方便地用作为模板。


Triggers触发器
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- 当使用触发器令牌触发流水线运行时，触发器可用于强制重建特定分支，标记或提交，并使用API调用。
- 触发器使用可参考 :ref:`trigger_pipeline_label` 。


忽略CI检查
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- 当你提交的commit日志信息中包含 ``[ci skip]`` 或者 ``[skip ci]`` (忽略大小写)，提交可以成功但是会忽略流水线的执行。
- 或者，在 ``git push`` 时添加推送选项，如 ``git push -o ci.skip`` 。


我们第一次修改配置文件，commit日志为"移除自定义构建目录，测试忽略ci构建 ci skip"，包含有 ``ci skip`` 关键字，但是没有左右中括号，进行提交：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_ci_skip.png

但是发现流水线被触发了，正常运行了：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_ci_skip_trigger_success_pipeline.png

我们第二次修改配置文件，commit日志为"移除自定义构建目录，测试忽略ci构建 [CI Skip]"，包含有 ``[CI Skip]`` 关键字，进行提交：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_CI_Skip_Capitalization.png

可以发现流水线没有被触发，但是提交已经创建成功了：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_ci_skip_trigger_skipped_pipeline.png
.. image:: ./_static/images/gitlab_bluelog_git_commit_with_ci_skip_trigger_skipped_pipeline1.png

我们第三次修改配置文件，commit日志为"测试使用git push添加推送选项"，进行提交：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_git_push_ci_skip_option.png

可以发现流水线没有被触发，但是提交已经创建成功了：

.. image:: ./_static/images/gitlab_bluelog_git_commit_with_git_push_ci_skip_option_trigger_skipped_pipeline.png


``.gitlab-ci.yml`` 配置文件各个关键字的使用就介绍到这里。


参考：

- `Getting started with GitLab CI/CD <https://docs.gitlab.com/ce/ci/quick_start/README.html>`_
- `GitLab CI/CD Pipeline Configuration Reference  <https://docs.gitlab.com/ce/ci/yaml/README.html>`_
- `Gitlab CI yaml官方配置文件翻译 <https://segmentfault.com/a/1190000010442764>`_
- `GitLab Runner Advanced configuration <https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-shells>`_
- `Why we're replacing GitLab CI jobs with .gitlab-ci.yml <https://about.gitlab.com/2015/05/06/why-were-replacing-gitlab-ci-jobs-with-gitlab-ci-dot-yml/>`_
- `GitLab CI/CD Examples <https://docs.gitlab.com/ce/ci/examples/README.html>`_
- `GitLab CI/CD Variables <https://docs.gitlab.com/ce/ci/variables/README.html>`_
- `企业级.gitlab-ci.yml示例 <https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.gitlab-ci.yml>`_
- `Gitlab CI 使用高级技巧 <https://www.jianshu.com/p/3c0cbb6c2936>`_
- `git tag的用法 <https://www.cnblogs.com/senlinyang/p/8527764.html>`_
- `Python静态代码检查工具Flake8 <https://www.cnblogs.com/zhangningyang/p/8692546.html>`_
- `Python代码规范利器Flake8 <http://www.imooc.com/article/51227>`_
- `Flake8: Your Tool For Style Guide Enforcement <https://flake8.readthedocs.io/en/latest/>`_
- `基于GitLab CI搭建Golang自动构建环境 <https://www.jqhtml.com/46077.html>`_
- `什么是staging server <https://www.cnblogs.com/beautiful-code/p/6265277.html>`_
- `Cache dependencies in GitLab CI/CD <https://docs.gitlab.com/ce/ci/caching/index.html>`_
- `Introduction to job artifacts <https://docs.gitlab.com/ce/user/project/pipelines/job_artifacts.html>`_
- `dependencies <https://docs.gitlab.com/ce/ci/yaml/README.html#dependencies>`_
- `JUnit test reports <https://docs.gitlab.com/ce/ci/junit_test_reports.html>`_ 
- `include <https://docs.gitlab.com/ce/ci/yaml/README.html#include>`_
- `extends <https://docs.gitlab.com/ce/ci/yaml/README.html#extends>`_
- `GitLab Pages <https://docs.gitlab.com/ce/user/project/pages/index.html>`_
- `Priority of environment variables <https://docs.gitlab.com/ce/ci/variables/README.html#priority-of-environment-variables>`_
- `The [runners.custom_build_dir] section <https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section>`_ 
- `trigger <https://docs.gitlab.com/ce/ci/yaml/README.html#trigger-premium>`_
- `Using Git submodules with GitLab CI <https://docs.gitlab.com/ce/ci/git_submodules.html>`_
- `Shallow cloning <https://docs.gitlab.com/ce/ci/yaml/README.html#shallow-cloning>`_