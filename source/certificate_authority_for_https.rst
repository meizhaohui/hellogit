.. _certificate_authority_for_https:

CentOS 7 搭建CA认证中心实现https认证
=============================================

.. contents:: 目录

本文讲解在CentOS7中搭建CA认证中心，实现Httpd和Nginx的https认证。

实验环境
----------------------------------------

- server服务端: 操作系统为CentOS 7.6，IP:192.168.56.14， git:2.16.5。
- client客户端: 操作系统为CentOS 7.6，IP:192.168.56.15， git:2.16.5。

查看server服务端信息::

    [root@server ~]# cat /etc/centos-release
    CentOS Linux release 7.6.1810 (Core) 
    [root@server ~]# ip a show|grep 192
    inet 192.168.56.14/24 brd 192.168.56.255 scope global noprefixroute enp0s3
    [root@server ~]# git --version
    git version 2.16.5

查看client客户端信息::

    [root@client ~]# cat /etc/centos-release
    CentOS Linux release 7.6.1810 (Core) 
    [root@client ~]# ip a show |grep 192
        inet 192.168.56.15/24 brd 192.168.56.255 scope global noprefixroute enp0s3
    [root@client ~]# git --version
    git version 2.16.5
    
CA认证中心简介
----------------------------------------

- 所谓CA（Certificate Authority）认证中心，它是采用PKI（Public Key Infrastructure）公开密钥基础架构技术，专门提供网络身份认证服务，CA可以是民间团体，也可以是政府机构。负责签发和管理数字证书，且具有权威性和公正性的第三方信任机构，它的作用就像我们现实生活中颁发证件的公司，如护照办理机构。目前国内的CA认证中心主要分为区域性CA认证中心和行业性CA认证中心。
- CA负责数字证书的批审、发放、归档、撤销等功能，CA颁发的数字证书拥有CA的数字签名。
- 数字证书在用户公钥后附加了用户信息及CA的签名。公钥是密钥对的一部分，另一部分是私钥。公钥公之于众，谁都可以使用。私钥只有自己知道。由公钥加密的信息只能由与之相对应的私钥解密。为确保只有某个人才能阅读自己的信件，发送者要用收件人的公钥加密信件；收件人便可用自己的私钥解密信件。同样，为证实发件人的身份，发送者要用自己的私钥对信件进行签名；收件人可使用发送者的公钥对签名进行验证，以确认发送者的身份。
- 作用： ``保密性`` ：只有收件人才能阅读信息; ``认证性`` ：确认信息发送者的身份; ``完整性`` ：信息在传递过程中不会被篡改; ``不可抵赖性`` ：发送者不能否认已发送的信息。
- 端口: https协议一般使用443端口，也可以使用别的端口。
- 证书请求文件： CSR是Cerificate Signing Request的英文缩写，即证书请求文件，也就是证书申请者在申请数字证书时由CSP(加密服务提供者)在生成私钥的同时也生成证书请求文件，证书申请者只要把CSR文件提交给证书颁发机构后，证书颁发机构使用其根证书的私钥签名就生成了证书文件，也就是颁发给用户的证书

在server服务端搭建CA认证中心
----------------------------------------

- 配置一个自己的CA认证中心,把FALSE改成TRUE,把本机变成CA认证中心

修改 ``/etc/pki/tls/openssl.cnf`` 文件第172行::

    [root@localhost ~]# sed -i '172s/basicConstraints=CA:FALSE/basicConstraints=CA:TRUE/g' /etc/pki/tls/openssl.cnf 

修改完成后， ``/etc/pki/tls/openssl.cnf`` 文件第172行处附近的内容如下::

    [root@server ~]# cat -n /etc/pki/tls/openssl.cnf |head -n 172|tail -n 8
       165  [ usr_cert ]
       166
       167  # These extensions are added when 'ca' signs a request.
       168
       169  # This goes against PKIX guidelines but some CAs do it and some software
       170  # requires this to avoid interpreting an end user certificate as a CA.
       171
       172  basicConstraints=CA:TRUE

- 配置认证中心，生成私钥与根证书

使用 ``/etc/pki/tls/misc/CA -newca`` 命令生成私钥和根证书::

    [root@server ~]# /etc/pki/tls/misc/CA -newca
    CA certificate filename (or enter to create)   <--说明:按回车

    Making CA certificate ...
    Generating a 2048 bit RSA private key
    ..................................................................................................................+++
    .+++
    writing new private key to '/etc/pki/CA/private/./cakey.pem'
    Enter PEM pass phrase:    <--说明: 输入密码保护密钥 hellogit
    Verifying - Enter PEM pass phrase:   <--说明: 再次输入密码保护密钥 hellogit
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [XX]:CN  <--说明: 国家地区名称
    State or Province Name (full name) []:hubei  <--说明: 省份名称
    Locality Name (eg, city) [Default City]:wuhan  <--说明: 地市名称
    Organization Name (eg, company) [Default Company Ltd]:IT   <--说明: 组织名称，可以理解为公司的部门
    Organizational Unit Name (eg, section) []:hopewait    <--说明: 组织单位名称
    Common Name (eg, your name or your server's hostname) []:192.168.56.14 <--说明: 通用名，因为没有域名，这里用IP代替，有域名的话，可以使用域名
    Email Address []:mzh.whut@gmail.com

    Please enter the following 'extra' attributes  # 添加一个额外的属性，让客户端发送CA证书，请求文件时要输入密码
    to be sent with your certificate request
    A challenge password []:      <--说明: 回车
    An optional company name []:      <--说明: 回车
    Using configuration from /etc/pki/tls/openssl.cnf  <--说明:  CA服务器的配置文件
    Enter pass phrase for /etc/pki/CA/private/./cakey.pem:   <--说明:  输入保护CA密钥的密码 hellogit
    Check that the request matches the signature
    Signature ok
    Certificate Details:    <--说明:  CA认证中心的详情
            Serial Number:
                a0:10:ec:4f:f7:db:f9:1f
            Validity
                Not Before: Jun  4 22:43:41 2019 GMT
                Not After : Jun  3 22:43:41 2022 GMT
            Subject:
                countryName               = CN
                stateOrProvinceName       = hubei
                organizationName          = IT
                organizationalUnitName    = hopewait
                commonName                = 192.168.56.14
                emailAddress              = mzh.whut@gmail.com
            X509v3 extensions:
                X509v3 Subject Key Identifier: 
                    DF:1A:24:4F:9E:B4:BC:B4:2E:D3:B1:AD:1C:B3:79:9D:4A:B1:35:65
                X509v3 Authority Key Identifier: 
                    keyid:DF:1A:24:4F:9E:B4:BC:B4:2E:D3:B1:AD:1C:B3:79:9D:4A:B1:35:65

                X509v3 Basic Constraints: 
                    CA:TRUE
    Certificate is to be certified until Jun  3 22:43:41 2022 GMT (1095 days)

    Write out database with 1 new entries
    Data Base Updated
    [root@server ~]# 

这里配置了CA认证中心，在里面就生成了CA认证根证书的私钥，在配置完结束之后，就会生成一个根证书，这个根证书中有这证书的公钥
到此CA认证中心就搭建好了。

- CA认证根证书文件 ``/etc/pki/CA/cacert.pem``

查看 ``/etc/pki/CA/cacert.pem`` 文件内容::

    [root@server ~]# cat -n /etc/pki/CA/cacert.pem
         1  Certificate:
         2      Data:
         3          Version: 3 (0x2)
         4          Serial Number:
         5              a0:10:ec:4f:f7:db:f9:1f
         6      Signature Algorithm: sha256WithRSAEncryption
         7          Issuer: C=CN, ST=hubei, O=IT, OU=hopewait, CN=192.168.56.14/emailAddress=mzh.whut@gmail.com  <--说明:  CA认证中心信息
         8          Validity
         9              Not Before: Jun  4 22:43:41 2019 GMT
        10              Not After : Jun  3 22:43:41 2022 GMT
        11          Subject: C=CN, ST=hubei, O=IT, OU=hopewait, CN=192.168.56.14/emailAddress=mzh.whut@gmail.com
        12          Subject Public Key Info:   <--说明:  CA认证中心公钥信息
        13              Public Key Algorithm: rsaEncryption
        14                  Public-Key: (2048 bit)
        15                  Modulus:
        16                      00:ad:2b:62:4e:10:6c:fe:dd:5b:16:1b:dd:ed:e4:
        17                      89:9e:14:d6:e3:6f:a9:56:1c:84:53:4c:12:58:7b:
        18                      43:09:8c:aa:76:d7:5c:8d:90:9f:1a:75:1c:c4:92:
        19                      32:63:bb:ae:3f:51:46:8c:13:17:a7:b6:3a:29:58:
        20                      17:14:5d:fa:a8:8c:66:8e:92:3e:43:72:cf:41:e9:
        21                      f3:7d:d0:5d:3a:75:de:14:80:c7:db:35:f5:fa:41:
        22                      fd:24:11:44:e6:7f:aa:bd:b3:bf:c3:ac:f2:9c:a6:
        23                      48:de:09:d7:72:34:04:44:87:3e:65:27:31:94:3c:
        24                      5a:6d:d9:1e:67:03:05:94:42:33:3e:cc:38:fc:84:
        25                      21:13:47:3e:f0:37:21:7d:cc:c5:54:21:06:9f:44:
        26                      92:20:dd:5e:57:06:ec:33:08:d4:91:99:17:fa:de:
        27                      c4:2e:0b:32:ea:b5:5b:a3:54:6a:ac:2e:e6:4a:ba:
        28                      e3:2f:6c:b3:f1:04:3f:19:6c:7a:97:ab:72:e6:e7:
        29                      1a:88:f7:d2:ba:d4:b3:33:90:1f:f6:3e:f4:fc:6a:
        30                      84:53:24:2b:2f:46:65:ce:1e:86:2c:a6:02:ae:6f:
        31                      5d:b8:cc:b7:31:d4:53:20:97:7a:a1:b2:d6:a1:4a:
        32                      aa:31:e6:13:4a:6c:09:07:98:c5:5d:44:ae:e9:97:
        33                      33:47
        34                  Exponent: 65537 (0x10001)
        35          X509v3 extensions:
        36              X509v3 Subject Key Identifier: 
        37                  DF:1A:24:4F:9E:B4:BC:B4:2E:D3:B1:AD:1C:B3:79:9D:4A:B1:35:65
        38              X509v3 Authority Key Identifier: 
        39                  keyid:DF:1A:24:4F:9E:B4:BC:B4:2E:D3:B1:AD:1C:B3:79:9D:4A:B1:35:65
        40
        41              X509v3 Basic Constraints: 
        42                  CA:TRUE
        43      Signature Algorithm: sha256WithRSAEncryption
        44           48:43:57:30:c2:22:93:3f:85:53:09:5f:8c:fe:91:5e:c4:04:
        45           fe:16:9b:72:18:6f:6f:71:e4:9a:28:a7:c8:0f:66:95:d1:ca:
        46           16:c4:b0:14:ad:c4:16:76:fa:89:77:55:f5:af:e2:ab:9e:3d:
        47           30:7c:41:08:e5:09:11:f0:89:b8:7e:86:04:5e:1f:94:48:4e:
        48           95:14:1c:f5:d5:58:f7:61:23:f7:c4:44:9c:aa:ac:82:fa:71:
        49           64:b2:e8:ba:6e:90:12:25:af:40:5f:87:ee:b4:98:be:67:66:
        50           43:8b:08:49:8f:1a:ba:6f:1b:2a:e9:5e:ba:0e:25:24:cf:25:
        51           70:d7:77:ba:1b:40:94:a4:2d:fe:ab:2e:07:3c:bd:71:4d:f2:
        52           96:ec:35:0b:1f:c9:3f:83:17:75:b9:b2:28:ac:97:03:75:be:
        53           bf:06:ad:42:e2:aa:1a:b5:fe:3f:b9:41:c1:10:83:b3:28:5f:
        54           e8:12:7a:af:81:fe:65:8e:6e:2f:a7:b8:38:83:c3:ef:5f:75:
        55           d5:c6:6e:dc:6f:6f:32:e6:b3:95:92:14:1f:76:c1:44:f1:cd:
        56           a7:97:9e:47:09:c5:5d:fb:ee:cd:0d:14:60:9a:23:fe:ba:dd:
        57           86:6e:01:b4:6a:56:f0:07:3d:4b:de:3e:23:b2:8f:15:f8:87:
        58           53:1b:9b:5a
        59  -----BEGIN CERTIFICATE-----
        60  MIIDwzCCAqugAwIBAgIJAKAQ7E/32/kfMA0GCSqGSIb3DQEBCwUAMHgxCzAJBgNV
        61  BAYTAkNOMQ4wDAYDVQQIDAVodWJlaTELMAkGA1UECgwCSVQxETAPBgNVBAsMCGhv
        62  cGV3YWl0MRYwFAYDVQQDDA0xOTIuMTY4LjU2LjE0MSEwHwYJKoZIhvcNAQkBFhJt
        63  emgud2h1dEBnbWFpbC5jb20wHhcNMTkwNjA0MjI0MzQxWhcNMjIwNjAzMjI0MzQx
        64  WjB4MQswCQYDVQQGEwJDTjEOMAwGA1UECAwFaHViZWkxCzAJBgNVBAoMAklUMREw
        65  DwYDVQQLDAhob3Bld2FpdDEWMBQGA1UEAwwNMTkyLjE2OC41Ni4xNDEhMB8GCSqG
        66  SIb3DQEJARYSbXpoLndodXRAZ21haWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOC
        67  AQ8AMIIBCgKCAQEArStiThBs/t1bFhvd7eSJnhTW42+pVhyEU0wSWHtDCYyqdtdc
        68  jZCfGnUcxJIyY7uuP1FGjBMXp7Y6KVgXFF36qIxmjpI+Q3LPQenzfdBdOnXeFIDH
        69  2zX1+kH9JBFE5n+qvbO/w6zynKZI3gnXcjQERIc+ZScxlDxabdkeZwMFlEIzPsw4
        70  /IQhE0c+8DchfczFVCEGn0SSIN1eVwbsMwjUkZkX+t7ELgsy6rVbo1RqrC7mSrrj
        71  L2yz8QQ/GWx6l6ty5ucaiPfSutSzM5Af9j70/GqEUyQrL0Zlzh6GLKYCrm9duMy3
        72  MdRTIJd6obLWoUqqMeYTSmwJB5jFXUSu6ZczRwIDAQABo1AwTjAdBgNVHQ4EFgQU
        73  3xokT560vLQu07GtHLN5nUqxNWUwHwYDVR0jBBgwFoAU3xokT560vLQu07GtHLN5
        74  nUqxNWUwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEASENXMMIikz+F
        75  UwlfjP6RXsQE/habchhvb3HkmiinyA9mldHKFsSwFK3EFnb6iXdV9a/iq549MHxB
        76  COUJEfCJuH6GBF4flEhOlRQc9dVY92Ej98REnKqsgvpxZLLoum6QEiWvQF+H7rSY
        77  vmdmQ4sISY8aum8bKuleug4lJM8lcNd3uhtAlKQt/qsuBzy9cU3yluw1Cx/JP4MX
        78  dbmyKKyXA3W+vwatQuKqGrX+P7lBwRCDsyhf6BJ6r4H+ZY5uL6e4OIPD71911cZu
        79  3G9vMuazlZIUH3bBRPHNp5eeRwnFXfvuzQ0UYJoj/rrdhm4BtGpW8Ac9S94+I7KP
        80  FfiHUxubWg==
        81  -----END CERTIFICATE-----
    [root@server ~]# 
 
- CA查看根证书的私钥 ``/etc/pki/CA/private/cakey.pem``

查看根证书的私钥 ``/etc/pki/CA/private/cakey.pem`` 文件内容::    
    
    [root@server ~]# ls -lah /etc/pki/CA/private/cakey.pem
    -rw-r--r--. 1 root root 1.8K Jun  5 06:43 /etc/pki/CA/private/cakey.pem
    [root@server ~]# cat -n /etc/pki/CA/private/cakey.pem
         1  -----BEGIN ENCRYPTED PRIVATE KEY-----
         2  MIIFDjBABgkqhkiG9w0BBQ0wMzAbBgkqhkiG9w0BBQwwDgQI45aQOAFPXeUCAggA
         3  MBQGCCqGSIb3DQMHBAjgODWRTTP6hgSCBMgqNsO7bZFjYXn9GXkIV4bMs0TL8dRR
         4  vxWPEy3+6lri3rQfB3Tmwg5jGWHC2o0p7vF+8g1XexSqogzVuuKQrF1Ez7CO0fnp
         5  tNm5jMaQvhivtHzl8PWk7ohpW7aq87eUZGNxDmwvqL3Le2Fm7bkBdUYXidWOZhiD
         6  To+WeI3IuszFBesNbkPtdRRTIBoG2bNWTp5NVxlMOMyyBCN6Fx71cEfhRf509Rzh
         7  1wTBpJQlLVAepqFQxsRnn7VqrcU0Sd05Ln/xO/8603J/UryceqN6Qj+mhrEBOwIi
         8  EgoVvOebSjj82wZRy3PXrEX/e9iYeWeEp7J3XZY7veRx2aooL03WBKsboOO0wWlC
         9  RziJGu2hwDVr0lrVh0sAzhuLN60hYKFD5pyEu8KOo++GLosIInstE/sEeyKaq9BF
        10  cIbeRgBsIK0mwzW/bA2MG5NpY9rees1VQBCmmC0qFygkB+aLObjjX9XxlHiJ0Nf1
        11  b+3QOvCJFXzfYP2czgMx25htNHg/M34JFTo7urhr7TPLku8GzifEqyB95zz6j4Os
        12  YD7kGo142p+iMr+4fTCtS74j/gO9gl59UN4jACBsXXj6qt8vzsAWOS4tXyhpoRIV
        13  OfQxMJLECakj5+BO8yzrMmlZuhIXCI9TguhJRYaocRSt9X3Tt6aTcE2KEp3SWPys
        14  w7epy5ioCjbp10JMbLym8wTRzySxkCnHJLJKztjYYPvIz2343j6y1Ofng4eZhqor
        15  1ZUemlJbBGrQX/dVBQ3m4YgI3+zEijKZ6SvEOuV4+8IjunEWtH/LW8B9EyaV+MnR
        16  OjzIrvmgKUQ8qcT8X9sm/KfcaRCHo3hepqKIVbJlXjBJ4m327BFy9hR4wo30i9Tk
        17  x/TM3ZbYR0m+8RxLBvNYsFiWbTxHPfZagdY0RiINXa/qZ7327t8zeEyrfQQyX9HB
        18  IToQQXD2nCW/EjtKyPemnvQ3UNEGSTPulS+OPdGHSbBllsK1aMJaJfcXp6JhbOzH
        19  JXmMl+ZurubRJk2TWKGjAub1jU9mOhsK8Ty8f1rVEcrlgcPzJMeD+8PdBB4a5C1M
        20  Vq8EvOq6LBcI6fUbgMWq8Vn1msoneILpfgf6m7EnUDkDbfCIOsjDix7FVG8cakES
        21  cs5JKeqI9V7S4UBHrmZwxrc20sqLj3m9c9eYXXWzdA/9xkUWRJcxd6MdIRoN0eX4
        22  qXsl7qHegyjIc8eJpESi6zrVWPc97gh8SsCvpN2gLPmgmHSbjBIlWUJgoUIyywsp
        23  A6UC8GcEhYwfTQp6udpxERM/Wr0fW0qizaxBje2L1vfgB3iC8b9cnZEA+Ln7Uxo5
        24  ZAvtDJzjYw9g2FuVtnwygK8ycAsE3682Zn7TReHc0q+WW8gRmmkH8BHtBFikDLKp
        25  9lT9uci7iqoFUr+EWPydqr+UYRJn+nrZ1Sgd18Q5gj/v0+NrGQBxNlwmaey1+xxK
        26  IkGWQbxn58TtongUXp+c0c6YTiyiV9LzPJKGZkJtkbvCXNfzB0w/Qnn46HuR82Lg
        27  EoSKlAwgLQJ1cviJT+9csoqfM/sT8dKwpR6dplvov7w030CpmyjoJKSSTBu41GMO
        28  8buXuIk2kp+Npn4q9CuQPmm9iLi9THhDvKZEk7vhvPxP3IcVjx5I8affbyJGoLBx
        29  GBA=
        30  -----END ENCRYPTED PRIVATE KEY-----    
    
在client客户端安装Apache WEB服务
----------------------------------------

安装Apache及wsgi支持::

    [root@client ~]# yum install httpd -y     
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.163.com
     * centos-sclo-rh: mirrors.163.com
     * extras: mirrors.163.com
     * updates: mirrors.aliyun.com
    Resolving Dependencies
    --> Running transaction check
    ---> Package httpd.x86_64 0:2.4.6-89.el7.centos will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                    Arch                        Version                                  Repository                    Size
    ====================================================================================================================================
    Installing:
     httpd                      x86_64                      2.4.6-89.el7.centos                      updates                      2.7 M

    Transaction Summary
    ====================================================================================================================================
    Install  1 Package

    Total download size: 2.7 M
    Installed size: 9.4 M
    Downloading packages:
    httpd-2.4.6-89.el7.centos.x86_64.rpm                                                                         | 2.7 MB  00:00:01     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : httpd-2.4.6-89.el7.centos.x86_64                                                                                 1/1 
      Verifying  : httpd-2.4.6-89.el7.centos.x86_64                                                                                 1/1 

    Installed:
      httpd.x86_64 0:2.4.6-89.el7.centos                                                                                                

    Complete!
    [root@client ~]# 
    
        [root@client ~]# yum install python36u-mod_wsgi httpd-devel -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.163.com
     * centos-sclo-rh: mirrors.163.com
     * extras: mirrors.163.com
     * updates: mirrors.aliyun.com
    Resolving Dependencies
    --> Running transaction check
    ---> Package httpd-devel.x86_64 0:2.4.6-89.el7.centos will be installed
    ---> Package python36u-mod_wsgi.x86_64 0:4.6.2-1.ius.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                             Arch                    Version                                 Repository                Size
    ====================================================================================================================================
    Installing:
     httpd-devel                         x86_64                  2.4.6-89.el7.centos                     updates                  196 k
     python36u-mod_wsgi                  x86_64                  4.6.2-1.ius.el7                         ius                      473 k

    Transaction Summary
    ====================================================================================================================================
    Install  2 Packages

    Total download size: 669 k
    Installed size: 1.8 M
    Downloading packages:
    (1/2): httpd-devel-2.4.6-89.el7.centos.x86_64.rpm                                                            | 196 kB  00:00:00     
    (2/2): python36u-mod_wsgi-4.6.2-1.ius.el7.x86_64.rpm                                                         | 473 kB  00:00:03     
    ------------------------------------------------------------------------------------------------------------------------------------
    Total                                                                                               182 kB/s | 669 kB  00:00:03     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : python36u-mod_wsgi-4.6.2-1.ius.el7.x86_64                                                                        1/2 
      Installing : httpd-devel-2.4.6-89.el7.centos.x86_64                                                                           2/2 
      Verifying  : httpd-devel-2.4.6-89.el7.centos.x86_64                                                                           1/2 
      Verifying  : python36u-mod_wsgi-4.6.2-1.ius.el7.x86_64                                                                        2/2 

    Installed:
      httpd-devel.x86_64 0:2.4.6-89.el7.centos                        python36u-mod_wsgi.x86_64 0:4.6.2-1.ius.el7                       

    Complete!

修改httpd的配置文件，修改ServerName::

    [root@client ~]# sed -i '95s/#ServerName www.example.com:80/ServerName 192.168.56.15:80/g' /etc/httpd/conf/httpd.conf    
    [root@client ~]# cat -n /etc/httpd/conf/httpd.conf|head -n 95|tail -n 1
    95  ServerName 192.168.56.15:80
    
设置开机启动并启动httpd服务::  

    root@client ~]# systemctl enable httpd
    Created symlink from /etc/systemd/system/multi-user.target.wants/httpd.service to /usr/lib/systemd/system/httpd.service.
    [root@client ~]# systemctl start httpd 
    [root@client ~]# systemctl status httpd
    ● httpd.service - The Apache HTTP Server
       Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
       Active: active (running) since Wed 2019-06-05 20:37:42 CST; 5s ago
         Docs: man:httpd(8)
               man:apachectl(8)
     Main PID: 13453 (httpd)
       Status: "Processing requests..."
        Tasks: 6
       Memory: 22.7M
       CGroup: /system.slice/httpd.service
               ├─13453 /usr/sbin/httpd -DFOREGROUND
               ├─13454 /usr/sbin/httpd -DFOREGROUND
               ├─13455 /usr/sbin/httpd -DFOREGROUND
               ├─13456 /usr/sbin/httpd -DFOREGROUND
               ├─13457 /usr/sbin/httpd -DFOREGROUND
               └─13458 /usr/sbin/httpd -DFOREGROUND

    Jun 05 20:37:25 client.hopewait systemd[1]: Starting The Apache HTTP Server...
    Jun 05 20:37:42 client.hopewait systemd[1]: Started The Apache HTTP Server.  

防火墙开放80端口::

    [root@client ~]# firewall-cmd --zone=public --add-port=80/tcp --permanent   
    success
    [root@client ~]# firewall-cmd --reload
    success
    [root@client ~]# firewall-cmd --list-all
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources: 
      services: ssh dhcpv6-client
      ports: 8140/tcp 53/tcp 11211/tcp 80/tcp
      protocols: 
      masquerade: no
      forward-ports: 
      source-ports: 
      icmp-blocks: 
      rich rules: 

在浏览器中访问链接 http://192.168.56.15/ ，则可以看到Nginx的测试页:

.. image:: ./_static/images/httpd_test.png

现在我们能够正常访问httpd的服务，能正常访问80端口，我们在Client客户端配置CA证书，使httpd提供https加密服务。

在client客户端生成请求证书文件
----------------------------------------

生成一个私钥密码::

    [root@client ~]# mkdir cafiles
    [root@client ~]# openssl genrsa -des3 -out ~/cafiles/server.key
    Generating RSA private key, 2048 bit long modulus
    ...............+++
    .................................+++
    e is 65537 (0x10001)
    Enter pass phrase for /root/cafiles/server.key:    <--说明:  输入保护私钥的密码clientca
    Verifying - Enter pass phrase for /root/cafiles/server.key:   <--说明:  再次输入保护私钥的密码clientca
    [root@client ~]# ls -lah ~/cafiles
    total 8.0K
    drwxr-xr-x.  2 root root   24 Jun  5 20:58 .
    dr-xr-x---. 14 root root 4.0K Jun  5 20:58 ..
    -rw-r--r--.  1 root root 1.8K Jun  5 20:59 server.key


查看私钥文件内容::

    [root@client ~]# cat cafiles/server.key 
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: DES-EDE3-CBC,E38009EB74CF6AE9  <--说明:  这个地方进行了加密

    I22V4W17mIUr5NAj4gQv5kID6QyFr2AUTOdzcyfeA9rT1FXzAV/r+29aZopcs8Bt
    sHcoR/ZOXidyNQDqlEw5Wbu8UAcA/HZyqOpIsjNQlJnaUpHCc8ATQNo3E0HfDS4W
    hLuStGZcoT4AsTbnaHEzkdN8X+ancBmQ2tLz0Hcc/LbTyZKycEXH1kE+PZauLroi
    LK+hl279E4NjeHnjx6jOTe2ebhWjmDfW66U+aZD3Gxfyx7qalR/UclKi54Uy17kQ
    uSslWWnzUVZoInuJs1fzMSA1iWkrPFPn8R9oOUWYCnyjNKBabmvQqLJbteA22OoJ
    1ZlYrNoommCoOpNV9h8VO9B71Czh6Nf+rtNJ84c1tgUlGgdwGhDriXc+q8OpThqd
    ELlmNUg+3LKJo21ZMNiX9LLCoaQnealYFI2N3u+vq0l9x4T5deghx3kMova2VF4Y
    ng/NYPsfN7OlmJI/9dgzKJGCM+hESMB/99Xz0pNOUmK4IR+V8RAHLVd+yGE0JpV8
    qZvZRT2RAiWLpY5Rx7G1u8CPnHJB1BocFbZ4L8/udreObso2HGWt+Kw0Y3rDr2mM
    Exr7ZLkD1JsJzCLdC6Y+iQjw0/WyhoXBowyRtbvyvGEPVdU2lVUy7NzmnX7BIo+g
    Kdej+II23ctZuaDPHl0fVhkgZBHg0hUsGjO0HbZzXRx95QJjtKGRzzkcBgJ+HbRX
    RsK493ak3qhOb+w+0zb8Cgr/U6F6ALy9czUsgKVwzjpQmaF7ekOcMx/o872Pj89U
    CcPavtZGjqAFpwnwPS3iRPR2Fxddhb6zqtfKN5IJqcvh5xHUtcSd4rUjjFtGI6sc
    ozW8Rz0H7EMiBpxLAUGeNqoh2cfYGPcpzIlqc1pIPGY2NJf9GmlnfMKwo3OGaLFE
    Or2UpvAzCuGQXwc1gNdTGLsmB7Ih8iLQdSuuMVh/cVWfmOX5ahpcd+SLl3rYwSHK
    X9qvEq23jCwSbX1KcVncHFnkTyji7UMveFwsZArYA/zOIN61rXHgT2MvOZje6aR/
    +i8e4buaZ1aMFM1enfRufJaq2ppW7de8sENnBnHt1U0pIAW6wTW9a3JQGKIvhf+F
    rk2FN5w40IGHVCY2P5Wmn+3sfHrDD01rwaAojT9jV3YMfiQx3jnLjunbVbevb0Hn
    hb3Hks3qYS3HDjU1pu+BUSUUQOgLkmp/g6ehxTbvHg8rXT75q/X04b+dw/oEVfdB
    5ZDSVcoUNJZ3VjjxCfpgOim7t0qvqoRN6JQOq3kBH/CsJfAE++JfcmSrlyOnmAck
    +uixe+wBSkTDs9N/22I7lBEDyli4DErlZdEBY2rRnfIH+guTmM8uG+P3wjIsX+M5
    xJmBfc8qSno6IZQVxCDyRdIqpJmXYcjSNhWCcEWSUdvumkYFr8wvF/ljS1JIhI2I
    OiyF9OuYwY2ny0LPRkrB0iD9CLGdP/H++NxOKaSgblBlTOYr2lyKAw3oqxtw4Hxl
    dt+MMJozi78nEaAw5B49ezqWHe+ChkQcsAwJ3VfqIRPNSyv+Ji/E4Xsu3FNZTYRb
    psll9JhUhSinvJ0qkCpRl/5FdbZYTDi7uXXVMoOENdprdMjg+THsXCvHs2sAE45y
    -----END RSA PRIVATE KEY-----

生成请求文件::

    [root@client ~]# openssl req -new -key ~/cafiles/server.key -out ~/cafiles/server.csr
    Enter pass phrase for /root/cafiles/server.key:    <--说明:  输入保护私钥的密码clientca
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [XX]:CN   <--说明: 国家地区名称，与前面的CA设置保持一致
    State or Province Name (full name) []:hubei   <--说明: 省份名称，与前面的CA设置保持一致
    Locality Name (eg, city) [Default City]:wuhan   <--说明: 地市名称，与前面的CA设置保持一致
    Organization Name (eg, company) [Default Company Ltd]:IT  <--说明: 组织名称，可以理解为公司的部门，与前面的CA设置保持一致
    Organizational Unit Name (eg, section) []:hopewait     <--说明:  输入组织单位名称，与前面的CA设置保持一致
    Common Name (eg, your name or your server's hostname) []:192.168.56.15   <--说明:  输入通用名，与通过URL访问web的地址设置保持一致，有域名用域名，没域名用IP地址
    Email Address []:mzh.whut@gmail.com    <--说明:  输入邮箱，可以与前面的CA设置不一致

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:  <--说明:  回车
    An optional company name []:  <--说明:  回车
    [root@client ~]# 

查看刚生成的请求文件::

    [root@client ~]# ls -lah ~/cafiles/
    total 12K
    drwxr-xr-x.  2 root root   42 Jun  5 21:05 .
    dr-xr-x---. 14 root root 4.0K Jun  5 20:58 ..
    -rw-r--r--.  1 root root 1.1K Jun  5 21:05 server.csr
    -rw-r--r--.  1 root root 1.8K Jun  5 20:59 server.key
    [root@client ~]# cat -n ~/cafiles/server.csr 
         1  -----BEGIN CERTIFICATE REQUEST-----
         2  MIICzjCCAbYCAQAwgYgxCzAJBgNVBAYTAkNOMQ4wDAYDVQQIDAVodWJlaTEOMAwG
         3  A1UEBwwFd3VoYW4xCzAJBgNVBAoMAklUMREwDwYDVQQLDAhob3Bld2FpdDEWMBQG
         4  A1UEAwwNMTkyLjE2OC41Ni4xNTEhMB8GCSqGSIb3DQEJARYSbXpoLndodXRAZ21h
         5  aWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2SPcNRvB8QBX
         6  6ey05Wjf3P4AmXISwAYnt3DWw0WfmO8vXl5t0g5DAHoqQdK5hcL2DAAxHaTR2w+5
         7  JsGKwGmrQulCrX3jmDcalKM2cUn3GoCZ0oHVTgV2iYDBoWTRn7yT4IIjGSGzFzf5
         8  stGj1S8mK+X+F2TgairevZanZ08Qh3/Bm37vfI3FudiPq7A+AqyACtnEjGgnQCgG
         9  XnsnmqsJpR15mRz93JpqZ/WTJrh/2pO9bWxGDM5vuZWr9T+1VMZr9R4RQqOqwopf
        10  eBnZqEcE9lDf8/DeklbAIviXJLK3S9qbsspXbLchc4MUWnsSBOPBsdig9dQY7Vx5
        11  s5sG1LqBZwIDAQABoAAwDQYJKoZIhvcNAQELBQADggEBAG5vN/IhhzbDvHgTdfhT
        12  pgNqWmg4XCV1agh7m6CKcg+LcJLPixbW6EA/NU9QX4ARZJp501t7v/bFPiQ1/uEm
        13  IrQqRnM4xGCdpVaY4Y1J21i8t1YoRZAOST9xgQe5nTwq2U1A1wyFJkKYgTFB5ou1
        14  UlI4wELnYTUcrOr4V/4b3DTEZNNfCk6oWv4guQI9UpC+i9FNQb/NkcePkNsQeE4n
        15  q1uM07C05+KMd/Lem6fLUlIDHlpI0iyhuQcSM1TJ1fKmF5uRQHTxIHnI5qqKbP5P
        16  tPW9DLv577wM7W4jIUbEhYkKPLRFLFobITMQu9nDUyF3WEbFbMHvippnu7nxRvb2
        17  OWQ=
        18  -----END CERTIFICATE REQUEST-----
    [root@client ~]# 


在client客户端将请求证书文件发送给server服务端
----------------------------------------------------------

使用scp将请求证书文件发送到服务端::

    [root@client ~]# scp ~/cafiles/server.csr root@192.168.56.14:/tmp
    root@192.168.56.14's password:  <--说明:  输入服务端root账号密码
    server.csr                                                                                        100% 1050   460.4KB/s   00:00    
    [root@client ~]# 


在server服务端对用户的请求文件进行CA签名
----------------------------------------------------------

查看用户的请求文件是否发送过来::

    [root@server ~]#  ls -lah /tmp/server.csr
    -rw-r--r--. 1 root root 1.1K Jun  5 21:12 /tmp/server.csr

说明请求文件发送到服务端了。

- CA认证中心进行CA签名，使用CA认证中心的私钥 ``/etc/pki/CA/private/cakey.pem`` 以及CA根证书 ``/etc/pki/CA/cacert.pem`` 对用户的请求文件 ``server.csr`` 进行签名。
- days参数控制证书有效期，可以设置为365*2=730天，2年！

CA认证中心对用户请求文件进行签名::

    [root@server ~]# openssl ca -keyfile /etc/pki/CA/private/cakey.pem -cert /etc/pki/CA/cacert.pem -days 730 -in /tmp/server.csr -out /tmp/server.crt
    Using configuration from /etc/pki/tls/openssl.cnf
    Enter pass phrase for /etc/pki/CA/private/cakey.pem:    <--说明: 输入CA中心保护密钥的密码hellogit
    Check that the request matches the signature
    Signature ok
    Certificate Details:
            Serial Number:
                a0:10:ec:4f:f7:db:f9:20
            Validity
                Not Before: Jun  5 13:21:44 2019 GMT
                Not After : Jun  4 13:21:44 2021 GMT
            Subject:
                countryName               = CN
                stateOrProvinceName       = hubei
                organizationName          = IT
                organizationalUnitName    = hopewait
                commonName                = 192.168.56.15
                emailAddress              = mzh.whut@gmail.com
            X509v3 extensions:
                X509v3 Basic Constraints: 
                    CA:TRUE
                Netscape Comment: 
                    OpenSSL Generated Certificate
                X509v3 Subject Key Identifier: 
                    5D:39:25:F3:C3:DB:13:ED:6F:9C:C3:30:E8:5C:59:46:1D:6E:37:58
                X509v3 Authority Key Identifier: 
                    keyid:DF:1A:24:4F:9E:B4:BC:B4:2E:D3:B1:AD:1C:B3:79:9D:4A:B1:35:65

    Certificate is to be certified until Jun  4 13:21:44 2021 GMT (730 days)
    Sign the certificate? [y/n]:y    <--说明: 是否注册证书，输入y


    1 out of 1 certificate requests certified, commit? [y/n]y   <--说明: 是否确认注册证书，输入y
    Write out database with 1 new entries
    Data Base Updated
    [root@server ~]# 

将CA中心的签名文件发送给用户::

    [root@server ~]# ls -lah /tmp/server.c*
    -rw-r--r--. 1 root root 4.6K Jun  5 21:21 /tmp/server.crt
    -rw-r--r--. 1 root root 1.1K Jun  5 21:12 /tmp/server.csr
    [root@server ~]# scp /tmp/server.crt root@192.168.56.15:/root/cafiles/
    The authenticity of host '192.168.56.15 (192.168.56.15)' can't be established.
    ECDSA key fingerprint is SHA256:7rw7b1vOEC5UmjDAbdIJ6SCK4aoGk5e+48vi3ubjdjE.
    ECDSA key fingerprint is MD5:96:39:70:28:72:73:f5:34:61:6f:b6:37:da:90:58:48.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added '192.168.56.15' (ECDSA) to the list of known hosts.
    root@192.168.56.15's password: 
    server.crt                                                                                        100% 4617     2.8MB/s   00:00    
    [root@server ~]# 


在client客户端使用CA中心颁发的证书文件配置https httpd web服务
----------------------------------------------------------------

查看CA中心发送过来的证书文件 ``server.crt`` ::

    [root@client ~]# ls -lah ~/cafiles/
    total 20K
    drwxr-xr-x.  2 root root   60 Jun  5 21:28 .
    dr-xr-x---. 14 root root 4.0K Jun  5 20:58 ..
    -rw-r--r--.  1 root root 4.6K Jun  5 21:28 server.crt
    -rw-r--r--.  1 root root 1.1K Jun  5 21:05 server.csr
    -rw-r--r--.  1 root root 1.8K Jun  5 20:59 server.key
    [root@client ~]# 

说明已经有了证书文件。

安装mod_ssl模块::

    [root@client ~]# yum install mod_ssl -y
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.163.com
     * centos-sclo-rh: mirrors.163.com
     * extras: mirrors.huaweicloud.com
     * updates: mirrors.163.com
    Resolving Dependencies
    --> Running transaction check
    ---> Package mod_ssl.x86_64 1:2.4.6-89.el7.centos will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                     Arch                       Version                                   Repository                   Size
    ====================================================================================================================================
    Installing:
     mod_ssl                     x86_64                     1:2.4.6-89.el7.centos                     updates                     112 k

    Transaction Summary
    ====================================================================================================================================
    Install  1 Package

    Total download size: 112 k
    Installed size: 224 k
    Downloading packages:
    mod_ssl-2.4.6-89.el7.centos.x86_64.rpm                                                                       | 112 kB  00:00:00     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : 1:mod_ssl-2.4.6-89.el7.centos.x86_64                                                                             1/1 
      Verifying  : 1:mod_ssl-2.4.6-89.el7.centos.x86_64                                                                             1/1 

    Installed:
      mod_ssl.x86_64 1:2.4.6-89.el7.centos                                                                                              

    Complete!
    [root@client ~]# 
    
复制server.key和server.crt文件到etc/httpd/conf.d/目录下::

    [root@client ~]# cp ~/cafiles/server.key /etc/httpd/conf.d/
    [root@client ~]# cp ~/cafiles/server.crt /etc/httpd/conf.d/
    [root@client ~]# ls -lah /etc/httpd/conf.d/
    total 40K
    drwxr-xr-x. 2 root root  134 Jun  5 22:03 .
    drwxr-xr-x. 5 root root   92 Jun  5 20:32 ..
    -rw-r--r--. 1 root root 2.9K Apr 24 21:45 autoindex.conf
    -rw-r--r--. 1 root root  366 Apr 24 21:46 README
    -rw-r--r--. 1 root root 4.6K Jun  5 22:03 server.crt
    -rw-r--r--. 1 root root 1.8K Jun  5 22:03 server.key
    -rw-r--r--. 1 root root 9.3K Jun  5 21:58 ssl.conf
    -rw-r--r--. 1 root root 1.3K Apr 24 21:44 userdir.conf
    -rw-r--r--. 1 root root  824 Apr 24 21:44 welcome.conf
    [root@client ~]#    


修改httpd的ssl配置文件 ``修改配置文件/etc/httpd/conf.d/ssl.conf`` ::

    [root@client ~]# cat -n /etc/httpd/conf.d/ssl.conf|head -n 108|tail -n 14     <--说明:  配置文件原始内容
        95  #   Server Certificate:
        96  # Point SSLCertificateFile at a PEM encoded certificate.  If
        97  # the certificate is encrypted, then you will be prompted for a
        98  # pass phrase.  Note that a kill -HUP will prompt again.  A new
        99  # certificate can be generated using the genkey(1) command.
       100  SSLCertificateFile /etc/pki/tls/certs/localhost.crt     <--说明:  配置文件原始内容
       101
       102  #   Server Private Key:
       103  #   If the key is not combined with the certificate, use this
       104  #   directive to point at the key file.  Keep in mind that if
       105  #   you've both a RSA and a DSA private key you can configure
       106  #   both in parallel (to also allow the use of DSA ciphers, etc.)
       107  SSLCertificateKeyFile /etc/pki/tls/private/localhost.key      <--说明:  配置文件原始内容
       108
    [root@client ~]#   
     <--说明:  替换配置文件的内容  
    [root@client ~]# sed -i '100s@SSLCertificateFile /etc/pki/tls/certs/localhost.crt@SSLCertificateFile /etc/httpd/conf.d/server.crt@g' /etc/httpd/conf.d/ssl.conf
    [root@client ~]# sed -i '107s@SSLCertificateKeyFile /etc/pki/tls/private/localhost.key@SSLCertificateKeyFile /etc/httpd/conf.d/server.key@g' /etc/httpd/conf.d/ssl.conf
    [root@client ~]# cat -n /etc/httpd/conf.d/ssl.conf|head -n 108|tail -n 14    <--说明:  配置文件修改后的内容
        95  #   Server Certificate:
        96  # Point SSLCertificateFile at a PEM encoded certificate.  If
        97  # the certificate is encrypted, then you will be prompted for a
        98  # pass phrase.  Note that a kill -HUP will prompt again.  A new
        99  # certificate can be generated using the genkey(1) command.
       100  SSLCertificateFile /etc/httpd/conf.d/server.crt      <--说明:  配置文件修改后的内容，指向CA中心颁发证书的路径
       101
       102  #   Server Private Key:
       103  #   If the key is not combined with the certificate, use this
       104  #   directive to point at the key file.  Keep in mind that if
       105  #   you've both a RSA and a DSA private key you can configure
       106  #   both in parallel (to also allow the use of DSA ciphers, etc.)
       107  SSLCertificateKeyFile /etc/httpd/conf.d/server.key    <--说明:  配置文件修改后的内容，自己的私钥文件的路径
       108
    [root@client ~]#   

奇怪的是，如果不将ca证书文件从~/cafiles复制到/etc/httpd/conf.d/目录下，启动httpd会失败，并报"SSLCertificateFile: file '/root/cafiles/server.crt' does not exist or is empty"异常。
    
    
重启httpd服务::

    [root@client ~]# systemctl restart httpd
    Enter SSL pass phrase for 192.168.56.15:443 (RSA) : ********  <--说明:  需要输入保护私钥的密码clientca
    [root@client ~]#  

查看httpd服务启用的端口号::

    [root@client ~]# netstat -tunlp|grep httpd
    tcp6       0      0 :::80                   :::*                    LISTEN      14217/httpd         
    tcp6       0      0 :::443                  :::*                    LISTEN      14217/httpd         
    [root@client ~]#   

发现已经开启了443端口，说明可以使用https协议。    
    
防火墙开放443端口::

    [root@client ~]# firewall-cmd --zone=public  --add-port=443/tcp --permanent 
    success
    [root@client ~]# firewall-cmd --reload
    success
    [root@client ~]# firewall-cmd --list-all
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources: 
      services: ssh dhcpv6-client
      ports: 8140/tcp 53/tcp 11211/tcp 80/tcp 443/tcp
      protocols: 
      masquerade: no
      forward-ports: 
      source-ports: 
      icmp-blocks: 
      rich rules: 

    [root@client ~]# 
    
 
在浏览器中访问 https://192.168.56.15/ ，可以正常访问，说明配置正常。


Enter PEM pass phrase 处理
------------------------------------------------------------

解决每次重启httpd服务提示"Enter PEM pass phrase"需要输入保护私钥的密码的问题::

    [root@client ~]# openssl rsa -in ~/cafiles/server.key -out ~/cafiles/server.key.unsecure  <-- 说明: 从server.key中剥离密码
    Enter pass phrase for /root/cafiles/server.key:  <--说明:  需要输入保护私钥的密码clientca
    writing RSA key
    [root@client ~]# ls -lah ~/cafiles/
    total 24K
    drwxr-xr-x.  2 root root   87 Jun  5 22:25 .
    dr-xr-x---. 14 root root 4.0K Jun  5 22:08 ..
    -rw-r--r--.  1 root root 4.6K Jun  5 21:28 server.crt
    -rw-r--r--.  1 root root 1.1K Jun  5 21:05 server.csr
    -rw-r--r--.  1 root root 1.8K Jun  5 20:59 server.key
    -rw-r--r--.  1 root root 1.7K Jun  5 22:25 server.key.unsecure
    [root@client ~]# cp ~/cafiles/server.key.unsecure /etc/httpd/conf.d/
    [root@client ~]# ls -lah /etc/httpd/conf.d/server.*
    -rw-r--r--. 1 root root 4.6K Jun  5 22:03 /etc/httpd/conf.d/server.crt
    -rw-r--r--. 1 root root 1.8K Jun  5 22:03 /etc/httpd/conf.d/server.key
    -rw-r--r--. 1 root root 1.7K Jun  5 22:26 /etc/httpd/conf.d/server.key.unsecure
    [root@client ~]# 

修改配置文件 ``/etc/httpd/conf.d/ssl.conf`` 中的server.key 为 ``server.key.unsecure`` ,修改后显示如下 ::

    [root@client ~]# cat -n /etc/httpd/conf.d/ssl.conf|head -n 108|tail -n 14 
        95  #   Server Certificate:
        96  # Point SSLCertificateFile at a PEM encoded certificate.  If
        97  # the certificate is encrypted, then you will be prompted for a
        98  # pass phrase.  Note that a kill -HUP will prompt again.  A new
        99  # certificate can be generated using the genkey(1) command.
       100  SSLCertificateFile /etc/httpd/conf.d/server.crt
       101
       102  #   Server Private Key:
       103  #   If the key is not combined with the certificate, use this
       104  #   directive to point at the key file.  Keep in mind that if
       105  #   you've both a RSA and a DSA private key you can configure
       106  #   both in parallel (to also allow the use of DSA ciphers, etc.)
       107  SSLCertificateKeyFile /etc/httpd/conf.d/server.key.unsecure    <--说明:   修改此处
       108
    [root@client ~]# 

重启httpd服务::

    [root@client ~]# systemctl restart httpd  <--说明:  不再需要输入保护私钥的密码！！！
    [root@client ~]#  

远程访问https web服务
------------------------------------------------------------

在Google浏览器中打开 https://192.168.56.15/ 链接，显示如下图:

.. image:: ./_static/images/err_cert_authority_invalid.png

点击"高级" --> "继续前往192.168.56.15（不安全）"，则会正常显示页面:

.. image:: ./_static/images/httpd_https_test.png
 
点击Google地址栏"不安全" --> "证书(无效)"，则会正常显示页面，可以看到证书有效期是2年: 

.. image:: ./_static/images/unsecure.png

点击"证书" --> "详细信息"，可以看到颁发者就是我们的CA中心，则会正常显示页面: 

.. image:: ./_static/images/ca_details.png

在client客户端使用CA中心颁发的证书文件配置https nginx web服务
---------------------------------------------------------------

为避免nginx测试与httpd冲突，先停止httpd服务，并移除开机自启::

    [root@client ~]# systemctl stop httpd
    [root@client ~]# systemctl status httpd
    ● httpd.service - The Apache HTTP Server
       Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
       Active: inactive (dead) since Wed 2019-06-05 22:52:06 CST; 5s ago
         Docs: man:httpd(8)
               man:apachectl(8)
      Process: 14547 ExecStop=/bin/kill -WINCH ${MAINPID} (code=exited, status=0/SUCCESS)
      Process: 14506 ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND (code=exited, status=0/SUCCESS)
     Main PID: 14506 (code=exited, status=0/SUCCESS)
       Status: "Total requests: 10; Current requests/sec: 0; Current traffic:   0 B/sec"

    Jun 05 22:31:04 client.hopewait systemd[1]: Starting The Apache HTTP Server...
    Jun 05 22:31:04 client.hopewait systemd[1]: Started The Apache HTTP Server.
    Jun 05 22:52:05 client.hopewait systemd[1]: Stopping The Apache HTTP Server...
    Jun 05 22:52:06 client.hopewait systemd[1]: Stopped The Apache HTTP Server.
    [root@client ~]# systemctl disable httpd
    Removed symlink /etc/systemd/system/multi-user.target.wants/httpd.service.
    [root@client ~]# 

安装 ``nginx-1.12.2`` 这个版本中 ``nginx.conf`` 文本已经配置好了模板::
    
    # 安装YUM源:
   [root@client ~]# yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
   [root@client ~]# rpm -ivh https://centos7.iuscommunity.org/ius-release.rpm
   
   # 更新epel为清华大学开源软件镜像站的源
   参考 https://mirror.tuna.tsinghua.edu.cn/help/epel/
   可使用以下三个命令进行更新
   [root@client ~]# sed -i 's@^#baseurl@baseurl@g' /etc/yum.repos.d/epel.repo
   [root@client ~]# sed -i 's@^metalink@#metalink@g' /etc/yum.repos.d/epel.repo
   [root@client ~]# sed -i 's@http://download.fedoraproject.org/pub@https://mirrors.tuna.tsinghua.edu.cn@g' /etc/yum.repos.d/epel.repo
   
   
   # 查看nginx info页:
   [root@client ~]# yum info nginx
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirror.jdcloud.com
     * centos-sclo-rh: mirror.jdcloud.com
     * epel: mirrors.tuna.tsinghua.edu.cn
     * extras: mirror.jdcloud.com
     * updates: mirror.jdcloud.com
    Available Packages
    Name        : nginx
    Arch        : x86_64
    Epoch       : 1
    Version     : 1.12.2
    Release     : 3.el7
    Size        : 531 k
    Repo        : epel/x86_64
    Summary     : A high performance web server and reverse proxy server
    URL         : http://nginx.org/
    License     : BSD
    Description : Nginx is a web server and a reverse proxy server for HTTP, SMTP, POP3 and
                : IMAP protocols, with a strong focus on high concurrency, performance and low
                : memory usage.
    
    # 安装
    [root@client ~]# yum install nginx-1.12.2
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirror.jdcloud.com
     * centos-sclo-rh: mirror.jdcloud.com
     * epel: mirrors.tuna.tsinghua.edu.cn
     * extras: mirror.jdcloud.com
     * updates: mirror.jdcloud.com
    Resolving Dependencies
    --> Running transaction check
    ---> Package nginx.x86_64 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: nginx-all-modules = 1:1.12.2-3.el7 for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: nginx-filesystem = 1:1.12.2-3.el7 for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: nginx-filesystem for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: libprofiler.so.0()(64bit) for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Running transaction check
    ---> Package gperftools-libs.x86_64 0:2.6.1-1.el7 will be installed
    ---> Package nginx-all-modules.noarch 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: nginx-mod-http-geoip = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-image-filter = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-perl = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-xslt-filter = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-mail = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-stream = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    ---> Package nginx-filesystem.noarch 1:1.12.2-3.el7 will be installed
    --> Running transaction check
    ---> Package nginx-mod-http-geoip.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-http-image-filter.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-http-perl.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-http-xslt-filter.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-mail.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-stream.x86_64 1:1.12.2-3.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    ====================================================================================================================================
     Package                                      Arch                    Version                           Repository             Size
    ====================================================================================================================================
    Installing:
     nginx                                        x86_64                  1:1.12.2-3.el7                    epel                  531 k
    Installing for dependencies:
     gperftools-libs                              x86_64                  2.6.1-1.el7                       base                  272 k
     nginx-all-modules                            noarch                  1:1.12.2-3.el7                    epel                   16 k
     nginx-filesystem                             noarch                  1:1.12.2-3.el7                    epel                   17 k
     nginx-mod-http-geoip                         x86_64                  1:1.12.2-3.el7                    epel                   23 k
     nginx-mod-http-image-filter                  x86_64                  1:1.12.2-3.el7                    epel                   27 k
     nginx-mod-http-perl                          x86_64                  1:1.12.2-3.el7                    epel                   36 k
     nginx-mod-http-xslt-filter                   x86_64                  1:1.12.2-3.el7                    epel                   26 k
     nginx-mod-mail                               x86_64                  1:1.12.2-3.el7                    epel                   54 k
     nginx-mod-stream                             x86_64                  1:1.12.2-3.el7                    epel                   76 k

    Transaction Summary
    ====================================================================================================================================
    Install  1 Package (+9 Dependent packages)

    Total download size: 1.1 M
    Installed size: 3.2 M
    Is this ok [y/d/N]: y
    Downloading packages:
    (1/10): nginx-all-modules-1.12.2-3.el7.noarch.rpm                                                            |  16 kB  00:00:01     
    (2/10): gperftools-libs-2.6.1-1.el7.x86_64.rpm                                                               | 272 kB  00:00:02     
    (3/10): nginx-filesystem-1.12.2-3.el7.noarch.rpm                                                             |  17 kB  00:00:03     
    (4/10): nginx-1.12.2-3.el7.x86_64.rpm                                                                        | 531 kB  00:00:04     
    (5/10): nginx-mod-http-geoip-1.12.2-3.el7.x86_64.rpm                                                         |  23 kB  00:00:00     
    (6/10): nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64.rpm                                                   |  26 kB  00:00:00     
    (7/10): nginx-mod-mail-1.12.2-3.el7.x86_64.rpm                                                               |  54 kB  00:00:00     
    (8/10): nginx-mod-http-perl-1.12.2-3.el7.x86_64.rpm                                                          |  36 kB  00:00:00     
    (9/10): nginx-mod-http-image-filter-1.12.2-3.el7.x86_64.rpm                                                  |  27 kB  00:00:00     
    (10/10): nginx-mod-stream-1.12.2-3.el7.x86_64.rpm                                                            |  76 kB  00:00:00     
    ------------------------------------------------------------------------------------------------------------------------------------
    Total                                                                                               203 kB/s | 1.1 MB  00:00:05     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
    Warning: RPMDB altered outside of yum.
      Installing : 1:nginx-filesystem-1.12.2-3.el7.noarch                                                                          1/10 
      Installing : gperftools-libs-2.6.1-1.el7.x86_64                                                                              2/10 
      Installing : 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64                                                                3/10 
      Installing : 1:nginx-mod-http-perl-1.12.2-3.el7.x86_64                                                                       4/10 
      Installing : 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64                                                               5/10 
      Installing : 1:nginx-mod-mail-1.12.2-3.el7.x86_64                                                                            6/10 
      Installing : 1:nginx-mod-stream-1.12.2-3.el7.x86_64                                                                          7/10 
      Installing : 1:nginx-mod-http-geoip-1.12.2-3.el7.x86_64                                                                      8/10 
      Installing : 1:nginx-all-modules-1.12.2-3.el7.noarch                                                                         9/10 
      Installing : 1:nginx-1.12.2-3.el7.x86_64                                                                                    10/10 
      Verifying  : 1:nginx-all-modules-1.12.2-3.el7.noarch                                                                         1/10 
      Verifying  : 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64                                                                2/10 
      Verifying  : 1:nginx-mod-http-perl-1.12.2-3.el7.x86_64                                                                       3/10 
      Verifying  : 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64                                                               4/10 
      Verifying  : gperftools-libs-2.6.1-1.el7.x86_64                                                                              5/10 
      Verifying  : 1:nginx-1.12.2-3.el7.x86_64                                                                                     6/10 
      Verifying  : 1:nginx-filesystem-1.12.2-3.el7.noarch                                                                          7/10 
      Verifying  : 1:nginx-mod-mail-1.12.2-3.el7.x86_64                                                                            8/10 
      Verifying  : 1:nginx-mod-stream-1.12.2-3.el7.x86_64                                                                          9/10 
      Verifying  : 1:nginx-mod-http-geoip-1.12.2-3.el7.x86_64                                                                     10/10 

    Installed:
      nginx.x86_64 1:1.12.2-3.el7                                                                                                       

    Dependency Installed:
      gperftools-libs.x86_64 0:2.6.1-1.el7                                 nginx-all-modules.noarch 1:1.12.2-3.el7                      
      nginx-filesystem.noarch 1:1.12.2-3.el7                               nginx-mod-http-geoip.x86_64 1:1.12.2-3.el7                   
      nginx-mod-http-image-filter.x86_64 1:1.12.2-3.el7                    nginx-mod-http-perl.x86_64 1:1.12.2-3.el7                    
      nginx-mod-http-xslt-filter.x86_64 1:1.12.2-3.el7                     nginx-mod-mail.x86_64 1:1.12.2-3.el7                         
      nginx-mod-stream.x86_64 1:1.12.2-3.el7                              

    Complete!
    
    
查看nginx版本信息::

    [root@client ~]# nginx -v
    nginx version: nginx/1.12.2
    [root@client ~]# nginx -V
    nginx version: nginx/1.12.2
    built by gcc 4.8.5 20150623 (Red Hat 4.8.5-36) (GCC) 
    built with OpenSSL 1.0.2k-fips  26 Jan 2017
    TLS SNI support enabled
    configure arguments: --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-file-aio --with-ipv6 --with-http_auth_request_module --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream=dynamic --with-stream_ssl_module --with-google_perftools_module --with-debug --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E'
    [root@client ~]# 

- 确认一下 ``nginx`` 安装时已编译 ``http_ssl`` 模块，也就是执行 ``nginx -V`` 命令查看是否存在 ``--with-http_ssl_module`` 。一般都会有的，如果没有，则需要重新编译nginx将该模块加入。


查看nginx.conf配置文件的原始内容::

    [root@client ~]# cat -n /etc/nginx/nginx.conf
         1  # For more information on configuration, see:
         2  #   * Official English Documentation: http://nginx.org/en/docs/
         3  #   * Official Russian Documentation: http://nginx.org/ru/docs/
         4
         5  user nginx;
         6  worker_processes auto;
         7  error_log /var/log/nginx/error.log;
         8  pid /run/nginx.pid;
         9
        10  # Load dynamic modules. See /usr/share/nginx/README.dynamic.
        11  include /usr/share/nginx/modules/*.conf;
        12
        13  events {
        14      worker_connections 1024;
        15  }
        16
        17  http {
        18      log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
        19                        '$status $body_bytes_sent "$http_referer" '
        20                        '"$http_user_agent" "$http_x_forwarded_for"';
        21
        22      access_log  /var/log/nginx/access.log  main;
        23
        24      sendfile            on;
        25      tcp_nopush          on;
        26      tcp_nodelay         on;
        27      keepalive_timeout   65;
        28      types_hash_max_size 2048;
        29
        30      include             /etc/nginx/mime.types;
        31      default_type        application/octet-stream;
        32
        33      # Load modular configuration files from the /etc/nginx/conf.d directory.
        34      # See http://nginx.org/en/docs/ngx_core_module.html#include
        35      # for more information.
        36      include /etc/nginx/conf.d/*.conf;
        37
        38      server {
        39          listen       80 default_server;
        40          listen       [::]:80 default_server;
        41          server_name  _;
        42          root         /usr/share/nginx/html;
        43
        44          # Load configuration files for the default server block.
        45          include /etc/nginx/default.d/*.conf;
        46
        47          location / {
        48          }
        49
        50          error_page 404 /404.html;
        51              location = /40x.html {
        52          }
        53
        54          error_page 500 502 503 504 /50x.html;
        55              location = /50x.html {
        56          }
        57      }
        58
        59  # Settings for a TLS enabled server.
        60  #
        61  #    server {
        62  #        listen       443 ssl http2 default_server;
        63  #        listen       [::]:443 ssl http2 default_server;
        64  #        server_name  _;
        65  #        root         /usr/share/nginx/html;
        66  #
        67  #        ssl_certificate "/etc/pki/nginx/server.crt";
        68  #        ssl_certificate_key "/etc/pki/nginx/private/server.key";
        69  #        ssl_session_cache shared:SSL:1m;
        70  #        ssl_session_timeout  10m;
        71  #        ssl_ciphers HIGH:!aNULL:!MD5;
        72  #        ssl_prefer_server_ciphers on;
        73  #
        74  #        # Load configuration files for the default server block.
        75  #        include /etc/nginx/default.d/*.conf;
        76  #
        77  #        location / {
        78  #        }
        79  #
        80  #        error_page 404 /404.html;
        81  #            location = /40x.html {
        82  #        }
        83  #
        84  #        error_page 500 502 503 504 /50x.html;
        85  #            location = /50x.html {
        86  #        }
        87  #    }
        88
        89  }
        90


可以看到nginx针对普通的80端口以及TLS加密服务的443端口已经给出了配置示例。

将nginx设置为开机启动，并启动nginx::

    [root@client ~]# systemctl enable nginx
    Created symlink from /etc/systemd/system/multi-user.target.wants/nginx.service to /usr/lib/systemd/system/nginx.service.
    [root@client ~]# systemctl start nginx
    [root@client ~]# systemctl status nginx
    ● nginx.service - The nginx HTTP and reverse proxy server
       Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
       Active: active (running) since Thu 2019-06-06 21:49:30 CST; 7s ago
      Process: 13765 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
      Process: 13763 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
      Process: 13761 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
     Main PID: 13767 (nginx)
        Tasks: 2
       Memory: 6.4M
       CGroup: /system.slice/nginx.service
               ├─13767 nginx: master process /usr/sbin/nginx
               └─13768 nginx: worker process

    Jun 06 21:49:29 client.hopewait systemd[1]: Starting The nginx HTTP and reverse proxy server...
    Jun 06 21:49:29 client.hopewait nginx[13763]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    Jun 06 21:49:29 client.hopewait nginx[13763]: nginx: configuration file /etc/nginx/nginx.conf test is successful
    Jun 06 21:49:30 client.hopewait systemd[1]: Failed to read PID from file /run/nginx.pid: Invalid argument
    Jun 06 21:49:30 client.hopewait systemd[1]: Started The nginx HTTP and reverse proxy server.
    [root@client ~]# 

查看nginx启动的端口，并检查防火墙是否开放该端口::

    [root@client ~]# netstat -tunlp|grep nginx
    tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      13767/nginx: master 
    tcp6       0      0 :::80                   :::*                    LISTEN      13767/nginx: master 
    [root@client ~]# firewall-cmd --list-all
    public (active)
      target: default
      icmp-block-inversion: no
      interfaces: enp0s3 enp0s8
      sources: 
      services: ssh dhcpv6-client
      ports: 8140/tcp 53/tcp 11211/tcp 80/tcp 443/tcp
      protocols: 
      masquerade: no
      forward-ports: 
      source-ports: 
      icmp-blocks: 
      rich rules: 
    [root@client ~]# 
    
可以看到nginx当前启动的是80端口，我们使用google浏览器打开 http://192.168.56.15/ 链接:

.. image:: ./_static/images/nginx_test.png

我们将CA证书应用到nginx中，修改nginx的配置文件 ``/etc/nginx/nginx.conf`` ， 将38-57行80端口部分注释掉，61-87行部分取消注释::

    [root@client ~]# cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
    [root@client ~]# sed  -i '38,57s/^/#/g' /etc/nginx/nginx.conf
    [root@client ~]# sed -i '60,87s/^#//g' /etc/nginx/nginx.conf 
    # 替换后文件内容如下
    
    [root@client ~]# cat -n /etc/nginx/nginx.conf|sed -n '38,90p'
        38  #    server {
        39  #        listen       80 default_server;
        40  #        listen       [::]:80 default_server;
        41  #        server_name  _;
        42  #        root         /usr/share/nginx/html;
        43  #
        44  #        # Load configuration files for the default server block.
        45  #        include /etc/nginx/default.d/*.conf;
        46  #
        47  #        location / {
        48  #        }
        49  #
        50  #        error_page 404 /404.html;
        51  #            location = /40x.html {
        52  #        }
        53  #
        54  #        error_page 500 502 503 504 /50x.html;
        55  #            location = /50x.html {
        56  #        }
        57  #    }
        58
        59  # Settings for a TLS enabled server.
        60
        61      server {
        62          listen       443 ssl http2 default_server;
        63          listen       [::]:443 ssl http2 default_server;
        64          server_name  _;
        65          root         /usr/share/nginx/html;
        66
        67          ssl_certificate "/etc/pki/nginx/server.crt";
        68          ssl_certificate_key "/etc/pki/nginx/private/server.key";
        69          ssl_session_cache shared:SSL:1m;
        70          ssl_session_timeout  10m;
        71          ssl_ciphers HIGH:!aNULL:!MD5;
        72          ssl_prefer_server_ciphers on;
        73
        74          # Load configuration files for the default server block.
        75          include /etc/nginx/default.d/*.conf;
        76
        77          location / {
        78          }
        79
        80          error_page 404 /404.html;
        81              location = /40x.html {
        82          }
        83
        84          error_page 500 502 503 504 /50x.html;
        85              location = /50x.html {
        86          }
        87      }
        88
        89  }
        90
    [root@client ~]# 

替换掉64行的server_name指定具体的IP地址192.168.56.15::

    [root@client ~]# sed -i '64s@server_name  _;@server_name 192.168.56.15;@g' /etc/nginx/nginx.conf

再把67-68两行替换成我们之前配置的CA认证文件以及自己的私钥地址::

    [root@client ~]# sed -i '67s@ssl_certificate "/etc/pki/nginx/server.crt"@ssl_certificate "/root/cafiles/server.crt"@g' /etc/nginx/nginx.conf
    [root@client ~]# sed -i '68s@ssl_certificate_key "/etc/pki/nginx/private/server.key"@ssl_certificate_key "/root/cafiles/server.key.unsecure"@g' /etc/nginx/nginx.conf

查看文件59-90行::

    [root@client ~]# cat -n /etc/nginx/nginx.conf|sed -n '59,90p'
        59  # Settings for a TLS enabled server.
        60
        61      server {
        62          listen       443 ssl http2 default_server;
        63          listen       [::]:443 ssl http2 default_server;
        64          server_name 192.168.56.15;
        65          root         /usr/share/nginx/html;
        66
        67          ssl_certificate "/root/cafiles/server.crt";
        68          ssl_certificate_key "/root/cafiles/server.key.unsecure";
        69          ssl_session_cache shared:SSL:1m;
        70          ssl_session_timeout  10m;
        71          ssl_ciphers HIGH:!aNULL:!MD5;
        72          ssl_prefer_server_ciphers on;
        73
        74          # Load configuration files for the default server block.
        75          include /etc/nginx/default.d/*.conf;
        76
        77          location / {
        78          }
        79
        80          error_page 404 /404.html;
        81              location = /40x.html {
        82          }
        83
        84          error_page 500 502 503 504 /50x.html;
        85              location = /50x.html {
        86          }
        87      }
        88
        89  }
        90

重启nginx服务，发现启动不了::


    [root@client ~]# systemctl start nginx
    Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
    [root@client ~]# systemctl status nginx
    ● nginx.service - The nginx HTTP and reverse proxy server
       Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
       Active: failed (Result: exit-code) since Thu 2019-06-06 22:23:10 CST; 8s ago
      Process: 13765 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
      Process: 13943 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
      Process: 13942 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
     Main PID: 13767 (code=exited, status=0/SUCCESS)
    
    Jun 06 22:23:10 client.hopewait systemd[1]: Starting The nginx HTTP and reverse proxy server...
    Jun 06 22:23:10 client.hopewait nginx[13943]: nginx: [emerg] BIO_new_file("/root/cafiles/server.crt") failed (SSL: error:02...m lib)
    Jun 06 22:23:10 client.hopewait nginx[13943]: nginx: configuration file /etc/nginx/nginx.conf test failed
    Jun 06 22:23:10 client.hopewait systemd[1]: nginx.service: control process exited, code=exited status=1
    Jun 06 22:23:10 client.hopewait systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    Jun 06 22:23:10 client.hopewait systemd[1]: Unit nginx.service entered failed state.
    Jun 06 22:23:10 client.hopewait systemd[1]: nginx.service failed.
    Hint: Some lines were ellipsized, use -l to show in full.
    [root@client ~]# systemctl status nginx -l
    ● nginx.service - The nginx HTTP and reverse proxy server
       Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
       Active: failed (Result: exit-code) since Thu 2019-06-06 22:23:10 CST; 30s ago
      Process: 13765 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
      Process: 13943 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
      Process: 13942 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
     Main PID: 13767 (code=exited, status=0/SUCCESS)
    
    Jun 06 22:23:10 client.hopewait systemd[1]: Starting The nginx HTTP and reverse proxy server...
    Jun 06 22:23:10 client.hopewait nginx[13943]: nginx: [emerg] BIO_new_file("/root/cafiles/server.crt") failed (SSL: error:0200100D:system library:fopen:Permission denied:fopen('/root/cafiles/server.crt','r') error:2006D002:BIO routines:BIO_new_file:system lib)
    Jun 06 22:23:10 client.hopewait nginx[13943]: nginx: configuration file /etc/nginx/nginx.conf test failed
    Jun 06 22:23:10 client.hopewait systemd[1]: nginx.service: control process exited, code=exited status=1
    Jun 06 22:23:10 client.hopewait systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    Jun 06 22:23:10 client.hopewait systemd[1]: Unit nginx.service entered failed state.
    Jun 06 22:23:10 client.hopewait systemd[1]: nginx.service failed.


后又将nginx.conf中证书配置处还原初始状态，并复制证书和私钥到相应的位置::

    [root@client ~]# cat -n /etc/nginx/nginx.conf|sed -n '59,90p'
        59  # Settings for a TLS enabled server.
        60
        61      server {
        62          listen       443 ssl http2 default_server;
        63          listen       [::]:443 ssl http2 default_server;
        64          server_name  192.168.56.15;
        65          root         /usr/share/nginx/html;
        66
        67          ssl_certificate "/etc/pki/nginx/server.crt";
        68          ssl_certificate_key "/etc/pki/nginx/private/server.key";
        69          ssl_session_cache shared:SSL:1m;
        70          ssl_session_timeout  10m;
        71          ssl_ciphers HIGH:!aNULL:!MD5;
        72          ssl_prefer_server_ciphers on;
        73
        74          # Load configuration files for the default server block.
        75          include /etc/nginx/default.d/*.conf;
        76
        77          location / {
        78          }
        79
        80          error_page 404 /404.html;
        81              location = /40x.html {
        82          }
        83
        84          error_page 500 502 503 504 /50x.html;
        85              location = /50x.html {
        86          }
        87      }
        88
        89  }
        90
    [root@client ~]# 

.. Attention:: 如果不进行复制，nginx读取不到/root/cafiles/目录中的文件，则无法启动nginx服务。


复制证书文件到/etc/pki/nginx目录下，复制私钥到/etc/pki/nginx/private目录下::

    [root@client ~]# mkdir -p /etc/pki/nginx/private
    [root@client ~]# cp cafiles/server.crt /etc/pki/nginx/server.crt
    [root@client ~]# cp cafiles/server.key.unsecure  /etc/pki/nginx/private/server.key
    [root@client ~]# ls -lah /etc/pki/nginx/
    total 12K
    drwxr-xr-x.  3 root root   57 Jun  6 22:30 .
    drwxr-xr-x. 11 root root  129 Jun  6 22:29 ..
    drwxr-xr-x.  2 root root   24 Jun  6 22:31 private
    -rw-r--r--.  1 root root 4.6K Jun  6 22:30 server.crt
    [root@client ~]# ls -lah /etc/pki/nginx/private/server.key 
    -rw-r--r--. 1 root root 1.7K Jun  6 22:31 /etc/pki/nginx/private/server.key

使用 ``nginx -t`` 检查一下nginx配置文件是否配置有误::

    [root@client ~]# nginx -t
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful
    
语法正确，启动nginx，发现可以正常启动::

    [root@client ~]# systemctl start nginx
    [root@client ~]# netstat -tunlp|grep nginx
    tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN      14060/nginx: master 
    tcp6       0      0 :::443                  :::*                    LISTEN      14060/nginx: master 
    [root@client ~]# ps -ef|grep nginx
    root     14060     1  0 22:35 ?        00:00:00 nginx: master process /usr/sbin/nginx
    nginx    14061 14060  0 22:35 ?        00:00:00 nginx: worker process
    root     14066 11535  0 22:35 pts/0    00:00:00 grep --color=auto nginx

使用google浏览器打开 https://192.168.56.15/ 链接:

.. image:: ./_static/images/nginx_https_test.png

nginx 80端口转443端口
------------------------------------

重新修改nginx配置文件80端口部分::

    [root@client ~]# cat -n /etc/nginx/nginx.conf|sed -n '38,90p'
        38      server {
        39          listen       80;
        40  #        listen       [::]:80 default_server;
        41          server_name  192.168.56.15;
        42          rewrite ^(.*)$ https://${server_name}$1 permanent;      # <--说明:  此处进行端口转发
        43  #        root         /usr/share/nginx/html;
        44  #
        45  #        # Load configuration files for the default server block.
        46  #        include /etc/nginx/default.d/*.conf;
        47  #
        48  #        location / {
        49  #        }
        50  #
        51  #        error_page 404 /404.html;
        52  #            location = /40x.html {
        53  #        }
        54  #
        55  #        error_page 500 502 503 504 /50x.html;
        56  #            location = /50x.html {
        57  #        }
        58      }
        59
        60  # Settings for a TLS enabled server.
        61
        62      server {
        63          listen       443 ssl http2 default_server;
        64          listen       [::]:443 ssl http2 default_server;
        65          server_name 192.168.56.15;
        66          root         /usr/share/nginx/html;
        67
        68          ssl_certificate "/etc/pki/nginx/server.crt";
        69          ssl_certificate_key "/etc/pki/nginx/private/server.key";
        70          ssl_session_cache shared:SSL:1m;
        71          ssl_session_timeout  10m;
        72          ssl_ciphers HIGH:!aNULL:!MD5;
        73          ssl_prefer_server_ciphers on;
        74
        75          # Load configuration files for the default server block.
        76          include /etc/nginx/default.d/*.conf;
        77
        78          location / {
        79          }
        80
        81          error_page 404 /404.html;
        82              location = /40x.html {
        83          }
        84
        85          error_page 500 502 503 504 /50x.html;
        86              location = /50x.html {
        87          }
        88      }
        89
        90  }
    [root@client ~]# 

- 使用 ``rewrite ^(.*)$ https://${server_name}$1 permanent;`` 进行端口转发。

使用google浏览器打开 http://192.168.56.15/ 链接时，会自动跳转到  https://192.168.56.15/ 链接:

.. image:: ./_static/images/nginx_80_2_443.png

打开F12调试Network可以看到返回301重定向。

httpd 80端口转443端口
------------------------------------

首先使用 ``systemctl stop nginx`` 停止nginx服务。

在 ``/etc/httpd/conf.d/`` 目录下新增 ``http2https.conf`` 配置文件，配置文件内容如下::

    [root@client ~]# cat -n /etc/httpd/conf.d/http2https.conf 
         1  <VirtualHost *:80>
         2      ServerName 192.168.56.15
         3      RewriteEngine on
         4      RewriteCond %{SERVER_PORT} !^443$
         5      RewriteRule ^/?(.*)$ https://%{SERVER_NAME}/$1 [L,R]
         6  </VirtualHost>                                  
         7
    [root@client ~]# 

使用 ``systemctl start httpd`` 启动httpd web服务，则可以看到Apache的测试页。


自签名证书
--------------------------------------

以上证书的使用都是使用CA中心颁发的证书，使用两台服务器进行测试的。

下面我们仅在client服务器上面使用OpenSSL配置自签名证书，不需要CA中心，来达到https加密服务。自签名证书，用于自己测试，不需要CA签发。

先停止httpd服务::

    [root@client ~]# systemctl stop httpd
    [root@client ~]# ps -ef|grep httpd
    root     15656 14955  0 20:51 pts/0    00:00:00 grep --color=auto httpd

生成密钥和证书文件::

    [root@client ~]# openssl req -x509 -nodes -days 1095 -newkey rsa:2048 -keyout /etc/httpd/conf.d/self_ca.key -out /etc/httpd/conf.d/self_ca.crt
    Generating a 2048 bit RSA private key
    .........+++
    ..+++
    writing new private key to '/etc/httpd/conf.d/self_ca.key'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [XX]:CN
    State or Province Name (full name) []:hubei
    Locality Name (eg, city) [Default City]:wuhan
    Organization Name (eg, company) [Default Company Ltd]:IT
    Organizational Unit Name (eg, section) []:hopewait
    Common Name (eg, your name or your server's hostname) []:192.168.56.15
    Email Address []:mzh.whut@gmail.com
    [root@client ~]# ls -lah /etc/httpd/conf.d/self_ca*
    -rw-r--r-- 1 root root 1.4K Jun 13 20:59 /etc/httpd/conf.d/self_ca.crt
    -rw-r--r-- 1 root root 1.7K Jun 13 20:59 /etc/httpd/conf.d/self_ca.key
    [root@client ~]# 


.. Attention::
    参数说明：
    
    
    
    -key    指定已有的秘钥文件生成秘钥请求，只与生成证书请求选项-new配合
    
    -xfivezeronine   -x509 说明生成自签名证
    
    -newkey  -newkey是与-key互斥的，-newkey是指在生成证书请求或者自签名证书的时候自动生成密钥，生成的密钥名称由-keyout参数指定。当指定newkey选项时，后面指定rsa:bits说明产生rsa密钥，位数由bits指定。如果没有指定选项-key和-newkey，默认自动生成秘钥
    
    -out    指定生成的证书请求或者自签名证书名称
    
    -nodes  如果指定-newkey自动生成秘钥，那么-nodes选项说明生成的秘钥不需要加密，即不需要输入passphase 
    
    -days  -days n 指定自签名证书的有效期限。默认为30天
          
修改Apache的配置文件 ``/etc/httpd/conf.d/ssl.conf`` 的证书文件和密钥文件路径::

    [root@client ~]# cat -n /etc/httpd/conf.d/ssl.conf|sed -n '95,108p'
        95  #   Server Certificate:
        96  # Point SSLCertificateFile at a PEM encoded certificate.  If
        97  # the certificate is encrypted, then you will be prompted for a
        98  # pass phrase.  Note that a kill -HUP will prompt again.  A new
        99  # certificate can be generated using the genkey(1) command.
       100  SSLCertificateFile /etc/httpd/conf.d/self_ca.crt        <-- 说明：证书文件路径
       101
       102  #   Server Private Key:
       103  #   If the key is not combined with the certificate, use this
       104  #   directive to point at the key file.  Keep in mind that if
       105  #   you've both a RSA and a DSA private key you can configure
       106  #   both in parallel (to also allow the use of DSA ciphers, etc.)
       107  SSLCertificateKeyFile /etc/httpd/conf.d/self_ca.key       <-- 说明：密钥文件路径
       108
    [root@client ~]# 

重启httpd服务::

    [root@client ~]# httpd -t
    Syntax OK
    [root@client ~]# systemctl start httpd
    [root@client ~]# 

使用google浏览器打开 http://192.168.56.15/ 链接时，会自动跳转到  https://192.168.56.15/ 链接，此时查看证书的详情:

.. image:: ./_static/images/self_ca.png

可以看到证书的颁发者和使用者都是192.168.56.15，有效期三年，也就是我们刚才的配置的自签名证书呢。

无论是通过配置OpenSSL配置CA中心颁发签名证书还是自签名证书，浏览器都认为证书是 **不安全** 的，推荐使用权威CA中心签发的证书。


如果自己有域名并解析到云服务器上，可以使用 ``Let’s Encrypt`` CA中心颁发的证书来构建https服务。可参考 https://letsencrypt.org/zh-cn/getting-started/ 和 https://certbot.eff.org/docs/using.html#where-are-my-certificates 。

使用Let’s Encrypt颁发证书
--------------------------------------


什么是Let’s Encrypt
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. image:: ./_static/images/LetsEncrypt.jpg

`Let's Encrypt <https://letsencrypt.org/>`_ 是一个由非营利性组织 互联网安全研究小组（ISRG）提供的免费、自动化和开放的证书颁发机构（CA）。

简单的说，借助 Let's Encrypt 颁发的证书可以为我们的网站免费启用 ``HTTPS(SSL/TLS)`` 。

Let's Encrypt免费证书的签发/续签都是脚本自动化的，官方提供了几种证书的申请方式方法， `点击此处 <https://letsencrypt.org/docs/client-options/>`_ 快速浏览。官方推荐使用 `Certbot <https://certbot.eff.org/lets-encrypt/centosrhel7-apache>`_ 客户端来签发证书。

Let's Encrypt免费证书默认是90天有效期，后面我们需要设置自动续签证书。

下载Let's Encrypt脚本文件::

    [root@hopewait ~]# git clone https://github.com/letsencrypt/letsencrypt
    Cloning into 'letsencrypt'...
    remote: Enumerating objects: 98, done.
    remote: Counting objects: 100% (98/98), done.
    remote: Compressing objects: 100% (72/72), done.
    remote: Total 66231 (delta 52), reused 63 (delta 26), pack-reused 66133
    Receiving objects: 100% (66231/66231), 21.66 MiB | 21.38 MiB/s, done.
    Resolving deltas: 100% (48443/48443), done.
    
    或者：git clone https://github.com/certbot/certbot.git 
    
查看letsencrypt的版本::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto --version
    certbot 0.35.1

获取帮助信息(帮助信息很长，可以将其重写向到文件中)::


    [root@hopewait ~]# /root/letsencrypt/certbot-auto --help all
        usage: 
          certbot-auto [SUBCOMMAND] [options] [-d DOMAIN] [-d DOMAIN] ...

        Certbot can obtain and install HTTPS/TLS/SSL certificates.  By default,
        it will attempt to use a webserver both for obtaining and installing the
        certificate. The most common SUBCOMMANDS and flags are:

        obtain, install, and renew certificates:
            (default) run   Obtain & install a certificate in your current webserver
            certonly        Obtain or renew a certificate, but do not install it
            renew           Renew all previously obtained certificates that are near expiry
            enhance         Add security enhancements to your existing configuration
           -d DOMAINS       Comma-separated list of domains to obtain a certificate for

          --apache          Use the Apache plugin for authentication & installation
          --standalone      Run a standalone webserver for authentication
          --nginx           Use the Nginx plugin for authentication & installation
          --webroot         Place files in a server's webroot folder for authentication
          --manual          Obtain certificates interactively, or using shell script hooks

           -n               Run non-interactively
          --test-cert       Obtain a test certificate from a staging server
          --dry-run         Test "renew" or "certonly" without saving any certificates to disk

        manage certificates:
            certificates    Display information about certificates you have from Certbot
            revoke          Revoke a certificate (supply --cert-path or --cert-name)
            delete          Delete a certificate

        manage your account with Let's Encrypt:
            register        Create a Let's Encrypt ACME account
            unregister      Deactivate a Let's Encrypt ACME account
            update_account  Update a Let's Encrypt ACME account
          --agree-tos       Agree to the ACME server's Subscriber Agreement
           -m EMAIL         Email address for important account notifications

        optional arguments:
          -h, --help            show this help message and exit
          -c CONFIG_FILE, --config CONFIG_FILE
                                path to config file (default: /etc/letsencrypt/cli.ini
                                and ~/.config/letsencrypt/cli.ini)
          -v, --verbose         This flag can be used multiple times to incrementally
                                increase the verbosity of output, e.g. -vvv. (default:
                                -2)
          --max-log-backups MAX_LOG_BACKUPS
                                Specifies the maximum number of backup logs that
                                should be kept by Certbot's built in log rotation.
                                Setting this flag to 0 disables log rotation entirely,
                                causing Certbot to always append to the same log file.
                                (default: 1000)
          -n, --non-interactive, --noninteractive
                                Run without ever asking for user input. This may
                                require additional command line flags; the client will
                                try to explain which ones are required if it finds one
                                missing (default: False)
          --force-interactive   Force Certbot to be interactive even if it detects
                                it's not being run in a terminal. This flag cannot be
                                used with the renew subcommand. (default: False)
          -d DOMAIN, --domains DOMAIN, --domain DOMAIN
                                Domain names to apply. For multiple domains you can
                                use multiple -d flags or enter a comma separated list
                                of domains as a parameter. The first domain provided
                                will be the subject CN of the certificate, and all
                                domains will be Subject Alternative Names on the
                                certificate. The first domain will also be used in
                                some software user interfaces and as the file paths
                                for the certificate and related material unless
                                otherwise specified or you already have a certificate
                                with the same name. In the case of a name collision it
                                will append a number like 0001 to the file path name.
                                (default: Ask)
          --eab-kid EAB_KID     Key Identifier for External Account Binding (default:
                                None)
          --eab-hmac-key EAB_HMAC_KEY
                                HMAC key for External Account Binding (default: None)
          --cert-name CERTNAME  Certificate name to apply. This name is used by
                                Certbot for housekeeping and in file paths; it doesn't
                                affect the content of the certificate itself. To see
                                certificate names, run 'certbot certificates'. When
                                creating a new certificate, specifies the new
                                certificate's name. (default: the first provided
                                domain or the name of an existing certificate on your
                                system for the same domains)
          --dry-run             Perform a test run of the client, obtaining test
                                (invalid) certificates but not saving them to disk.
                                This can currently only be used with the 'certonly'
                                and 'renew' subcommands. Note: Although --dry-run
                                tries to avoid making any persistent changes on a
                                system, it is not completely side-effect free: if used
                                with webserver authenticator plugins like apache and
                                nginx, it makes and then reverts temporary config
                                changes in order to obtain test certificates, and
                                reloads webservers to deploy and then roll back those
                                changes. It also calls --pre-hook and --post-hook
                                commands if they are defined because they may be
                                necessary to accurately simulate renewal. --deploy-
                                hook commands are not called. (default: False)
          --debug-challenges    After setting up challenges, wait for user input
                                before submitting to CA (default: False)
          --preferred-challenges PREF_CHALLS
                                A sorted, comma delimited list of the preferred
                                challenge to use during authorization with the most
                                preferred challenge listed first (Eg, "dns" or
                                "http,dns"). Not all plugins support all challenges.
                                See https://certbot.eff.org/docs/using.html#plugins
                                for details. ACME Challenges are versioned, but if you
                                pick "http" rather than "http-01", Certbot will select
                                the latest version automatically. (default: [])
          --user-agent USER_AGENT
                                Set a custom user agent string for the client. User
                                agent strings allow the CA to collect high level
                                statistics about success rates by OS, plugin and use
                                case, and to know when to deprecate support for past
                                Python versions and flags. If you wish to hide this
                                information from the Let's Encrypt server, set this to
                                "". (default: CertbotACMEClient/0.35.1 (certbot-auto;
                                CentOS Linux 7 (Core)) Authenticator/XXX Installer/YYY
                                (SUBCOMMAND; flags: FLAGS) Py/2.7.5). The flags
                                encoded in the user agent are: --duplicate, --force-
                                renew, --allow-subset-of-names, -n, and whether any
                                hooks are set.
          --user-agent-comment USER_AGENT_COMMENT
                                Add a comment to the default user agent string. May be
                                used when repackaging Certbot or calling it from
                                another tool to allow additional statistical data to
                                be collected. Ignored if --user-agent is set.
                                (Example: Foo-Wrapper/1.0) (default: None)

        automation:
          Flags for automating execution & other tweaks

          --keep-until-expiring, --keep, --reinstall
                                If the requested certificate matches an existing
                                certificate, always keep the existing one until it is
                                due for renewal (for the 'run' subcommand this means
                                reinstall the existing certificate). (default: Ask)
          --expand              If an existing certificate is a strict subset of the
                                requested names, always expand and replace it with the
                                additional names. (default: Ask)
          --version             show program's version number and exit
          --force-renewal, --renew-by-default
                                If a certificate already exists for the requested
                                domains, renew it now, regardless of whether it is
                                near expiry. (Often --keep-until-expiring is more
                                appropriate). Also implies --expand. (default: False)
          --renew-with-new-domains
                                If a certificate already exists for the requested
                                certificate name but does not match the requested
                                domains, renew it now, regardless of whether it is
                                near expiry. (default: False)
          --reuse-key           When renewing, use the same private key as the
                                existing certificate. (default: False)
          --allow-subset-of-names
                                When performing domain validation, do not consider it
                                a failure if authorizations can not be obtained for a
                                strict subset of the requested domains. This may be
                                useful for allowing renewals for multiple domains to
                                succeed even if some domains no longer point at this
                                system. This option cannot be used with --csr.
                                (default: False)
          --agree-tos           Agree to the ACME Subscriber Agreement (default: Ask)
          --duplicate           Allow making a certificate lineage that duplicates an
                                existing one (both can be renewed in parallel)
                                (default: False)
          --os-packages-only    (certbot-auto only) install OS package dependencies
                                and then stop (default: False)
          --no-self-upgrade     (certbot-auto only) prevent the certbot-auto script
                                from upgrading itself to newer released versions
                                (default: Upgrade automatically)
          --no-bootstrap        (certbot-auto only) prevent the certbot-auto script
                                from installing OS-level dependencies (default: Prompt
                                to install OS-wide dependencies, but exit if the user
                                says 'No')
          --no-permissions-check
                                (certbot-auto only) skip the check on the file system
                                permissions of the certbot-auto script (default:
                                False)
          -q, --quiet           Silence all output except errors. Useful for
                                automation via cron. Implies --non-interactive.
                                (default: False)

        security:
          Security parameters & server settings

          --rsa-key-size N      Size of the RSA key. (default: 2048)
          --must-staple         Adds the OCSP Must Staple extension to the
                                certificate. Autoconfigures OCSP Stapling for
                                supported setups (Apache version >= 2.3.3 ). (default:
                                False)
          --redirect            Automatically redirect all HTTP traffic to HTTPS for
                                the newly authenticated vhost. (default: Ask)
          --no-redirect         Do not automatically redirect all HTTP traffic to
                                HTTPS for the newly authenticated vhost. (default:
                                Ask)
          --hsts                Add the Strict-Transport-Security header to every HTTP
                                response. Forcing browser to always use SSL for the
                                domain. Defends against SSL Stripping. (default: None)
          --uir                 Add the "Content-Security-Policy: upgrade-insecure-
                                requests" header to every HTTP response. Forcing the
                                browser to use https:// for every http:// resource.
                                (default: None)
          --staple-ocsp         Enables OCSP Stapling. A valid OCSP response is
                                stapled to the certificate that the server offers
                                during TLS. (default: None)
          --strict-permissions  Require that all configuration files are owned by the
                                current user; only needed if your config is somewhere
                                unsafe like /tmp/ (default: False)
          --auto-hsts           Gradually increasing max-age value for HTTP Strict
                                Transport Security security header (default: False)

        testing:
          The following flags are meant for testing and integration purposes only.

          --test-cert, --staging
                                Use the staging server to obtain or revoke test
                                (invalid) certificates; equivalent to --server https
                                ://acme-staging-v02.api.letsencrypt.org/directory
                                (default: False)
          --debug               Show tracebacks in case of errors, and allow certbot-
                                auto execution on experimental platforms (default:
                                False)
          --no-verify-ssl       Disable verification of the ACME server's certificate.
                                (default: False)
          --http-01-port HTTP01_PORT
                                Port used in the http-01 challenge. This only affects
                                the port Certbot listens on. A conforming ACME server
                                will still attempt to connect on port 80. (default:
                                80)
          --http-01-address HTTP01_ADDRESS
                                The address the server listens to during http-01
                                challenge. (default: )
          --https-port HTTPS_PORT
                                Port used to serve HTTPS. This affects which port
                                Nginx will listen on after a LE certificate is
                                installed. (default: 443)
          --break-my-certs      Be willing to replace or renew valid certificates with
                                invalid (testing/staging) certificates (default:
                                False)

        paths:
          Flags for changing execution paths & servers

          --cert-path CERT_PATH
                                Path to where certificate is saved (with auth --csr),
                                installed from, or revoked. (default: None)
          --key-path KEY_PATH   Path to private key for certificate installation or
                                revocation (if account key is missing) (default: None)
          --fullchain-path FULLCHAIN_PATH
                                Accompanying path to a full certificate chain
                                (certificate plus chain). (default: None)
          --chain-path CHAIN_PATH
                                Accompanying path to a certificate chain. (default:
                                None)
          --config-dir CONFIG_DIR
                                Configuration directory. (default: /etc/letsencrypt)
          --work-dir WORK_DIR   Working directory. (default: /var/lib/letsencrypt)
          --logs-dir LOGS_DIR   Logs directory. (default: /var/log/letsencrypt)
          --server SERVER       ACME Directory Resource URI. (default:
                                https://acme-v02.api.letsencrypt.org/directory)

        manage:
          Various subcommands and flags are available for managing your
          certificates:

          certificates          List certificates managed by Certbot
          delete                Clean up all files related to a certificate
          renew                 Renew all certificates (or one specified with --cert-
                                name)
          revoke                Revoke a certificate specified with --cert-path or
                                --cert-name
          update_symlinks       Recreate symlinks in your /etc/letsencrypt/live/
                                directory

        run:
          Options for obtaining & installing certificates

        certonly:
          Options for modifying how a certificate is obtained

          --csr CSR             Path to a Certificate Signing Request (CSR) in DER or
                                PEM format. Currently --csr only works with the
                                'certonly' subcommand. (default: None)

        renew:
          The 'renew' subcommand will attempt to renew all certificates (or more
          precisely, certificate lineages) you have previously obtained if they are
          close to expiry, and print a summary of the results. By default, 'renew'
          will reuse the options used to create obtain or most recently successfully
          renew each certificate lineage. You can try it with `--dry-run` first. For
          more fine-grained control, you can renew individual lineages with the
          `certonly` subcommand. Hooks are available to run commands before and
          after renewal; see https://certbot.eff.org/docs/using.html#renewal for
          more information on these.

          --pre-hook PRE_HOOK   Command to be run in a shell before obtaining any
                                certificates. Intended primarily for renewal, where it
                                can be used to temporarily shut down a webserver that
                                might conflict with the standalone plugin. This will
                                only be called if a certificate is actually to be
                                obtained/renewed. When renewing several certificates
                                that have identical pre-hooks, only the first will be
                                executed. (default: None)
          --post-hook POST_HOOK
                                Command to be run in a shell after attempting to
                                obtain/renew certificates. Can be used to deploy
                                renewed certificates, or to restart any servers that
                                were stopped by --pre-hook. This is only run if an
                                attempt was made to obtain/renew a certificate. If
                                multiple renewed certificates have identical post-
                                hooks, only one will be run. (default: None)
          --deploy-hook DEPLOY_HOOK
                                Command to be run in a shell once for each
                                successfully issued certificate. For this command, the
                                shell variable $RENEWED_LINEAGE will point to the
                                config live subdirectory (for example,
                                "/etc/letsencrypt/live/example.com") containing the
                                new certificates and keys; the shell variable
                                $RENEWED_DOMAINS will contain a space-delimited list
                                of renewed certificate domains (for example,
                                "example.com www.example.com" (default: None)
          --disable-hook-validation
                                Ordinarily the commands specified for --pre-hook
                                /--post-hook/--deploy-hook will be checked for
                                validity, to see if the programs being run are in the
                                $PATH, so that mistakes can be caught early, even when
                                the hooks aren't being run just yet. The validation is
                                rather simplistic and fails if you use more advanced
                                shell constructs, so you can use this switch to
                                disable it. (default: False)
          --no-directory-hooks  Disable running executables found in Certbot's hook
                                directories during renewal. (default: False)
          --disable-renew-updates
                                Disable automatic updates to your server configuration
                                that would otherwise be done by the selected installer
                                plugin, and triggered when the user executes "certbot
                                renew", regardless of if the certificate is renewed.
                                This setting does not apply to important TLS
                                configuration updates. (default: False)
          --no-autorenew        Disable auto renewal of certificates. (default: True)

        certificates:
          List certificates managed by Certbot

        delete:
          Options for deleting a certificate

        revoke:
          Options for revocation of certificates

          --reason {unspecified,keycompromise,affiliationchanged,superseded,cessationofoperation}
                                Specify reason for revoking certificate. (default:
                                unspecified)
          --delete-after-revoke
                                Delete certificates after revoking them, along with
                                all previous and later versions of those certificates.
                                (default: None)
          --no-delete-after-revoke
                                Do not delete certificates after revoking them. This
                                option should be used with caution because the 'renew'
                                subcommand will attempt to renew undeleted revoked
                                certificates. (default: None)

        register:
          Options for account registration

          --register-unsafely-without-email
                                Specifying this flag enables registering an account
                                with no email address. This is strongly discouraged,
                                because in the event of key loss or account compromise
                                you will irrevocably lose access to your account. You
                                will also be unable to receive notice about impending
                                expiration or revocation of your certificates. Updates
                                to the Subscriber Agreement will still affect you, and
                                will be effective 14 days after posting an update to
                                the web site. (default: False)
          -m EMAIL, --email EMAIL
                                Email used for registration and recovery contact. Use
                                comma to register multiple emails, ex:
                                u1@example.com,u2@example.com. (default: Ask).
          --eff-email           Share your e-mail address with EFF (default: None)
          --no-eff-email        Don't share your e-mail address with EFF (default:
                                None)

        update_account:
          Options for account modification

        unregister:
          Options for account deactivation.

          --account ACCOUNT_ID  Account ID to use (default: None)

        install:
          Options for modifying how a certificate is deployed

        config_changes:
          Options for controlling which changes are displayed

          --num NUM             How many past revisions you want to be displayed
                                (default: None)

        rollback:
          Options for rolling back server configuration changes

          --checkpoints N       Revert configuration N number of checkpoints.
                                (default: 1)

        plugins:
          Options for for the "plugins" subcommand

          --init                Initialize plugins. (default: False)
          --prepare             Initialize and prepare plugins. (default: False)
          --authenticators      Limit to authenticator plugins only. (default: None)
          --installers          Limit to installer plugins only. (default: None)

        update_symlinks:
          Recreates certificate and key symlinks in /etc/letsencrypt/live, if you
          changed them by hand or edited a renewal configuration file

        enhance:
          Helps to harden the TLS configuration by adding security enhancements to
          already existing configuration.

        plugins:
          Plugin Selection: Certbot client supports an extensible plugins
          architecture. See 'certbot plugins' for a list of all installed plugins
          and their names. You can force a particular plugin by setting options
          provided below. Running --help <plugin_name> will list flags specific to
          that plugin.

          --configurator CONFIGURATOR
                                Name of the plugin that is both an authenticator and
                                an installer. Should not be used together with
                                --authenticator or --installer. (default: Ask)
          -a AUTHENTICATOR, --authenticator AUTHENTICATOR
                                Authenticator plugin name. (default: None)
          -i INSTALLER, --installer INSTALLER
                                Installer plugin name (also used to find domains).
                                (default: None)
          --apache              Obtain and install certificates using Apache (default:
                                False)
          --nginx               Obtain and install certificates using Nginx (default:
                                False)
          --standalone          Obtain certificates using a "standalone" webserver.
                                (default: False)
          --manual              Provide laborious manual instructions for obtaining a
                                certificate (default: False)
          --webroot             Obtain certificates by placing files in a webroot
                                directory. (default: False)
          --dns-cloudflare      Obtain certificates using a DNS TXT record (if you are
                                using Cloudflare for DNS). (default: False)
          --dns-cloudxns        Obtain certificates using a DNS TXT record (if you are
                                using CloudXNS for DNS). (default: False)
          --dns-digitalocean    Obtain certificates using a DNS TXT record (if you are
                                using DigitalOcean for DNS). (default: False)
          --dns-dnsimple        Obtain certificates using a DNS TXT record (if you are
                                using DNSimple for DNS). (default: False)
          --dns-dnsmadeeasy     Obtain certificates using a DNS TXT record (if you are
                                using DNS Made Easy for DNS). (default: False)
          --dns-gehirn          Obtain certificates using a DNS TXT record (if you are
                                using Gehirn Infrastracture Service for DNS).
                                (default: False)
          --dns-google          Obtain certificates using a DNS TXT record (if you are
                                using Google Cloud DNS). (default: False)
          --dns-linode          Obtain certificates using a DNS TXT record (if you are
                                using Linode for DNS). (default: False)
          --dns-luadns          Obtain certificates using a DNS TXT record (if you are
                                using LuaDNS for DNS). (default: False)
          --dns-nsone           Obtain certificates using a DNS TXT record (if you are
                                using NS1 for DNS). (default: False)
          --dns-ovh             Obtain certificates using a DNS TXT record (if you are
                                using OVH for DNS). (default: False)
          --dns-rfc2136         Obtain certificates using a DNS TXT record (if you are
                                using BIND for DNS). (default: False)
          --dns-route53         Obtain certificates using a DNS TXT record (if you are
                                using Route53 for DNS). (default: False)
          --dns-sakuracloud     Obtain certificates using a DNS TXT record (if you are
                                using Sakura Cloud for DNS). (default: False)

        apache:
          Apache Web Server plugin

          --apache-enmod APACHE_ENMOD
                                Path to the Apache 'a2enmod' binary (default: None)
          --apache-dismod APACHE_DISMOD
                                Path to the Apache 'a2dismod' binary (default: None)
          --apache-le-vhost-ext APACHE_LE_VHOST_EXT
                                SSL vhost configuration extension (default: -le-
                                ssl.conf)
          --apache-server-root APACHE_SERVER_ROOT
                                Apache server root directory (default: /etc/httpd)
          --apache-vhost-root APACHE_VHOST_ROOT
                                Apache server VirtualHost configuration root (default:
                                None)
          --apache-logs-root APACHE_LOGS_ROOT
                                Apache server logs directory (default: /var/log/httpd)
          --apache-challenge-location APACHE_CHALLENGE_LOCATION
                                Directory path for challenge configuration (default:
                                /etc/httpd/conf.d)
          --apache-handle-modules APACHE_HANDLE_MODULES
                                Let installer handle enabling required modules for you
                                (Only Ubuntu/Debian currently) (default: False)
          --apache-handle-sites APACHE_HANDLE_SITES
                                Let installer handle enabling sites for you (Only
                                Ubuntu/Debian currently) (default: False)
          --apache-ctl APACHE_CTL
                                Full path to Apache control script (default:
                                apachectl)

        manual:
          Authenticate through manual configuration or custom shell scripts. When
          using shell scripts, an authenticator script must be provided. The
          environment variables available to this script depend on the type of
          challenge. $CERTBOT_DOMAIN will always contain the domain being
          authenticated. For HTTP-01 and DNS-01, $CERTBOT_VALIDATION is the
          validation string, and $CERTBOT_TOKEN is the filename of the resource
          requested when performing an HTTP-01 challenge. An additional cleanup
          script can also be provided and can use the additional variable
          $CERTBOT_AUTH_OUTPUT which contains the stdout output from the auth
          script.

          --manual-auth-hook MANUAL_AUTH_HOOK
                                Path or command to execute for the authentication
                                script (default: None)
          --manual-cleanup-hook MANUAL_CLEANUP_HOOK
                                Path or command to execute for the cleanup script
                                (default: None)
          --manual-public-ip-logging-ok
                                Automatically allows public IP logging (default: Ask)

        nginx:
          Nginx Web Server plugin

          --nginx-server-root NGINX_SERVER_ROOT
                                Nginx server root directory. (default: /etc/nginx)
          --nginx-ctl NGINX_CTL
                                Path to the 'nginx' binary, used for 'configtest' and
                                retrieving nginx version number. (default: nginx)

        null:
          Null Installer

        standalone:
          Spin up a temporary webserver

        webroot:
          Place files in webroot directory

          --webroot-path WEBROOT_PATH, -w WEBROOT_PATH
                                public_html / webroot path. This can be specified
                                multiple times to handle different domains; each
                                domain will have the webroot path that preceded it.
                                For instance: `-w /var/www/example -d example.com -d
                                www.example.com -w /var/www/thing -d thing.net -d
                                m.thing.net` (default: Ask)
          --webroot-map WEBROOT_MAP
                                JSON dictionary mapping domains to webroot paths; this
                                implies -d for each entry. You may need to escape this
                                from your shell. E.g.: --webroot-map
                                '{"eg1.is,m.eg1.is":"/www/eg1/", "eg2.is":"/www/eg2"}'
                                This option is merged with, but takes precedence over,
                                -w / -d entries. At present, if you put webroot-map in
                                a config file, it needs to be on a single line, like:
                                webroot-map = {"example.com":"/var/www"}. (default:
                                {})

生成证书
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

创建证书文件，创建证书过程中会自动安装依赖包::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto certonly --standalone --email mzh@hopewait.com -d hopewait.com -d www.hopewait.com
    Bootstrapping dependencies for RedHat-based OSes... (you can skip this with --no-bootstrap)
    yum is /usr/bin/yum
    yum is hashed (/usr/bin/yum)
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
    epel/x86_64/metalink                                                                                            |  18 kB  00:00:00     
     * base: centos.sonn.com
     * epel: mirror.layeronline.com
     * extras: mirror.fileplanet.com
     * updates: mirror.fileplanet.com
    base                                                                                                            | 3.6 kB  00:00:00     
    epel                                                                                                            | 5.3 kB  00:00:00     
    extras                                                                                                          | 3.4 kB  00:00:00     
    ius                                                                                                             | 1.3 kB  00:00:00     
    updates                                                                                                         | 3.4 kB  00:00:00     
    (1/2): epel/x86_64/updateinfo                                                                                   | 976 kB  00:00:00     
    (2/2): epel/x86_64/primary_db                                                                                   | 6.7 MB  00:00:00     
    Package gcc-4.8.5-36.el7_6.2.x86_64 already installed and latest version
    Package 1:openssl-1.0.2k-16.el7_6.1.x86_64 already installed and latest version
    Package 1:openssl-devel-1.0.2k-16.el7_6.1.x86_64 already installed and latest version
    Package libffi-devel-3.0.13-18.el7.x86_64 already installed and latest version
    Package ca-certificates-2018.2.22-70.0.el7_5.noarch already installed and latest version
    Package python-devel-2.7.5-77.el7_6.x86_64 already installed and latest version
    Resolving Dependencies
    --> Running transaction check
    ---> Package augeas-libs.x86_64 0:1.4.0-6.el7_6.1 will be installed
    ---> Package mod_ssl.x86_64 1:2.4.6-89.el7.centos will be installed
    ---> Package python-tools.x86_64 0:2.7.5-77.el7_6 will be installed
    --> Processing Dependency: tkinter = 2.7.5-77.el7_6 for package: python-tools-2.7.5-77.el7_6.x86_64
    ---> Package python-virtualenv.noarch 0:15.1.0-2.el7 will be installed
    ---> Package python2-pip.noarch 0:8.1.2-8.el7 will be installed
    ---> Package redhat-rpm-config.noarch 0:9.1.0-87.el7.centos will be installed
    --> Processing Dependency: dwz >= 0.4 for package: redhat-rpm-config-9.1.0-87.el7.centos.noarch
    --> Processing Dependency: zip for package: redhat-rpm-config-9.1.0-87.el7.centos.noarch
    --> Processing Dependency: perl-srpm-macros for package: redhat-rpm-config-9.1.0-87.el7.centos.noarch
    --> Running transaction check
    ---> Package dwz.x86_64 0:0.11-3.el7 will be installed
    ---> Package perl-srpm-macros.noarch 0:1-8.el7 will be installed
    ---> Package tkinter.x86_64 0:2.7.5-77.el7_6 will be installed
    --> Processing Dependency: libtk8.5.so()(64bit) for package: tkinter-2.7.5-77.el7_6.x86_64
    --> Processing Dependency: libtcl8.5.so()(64bit) for package: tkinter-2.7.5-77.el7_6.x86_64
    --> Processing Dependency: libX11.so.6()(64bit) for package: tkinter-2.7.5-77.el7_6.x86_64
    --> Processing Dependency: libTix.so()(64bit) for package: tkinter-2.7.5-77.el7_6.x86_64
    ---> Package zip.x86_64 0:3.0-11.el7 will be installed
    --> Running transaction check
    ---> Package libX11.x86_64 0:1.6.5-2.el7 will be installed
    --> Processing Dependency: libX11-common >= 1.6.5-2.el7 for package: libX11-1.6.5-2.el7.x86_64
    --> Processing Dependency: libxcb.so.1()(64bit) for package: libX11-1.6.5-2.el7.x86_64
    ---> Package tcl.x86_64 1:8.5.13-8.el7 will be installed
    ---> Package tix.x86_64 1:8.4.3-12.el7 will be installed
    ---> Package tk.x86_64 1:8.5.13-6.el7 will be installed
    --> Processing Dependency: libXft.so.2()(64bit) for package: 1:tk-8.5.13-6.el7.x86_64
    --> Running transaction check
    ---> Package libX11-common.noarch 0:1.6.5-2.el7 will be installed
    ---> Package libXft.x86_64 0:2.3.2-2.el7 will be installed
    --> Processing Dependency: fontconfig >= 2.2-1 for package: libXft-2.3.2-2.el7.x86_64
    --> Processing Dependency: libfontconfig.so.1()(64bit) for package: libXft-2.3.2-2.el7.x86_64
    --> Processing Dependency: libXrender.so.1()(64bit) for package: libXft-2.3.2-2.el7.x86_64
    ---> Package libxcb.x86_64 0:1.13-1.el7 will be installed
    --> Processing Dependency: libXau.so.6()(64bit) for package: libxcb-1.13-1.el7.x86_64
    --> Running transaction check
    ---> Package fontconfig.x86_64 0:2.13.0-4.3.el7 will be installed
    --> Processing Dependency: fontpackages-filesystem for package: fontconfig-2.13.0-4.3.el7.x86_64
    --> Processing Dependency: dejavu-sans-fonts for package: fontconfig-2.13.0-4.3.el7.x86_64
    ---> Package libXau.x86_64 0:1.0.8-2.1.el7 will be installed
    ---> Package libXrender.x86_64 0:0.9.10-1.el7 will be installed
    --> Running transaction check
    ---> Package dejavu-sans-fonts.noarch 0:2.33-6.el7 will be installed
    --> Processing Dependency: dejavu-fonts-common = 2.33-6.el7 for package: dejavu-sans-fonts-2.33-6.el7.noarch
    ---> Package fontpackages-filesystem.noarch 0:1.44-8.el7 will be installed
    --> Running transaction check
    ---> Package dejavu-fonts-common.noarch 0:2.33-6.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    =======================================================================================================================================
     Package                                 Arch                   Version                                  Repository               Size
    =======================================================================================================================================
    Installing:
     augeas-libs                             x86_64                 1.4.0-6.el7_6.1                          updates                 355 k
     mod_ssl                                 x86_64                 1:2.4.6-89.el7.centos                    updates                 112 k
     python-tools                            x86_64                 2.7.5-77.el7_6                           updates                 856 k
     python-virtualenv                       noarch                 15.1.0-2.el7                             base                    1.7 M
     python2-pip                             noarch                 8.1.2-8.el7                              epel                    1.7 M
     redhat-rpm-config                       noarch                 9.1.0-87.el7.centos                      base                     81 k
    Installing for dependencies:
     dejavu-fonts-common                     noarch                 2.33-6.el7                               base                     64 k
     dejavu-sans-fonts                       noarch                 2.33-6.el7                               base                    1.4 M
     dwz                                     x86_64                 0.11-3.el7                               base                     99 k
     fontconfig                              x86_64                 2.13.0-4.3.el7                           base                    254 k
     fontpackages-filesystem                 noarch                 1.44-8.el7                               base                    9.9 k
     libX11                                  x86_64                 1.6.5-2.el7                              base                    606 k
     libX11-common                           noarch                 1.6.5-2.el7                              base                    164 k
     libXau                                  x86_64                 1.0.8-2.1.el7                            base                     29 k
     libXft                                  x86_64                 2.3.2-2.el7                              base                     58 k
     libXrender                              x86_64                 0.9.10-1.el7                             base                     26 k
     libxcb                                  x86_64                 1.13-1.el7                               base                    214 k
     perl-srpm-macros                        noarch                 1-8.el7                                  base                    4.6 k
     tcl                                     x86_64                 1:8.5.13-8.el7                           base                    1.9 M
     tix                                     x86_64                 1:8.4.3-12.el7                           base                    254 k
     tk                                      x86_64                 1:8.5.13-6.el7                           base                    1.4 M
     tkinter                                 x86_64                 2.7.5-77.el7_6                           updates                 326 k
     zip                                     x86_64                 3.0-11.el7                               base                    260 k

    Transaction Summary
    =======================================================================================================================================
    Install  6 Packages (+17 Dependent packages)

    Total download size: 12 M
    Installed size: 34 M
    Is this ok [y/d/N]: y
    Downloading packages:
    (1/23): dejavu-fonts-common-2.33-6.el7.noarch.rpm                                                               |  64 kB  00:00:00     
    (2/23): fontpackages-filesystem-1.44-8.el7.noarch.rpm                                                           | 9.9 kB  00:00:00     
    (3/23): augeas-libs-1.4.0-6.el7_6.1.x86_64.rpm                                                                  | 355 kB  00:00:00     
    (4/23): dwz-0.11-3.el7.x86_64.rpm                                                                               |  99 kB  00:00:00     
    (5/23): fontconfig-2.13.0-4.3.el7.x86_64.rpm                                                                    | 254 kB  00:00:00     
    (6/23): libXau-1.0.8-2.1.el7.x86_64.rpm                                                                         |  29 kB  00:00:00     
    (7/23): libXft-2.3.2-2.el7.x86_64.rpm                                                                           |  58 kB  00:00:00     
    (8/23): libxcb-1.13-1.el7.x86_64.rpm                                                                            | 214 kB  00:00:00     
    (9/23): libXrender-0.9.10-1.el7.x86_64.rpm                                                                      |  26 kB  00:00:00     
    (10/23): perl-srpm-macros-1-8.el7.noarch.rpm                                                                    | 4.6 kB  00:00:00     
    (11/23): mod_ssl-2.4.6-89.el7.centos.x86_64.rpm                                                                 | 112 kB  00:00:00     
    (12/23): dejavu-sans-fonts-2.33-6.el7.noarch.rpm                                                                | 1.4 MB  00:00:00     
    (13/23): libX11-1.6.5-2.el7.x86_64.rpm                                                                          | 606 kB  00:00:00     
    (14/23): libX11-common-1.6.5-2.el7.noarch.rpm                                                                   | 164 kB  00:00:00     
    (15/23): python-virtualenv-15.1.0-2.el7.noarch.rpm                                                              | 1.7 MB  00:00:00     
    (16/23): tcl-8.5.13-8.el7.x86_64.rpm                                                                            | 1.9 MB  00:00:00     
    (17/23): redhat-rpm-config-9.1.0-87.el7.centos.noarch.rpm                                                       |  81 kB  00:00:00     
    (18/23): tix-8.4.3-12.el7.x86_64.rpm                                                                            | 254 kB  00:00:00     
    (19/23): zip-3.0-11.el7.x86_64.rpm                                                                              | 260 kB  00:00:00     
    (20/23): python-tools-2.7.5-77.el7_6.x86_64.rpm                                                                 | 856 kB  00:00:00     
    (21/23): tkinter-2.7.5-77.el7_6.x86_64.rpm                                                                      | 326 kB  00:00:00     
    (22/23): python2-pip-8.1.2-8.el7.noarch.rpm                                                                     | 1.7 MB  00:00:00     
    (23/23): tk-8.5.13-6.el7.x86_64.rpm                                                                             | 1.4 MB  00:00:00     
    ---------------------------------------------------------------------------------------------------------------------------------------
    Total                                                                                                   13 MB/s |  12 MB  00:00:00     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : 1:tcl-8.5.13-8.el7.x86_64                                                                                          1/23 
      Installing : fontpackages-filesystem-1.44-8.el7.noarch                                                                          2/23 
      Installing : dejavu-fonts-common-2.33-6.el7.noarch                                                                              3/23 
      Installing : dejavu-sans-fonts-2.33-6.el7.noarch                                                                                4/23 
      Installing : fontconfig-2.13.0-4.3.el7.x86_64                                                                                   5/23 
      Installing : dwz-0.11-3.el7.x86_64                                                                                              6/23 
      Installing : libX11-common-1.6.5-2.el7.noarch                                                                                   7/23 
      Installing : zip-3.0-11.el7.x86_64                                                                                              8/23 
      Installing : libXau-1.0.8-2.1.el7.x86_64                                                                                        9/23 
      Installing : libxcb-1.13-1.el7.x86_64                                                                                          10/23 
      Installing : libX11-1.6.5-2.el7.x86_64                                                                                         11/23 
      Installing : libXrender-0.9.10-1.el7.x86_64                                                                                    12/23 
      Installing : libXft-2.3.2-2.el7.x86_64                                                                                         13/23 
      Installing : 1:tk-8.5.13-6.el7.x86_64                                                                                          14/23 
      Installing : 1:tix-8.4.3-12.el7.x86_64                                                                                         15/23 
      Installing : tkinter-2.7.5-77.el7_6.x86_64                                                                                     16/23 
      Installing : perl-srpm-macros-1-8.el7.noarch                                                                                   17/23 
      Installing : redhat-rpm-config-9.1.0-87.el7.centos.noarch                                                                      18/23 
      Installing : python-tools-2.7.5-77.el7_6.x86_64                                                                                19/23 
      Installing : 1:mod_ssl-2.4.6-89.el7.centos.x86_64                                                                              20/23 
      Installing : augeas-libs-1.4.0-6.el7_6.1.x86_64                                                                                21/23 
      Installing : python-virtualenv-15.1.0-2.el7.noarch                                                                             22/23 
      Installing : python2-pip-8.1.2-8.el7.noarch                                                                                    23/23 
      Verifying  : 1:tcl-8.5.13-8.el7.x86_64                                                                                          1/23 
      Verifying  : fontconfig-2.13.0-4.3.el7.x86_64                                                                                   2/23 
      Verifying  : python-tools-2.7.5-77.el7_6.x86_64                                                                                 3/23 
      Verifying  : libXrender-0.9.10-1.el7.x86_64                                                                                     4/23 
      Verifying  : 1:tix-8.4.3-12.el7.x86_64                                                                                          5/23 
      Verifying  : fontpackages-filesystem-1.44-8.el7.noarch                                                                          6/23 
      Verifying  : tkinter-2.7.5-77.el7_6.x86_64                                                                                      7/23 
      Verifying  : perl-srpm-macros-1-8.el7.noarch                                                                                    8/23 
      Verifying  : dejavu-fonts-common-2.33-6.el7.noarch                                                                              9/23 
      Verifying  : libxcb-1.13-1.el7.x86_64                                                                                          10/23 
      Verifying  : libXft-2.3.2-2.el7.x86_64                                                                                         11/23 
      Verifying  : redhat-rpm-config-9.1.0-87.el7.centos.noarch                                                                      12/23 
      Verifying  : python2-pip-8.1.2-8.el7.noarch                                                                                    13/23 
      Verifying  : 1:tk-8.5.13-6.el7.x86_64                                                                                          14/23 
      Verifying  : libX11-1.6.5-2.el7.x86_64                                                                                         15/23 
      Verifying  : dejavu-sans-fonts-2.33-6.el7.noarch                                                                               16/23 
      Verifying  : python-virtualenv-15.1.0-2.el7.noarch                                                                             17/23 
      Verifying  : libXau-1.0.8-2.1.el7.x86_64                                                                                       18/23 
      Verifying  : zip-3.0-11.el7.x86_64                                                                                             19/23 
      Verifying  : libX11-common-1.6.5-2.el7.noarch                                                                                  20/23 
      Verifying  : dwz-0.11-3.el7.x86_64                                                                                             21/23 
      Verifying  : augeas-libs-1.4.0-6.el7_6.1.x86_64                                                                                22/23 
      Verifying  : 1:mod_ssl-2.4.6-89.el7.centos.x86_64                                                                              23/23 

    Installed:
      augeas-libs.x86_64 0:1.4.0-6.el7_6.1       mod_ssl.x86_64 1:2.4.6-89.el7.centos    python-tools.x86_64 0:2.7.5-77.el7_6             
      python-virtualenv.noarch 0:15.1.0-2.el7    python2-pip.noarch 0:8.1.2-8.el7        redhat-rpm-config.noarch 0:9.1.0-87.el7.centos   

    Dependency Installed:
      dejavu-fonts-common.noarch 0:2.33-6.el7      dejavu-sans-fonts.noarch 0:2.33-6.el7            dwz.x86_64 0:0.11-3.el7               
      fontconfig.x86_64 0:2.13.0-4.3.el7           fontpackages-filesystem.noarch 0:1.44-8.el7      libX11.x86_64 0:1.6.5-2.el7           
      libX11-common.noarch 0:1.6.5-2.el7           libXau.x86_64 0:1.0.8-2.1.el7                    libXft.x86_64 0:2.3.2-2.el7           
      libXrender.x86_64 0:0.9.10-1.el7             libxcb.x86_64 0:1.13-1.el7                       perl-srpm-macros.noarch 0:1-8.el7     
      tcl.x86_64 1:8.5.13-8.el7                    tix.x86_64 1:8.4.3-12.el7                        tk.x86_64 1:8.5.13-6.el7              
      tkinter.x86_64 0:2.7.5-77.el7_6              zip.x86_64 0:3.0-11.el7                         

    Complete!
    Creating virtual environment...
    Installing Python packages...

    Installation succeeded.
    Saving debug log to /var/log/letsencrypt/letsencrypt.log
    Plugins selected: Authenticator standalone, Installer None

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Please read the Terms of Service at
    https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf. You must
    agree in order to register with the ACME server at
    https://acme-v02.api.letsencrypt.org/directory
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    (A)gree/(C)ancel: (A)gree/(C)ancel: A    <-- 说明： 此处输入A，表示同意

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Would you be willing to share your email address with the Electronic Frontier
    Foundation, a founding partner of the Let's Encrypt project and the non-profit
    organization that develops Certbot? We'd like to send you email about our work
    encrypting the web, EFF news, campaigns, and ways to support digital freedom.
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    (Y)es/(N)o: Y        <-- 说明： 此处输入Y，表示确认
    Obtaining a new certificate
    Performing the following challenges:
    http-01 challenge for hopewait.com
    http-01 challenge for www.hopewait.com
    Waiting for verification...
    Cleaning up challenges

    IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/hopewait.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/hopewait.com/privkey.pem
       Your cert will expire on 2019-09-14. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot-auto
       again. To non-interactively renew *all* of your certificates, run
       "certbot-auto renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:

       Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
       Donating to EFF:                    https://eff.org/donate-le

    [root@hopewait ~]# 

查看证书文件::

    [root@hopewait ~]# ls -lah /etc/letsencrypt/live/hopewait.com
    total 4.0K
    drwxr-xr-x. 2 root root  93 Jun 17 06:49 .
    drwx------. 3 root root  40 Jun 17 06:49 ..
    lrwxrwxrwx. 1 root root  36 Jun 17 06:49 cert.pem -> ../../archive/hopewait.com/cert1.pem
    lrwxrwxrwx. 1 root root  37 Jun 17 06:49 chain.pem -> ../../archive/hopewait.com/chain1.pem
    lrwxrwxrwx. 1 root root  41 Jun 17 06:49 fullchain.pem -> ../../archive/hopewait.com/fullchain1.pem
    lrwxrwxrwx. 1 root root  39 Jun 17 06:49 privkey.pem -> ../../archive/hopewait.com/privkey1.pem
    -rw-r--r--. 1 root root 692 Jun 17 06:49 README


删除证书::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto delete
    Saving debug log to /var/log/letsencrypt/letsencrypt.log

    Which certificate(s) would you like to delete?
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    1: hopewait.com
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Select the appropriate numbers separated by commas and/or spaces, or leave input
    blank to select all options shown (Enter 'c' to cancel): 1

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Deleted all files relating to certificate hopewait.com.
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    [root@hopewait ~]# ls -lah /etc/letsencrypt/live/
    total 4.0K
    drwx------. 2 root root  20 Jun 17 22:18 .
    drwxr-xr-x. 9 root root 108 Jun 17 22:18 ..
    -rw-r--r--. 1 root root 740 Jun 17 06:49 README
    [root@hopewait ~]# 

即删除证书时，会将证书文件夹删除，并删除归档文件archive中的证书文件夹。

重新生成证书文件::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto certonly --standalone --redirect --email mzh@hopewait.com -d hopewait.com -d www.hopewait.com
    Saving debug log to /var/log/letsencrypt/letsencrypt.log
    Plugins selected: Authenticator standalone, Installer None
    Obtaining a new certificate

    IMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/hopewait.com/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/hopewait.com/privkey.pem
       Your cert will expire on 2019-09-15. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot-auto
       again. To non-interactively renew *all* of your certificates, run
       "certbot-auto renew"
     - If you like Certbot, please consider supporting our work by:

       Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
       Donating to EFF:                    https://eff.org/donate-le

    [root@hopewait ~]# ls -lah /etc/letsencrypt/archive/
    total 0
    drwx------. 3 root root  26 Jun 17 22:25 .
    drwxr-xr-x. 9 root root 108 Jun 17 22:25 ..
    drwxr-xr-x. 2 root root  83 Jun 17 22:25 hopewait.com
    
    [root@hopewait ~]# ls -lah /etc/letsencrypt/live/hopewait.com/
    total 4.0K
    drwxr-xr-x. 2 root root  93 Jun 17 22:25 .
    drwx------. 3 root root  40 Jun 17 22:25 ..
    lrwxrwxrwx. 1 root root  36 Jun 17 22:25 cert.pem -> ../../archive/hopewait.com/cert1.pem
    lrwxrwxrwx. 1 root root  37 Jun 17 22:25 chain.pem -> ../../archive/hopewait.com/chain1.pem
    lrwxrwxrwx. 1 root root  41 Jun 17 22:25 fullchain.pem -> ../../archive/hopewait.com/fullchain1.pem
    lrwxrwxrwx. 1 root root  39 Jun 17 22:25 privkey.pem -> ../../archive/hopewait.com/privkey1.pem
    -rw-r--r--. 1 root root 692 Jun 17 22:25 README

在"/etc/letsencrypt/live/hopewait.com/"域名目录下有4个文件就是生成的密钥证书文件::

    cert.pem     <-- 说明：letsencrypt服务器端颁发的证书文件
    chain.pem     <-- 说明：根证书和中继证书
    fullchain.pem     <-- 说明：Nginx所需要ssl_certificate文件
    privkey.pem     <-- 说明：安全证书KEY文件，密钥文件

配置Apache
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

使用Apache需要使用 ``cert.pem``、 ``chain.pem``、 ``privkey.pem`` 三个文件。

配置 ``/etc/httpd/conf.d/ssl.conf`` 文件::

    [root@hopewait ~]# cat -n /etc/httpd/conf.d/ssl.conf|sed -n '95,117p'
        95  #   Server Certificate:
        96  # Point SSLCertificateFile at a PEM encoded certificate.  If
        97  # the certificate is encrypted, then you will be prompted for a
        98  # pass phrase.  Note that a kill -HUP will prompt again.  A new
        99  # certificate can be generated using the genkey(1) command.
       100  SSLCertificateFile /etc/letsencrypt/live/hopewait.com/cert.pem   <-- 说明：letsencrypt服务器端颁发的证书文件
       101
       102  #   Server Private Key:
       103  #   If the key is not combined with the certificate, use this
       104  #   directive to point at the key file.  Keep in mind that if
       105  #   you've both a RSA and a DSA private key you can configure
       106  #   both in parallel (to also allow the use of DSA ciphers, etc.)
       107  SSLCertificateKeyFile /etc/letsencrypt/live/hopewait.com/privkey.pem     <-- 说明：安全证书KEY文件，密钥文件
       108
       109  #   Server Certificate Chain:
       110  #   Point SSLCertificateChainFile at a file containing the
       111  #   concatenation of PEM encoded CA certificates which form the
       112  #   certificate chain for the server certificate. Alternatively
       113  #   the referenced file can be the same as SSLCertificateFile
       114  #   when the CA certificates are directly appended to the server
       115  #   certificate for convinience.
       116  SSLCertificateChainFile /etc/letsencrypt/live/hopewait.com/chain.pem    <-- 说明：根证书和中继证书
       117

配置http重定向https::

    [root@hopewait ~]# cat > /etc/httpd/conf.d/http2https.conf << EOF
    > <VirtualHost *:80>
    >     ServerName hopewait.com
    >     RewriteEngine on
    >     RewriteCond %{SERVER_PORT} !^443$
    >     RewriteRule ^/?(.*)$ https://%{SERVER_NAME}/$1 [L,R]
    > </VirtualHost>
    > EOF
    [root@hopewait ~]# cat /etc/httpd/conf.d/http2https.conf 
    <VirtualHost *:80>
        ServerName hopewait.com
        RewriteEngine on
        RewriteCond %{SERVER_PORT} !^443$
        RewriteRule ^/?(.*)$ https://%{SERVER_NAME}/ [L,R]
    </VirtualHost>

测试Apache服务::

    [root@hopewait ~]# httpd -t
    Syntax OK
    [root@hopewait ~]# systemctl restart httpd

使用google浏览器打开 http://hopewait.com/ 链接或 http://www.hopewait.com/  时，会自动跳转到  https://hopewait.com/ 链接或 https://www.hopewait.com/ 链接，此时查看证书的详情:

.. image:: ./_static/images/LetsEncrypt_cert.png

可以看到证书的颁发者是"Let's Encrypt Authority X3"和使用者是"hopewait.com"，有效期从2019年6月17日至2019年9月15日，并且浏览器提示"连接是安全的"、"证书有效"。

为测试nginx服务，先停止httpd服务::

    [root@hopewait ~]# netstat -tunlp|grep httpd
    tcp6       0      0 :::80                   :::*                    LISTEN      1505/httpd          
    tcp6       0      0 :::443                  :::*                    LISTEN      1505/httpd          
    [root@hopewait ~]# systemctl stop httpd
    [root@hopewait ~]# netstat -tunlp|grep httpd

配置Nginx
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

安装nginx::

    [root@hopewait ~]# yum install nginx 
    Loaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
    epel/x86_64/metalink                                                                                            |  19 kB  00:00:00     
     * base: mirror.sfo12.us.leaseweb.net
     * epel: mirror.layeronline.com
     * extras: mirror.fileplanet.com
     * updates: mirror.fileplanet.com
    base                                                                                                            | 3.6 kB  00:00:00     
    extras                                                                                                          | 3.4 kB  00:00:00     
    ius                                                                                                             | 1.3 kB  00:00:00     
    updates                                                                                                         | 3.4 kB  00:00:00     
    Resolving Dependencies
    --> Running transaction check
    ---> Package nginx.x86_64 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: nginx-all-modules = 1:1.12.2-3.el7 for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: nginx-filesystem = 1:1.12.2-3.el7 for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: nginx-filesystem for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Processing Dependency: libprofiler.so.0()(64bit) for package: 1:nginx-1.12.2-3.el7.x86_64
    --> Running transaction check
    ---> Package gperftools-libs.x86_64 0:2.6.1-1.el7 will be installed
    ---> Package nginx-all-modules.noarch 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: nginx-mod-http-geoip = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-image-filter = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-perl = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-http-xslt-filter = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-mail = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    --> Processing Dependency: nginx-mod-stream = 1:1.12.2-3.el7 for package: 1:nginx-all-modules-1.12.2-3.el7.noarch
    ---> Package nginx-filesystem.noarch 1:1.12.2-3.el7 will be installed
    --> Running transaction check
    ---> Package nginx-mod-http-geoip.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-http-image-filter.x86_64 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: gd for package: 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64
    --> Processing Dependency: libgd.so.2()(64bit) for package: 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64
    ---> Package nginx-mod-http-perl.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-http-xslt-filter.x86_64 1:1.12.2-3.el7 will be installed
    --> Processing Dependency: libxslt.so.1(LIBXML2_1.0.11)(64bit) for package: 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64
    --> Processing Dependency: libxslt.so.1(LIBXML2_1.0.18)(64bit) for package: 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64
    --> Processing Dependency: libexslt.so.0()(64bit) for package: 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64
    --> Processing Dependency: libxslt.so.1()(64bit) for package: 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64
    ---> Package nginx-mod-mail.x86_64 1:1.12.2-3.el7 will be installed
    ---> Package nginx-mod-stream.x86_64 1:1.12.2-3.el7 will be installed
    --> Running transaction check
    ---> Package gd.x86_64 0:2.0.35-26.el7 will be installed
    --> Processing Dependency: libjpeg.so.62(LIBJPEG_6.2)(64bit) for package: gd-2.0.35-26.el7.x86_64
    --> Processing Dependency: libjpeg.so.62()(64bit) for package: gd-2.0.35-26.el7.x86_64
    --> Processing Dependency: libXpm.so.4()(64bit) for package: gd-2.0.35-26.el7.x86_64
    ---> Package libxslt.x86_64 0:1.1.28-5.el7 will be installed
    --> Running transaction check
    ---> Package libXpm.x86_64 0:3.5.12-1.el7 will be installed
    ---> Package libjpeg-turbo.x86_64 0:1.2.90-6.el7 will be installed
    --> Finished Dependency Resolution

    Dependencies Resolved

    =======================================================================================================================================
     Package                                       Arch                     Version                           Repository              Size
    =======================================================================================================================================
    Installing:
     nginx                                         x86_64                   1:1.12.2-3.el7                    epel                   531 k
    Installing for dependencies:
     gd                                            x86_64                   2.0.35-26.el7                     base                   146 k
     gperftools-libs                               x86_64                   2.6.1-1.el7                       base                   272 k
     libXpm                                        x86_64                   3.5.12-1.el7                      base                    55 k
     libjpeg-turbo                                 x86_64                   1.2.90-6.el7                      base                   134 k
     libxslt                                       x86_64                   1.1.28-5.el7                      base                   242 k
     nginx-all-modules                             noarch                   1:1.12.2-3.el7                    epel                    16 k
     nginx-filesystem                              noarch                   1:1.12.2-3.el7                    epel                    17 k
     nginx-mod-http-geoip                          x86_64                   1:1.12.2-3.el7                    epel                    23 k
     nginx-mod-http-image-filter                   x86_64                   1:1.12.2-3.el7                    epel                    27 k
     nginx-mod-http-perl                           x86_64                   1:1.12.2-3.el7                    epel                    36 k
     nginx-mod-http-xslt-filter                    x86_64                   1:1.12.2-3.el7                    epel                    26 k
     nginx-mod-mail                                x86_64                   1:1.12.2-3.el7                    epel                    54 k
     nginx-mod-stream                              x86_64                   1:1.12.2-3.el7                    epel                    76 k

    Transaction Summary
    =======================================================================================================================================
    Install  1 Package (+13 Dependent packages)

    Total download size: 1.6 M
    Installed size: 4.7 M
    Is this ok [y/d/N]: y
    Downloading packages:
    (1/14): gd-2.0.35-26.el7.x86_64.rpm                                                                             | 146 kB  00:00:00     
    (2/14): libXpm-3.5.12-1.el7.x86_64.rpm                                                                          |  55 kB  00:00:00     
    (3/14): libjpeg-turbo-1.2.90-6.el7.x86_64.rpm                                                                   | 134 kB  00:00:00     
    (4/14): gperftools-libs-2.6.1-1.el7.x86_64.rpm                                                                  | 272 kB  00:00:00     
    (5/14): libxslt-1.1.28-5.el7.x86_64.rpm                                                                         | 242 kB  00:00:00     
    (6/14): nginx-1.12.2-3.el7.x86_64.rpm                                                                           | 531 kB  00:00:00     
    (7/14): nginx-all-modules-1.12.2-3.el7.noarch.rpm                                                               |  16 kB  00:00:00     
    (8/14): nginx-filesystem-1.12.2-3.el7.noarch.rpm                                                                |  17 kB  00:00:00     
    (9/14): nginx-mod-http-geoip-1.12.2-3.el7.x86_64.rpm                                                            |  23 kB  00:00:00     
    (10/14): nginx-mod-http-image-filter-1.12.2-3.el7.x86_64.rpm                                                    |  27 kB  00:00:00     
    (11/14): nginx-mod-http-perl-1.12.2-3.el7.x86_64.rpm                                                            |  36 kB  00:00:00     
    (12/14): nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64.rpm                                                     |  26 kB  00:00:00     
    (13/14): nginx-mod-mail-1.12.2-3.el7.x86_64.rpm                                                                 |  54 kB  00:00:00     
    (14/14): nginx-mod-stream-1.12.2-3.el7.x86_64.rpm                                                               |  76 kB  00:00:00     
    ---------------------------------------------------------------------------------------------------------------------------------------
    Total                                                                                                  1.7 MB/s | 1.6 MB  00:00:00     
    Running transaction check
    Running transaction test
    Transaction test succeeded
    Running transaction
      Installing : libjpeg-turbo-1.2.90-6.el7.x86_64                                                                                  1/14 
      Installing : 1:nginx-filesystem-1.12.2-3.el7.noarch                                                                             2/14 
      Installing : gperftools-libs-2.6.1-1.el7.x86_64                                                                                 3/14 
      Installing : libxslt-1.1.28-5.el7.x86_64                                                                                        4/14 
      Installing : libXpm-3.5.12-1.el7.x86_64                                                                                         5/14 
      Installing : gd-2.0.35-26.el7.x86_64                                                                                            6/14 
      Installing : 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64                                                                   7/14 
      Installing : 1:nginx-mod-http-perl-1.12.2-3.el7.x86_64                                                                          8/14 
      Installing : 1:nginx-mod-mail-1.12.2-3.el7.x86_64                                                                               9/14 
      Installing : 1:nginx-mod-stream-1.12.2-3.el7.x86_64                                                                            10/14 
      Installing : 1:nginx-mod-http-geoip-1.12.2-3.el7.x86_64                                                                        11/14 
      Installing : 1:nginx-1.12.2-3.el7.x86_64                                                                                       12/14 
      Installing : 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64                                                                 13/14 
      Installing : 1:nginx-all-modules-1.12.2-3.el7.noarch                                                                           14/14 
      Verifying  : libXpm-3.5.12-1.el7.x86_64                                                                                         1/14 
      Verifying  : 1:nginx-all-modules-1.12.2-3.el7.noarch                                                                            2/14 
      Verifying  : 1:nginx-mod-http-xslt-filter-1.12.2-3.el7.x86_64                                                                   3/14 
      Verifying  : 1:nginx-mod-http-perl-1.12.2-3.el7.x86_64                                                                          4/14 
      Verifying  : libxslt-1.1.28-5.el7.x86_64                                                                                        5/14 
      Verifying  : 1:nginx-mod-http-image-filter-1.12.2-3.el7.x86_64                                                                  6/14 
      Verifying  : gperftools-libs-2.6.1-1.el7.x86_64                                                                                 7/14 
      Verifying  : gd-2.0.35-26.el7.x86_64                                                                                            8/14 
      Verifying  : 1:nginx-1.12.2-3.el7.x86_64                                                                                        9/14 
      Verifying  : 1:nginx-filesystem-1.12.2-3.el7.noarch                                                                            10/14 
      Verifying  : 1:nginx-mod-mail-1.12.2-3.el7.x86_64                                                                              11/14 
      Verifying  : 1:nginx-mod-stream-1.12.2-3.el7.x86_64                                                                            12/14 
      Verifying  : 1:nginx-mod-http-geoip-1.12.2-3.el7.x86_64                                                                        13/14 
      Verifying  : libjpeg-turbo-1.2.90-6.el7.x86_64                                                                                 14/14 

    Installed:
      nginx.x86_64 1:1.12.2-3.el7                                                                                                          

    Dependency Installed:
      gd.x86_64 0:2.0.35-26.el7                                             gperftools-libs.x86_64 0:2.6.1-1.el7                          
      libXpm.x86_64 0:3.5.12-1.el7                                          libjpeg-turbo.x86_64 0:1.2.90-6.el7                           
      libxslt.x86_64 0:1.1.28-5.el7                                         nginx-all-modules.noarch 1:1.12.2-3.el7                       
      nginx-filesystem.noarch 1:1.12.2-3.el7                                nginx-mod-http-geoip.x86_64 1:1.12.2-3.el7                    
      nginx-mod-http-image-filter.x86_64 1:1.12.2-3.el7                     nginx-mod-http-perl.x86_64 1:1.12.2-3.el7                     
      nginx-mod-http-xslt-filter.x86_64 1:1.12.2-3.el7                      nginx-mod-mail.x86_64 1:1.12.2-3.el7                          
      nginx-mod-stream.x86_64 1:1.12.2-3.el7                               

    Complete!
    [root@hopewait ~]# nginx -v
    nginx version: nginx/1.12.2

配置nginx配置文件::

    [root@hopewait ~]# cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
    [root@hopewait ~]# cat -n /etc/nginx/nginx.conf|sed -n '36,91p'
        36      include /etc/nginx/conf.d/*.conf;
        37
        38      server {
        39          listen       80 default_server;
        40  #         listen       [::]:80 default_server;
        41           server_name  hopewait.com;
        42           rewrite ^(.*)$ https://${server_name}$1 permanent; 
        43  #         root         /usr/share/nginx/html;
        44  # 
        45  #         # Load configuration files for the default server block.
        46  #         include /etc/nginx/default.d/*.conf;
        47  # 
        48  #         location / {
        49  #         }
        50  # 
        51  #         error_page 404 /404.html;
        52  #             location = /40x.html {
        53  #         }
        54  # 
        55  #         error_page 500 502 503 504 /50x.html;
        56  #             location = /50x.html {
        57  #         }
        58      }
        59
        60  # Settings for a TLS enabled server.
        61
        62      server {
        63          listen       443 ssl http2 default_server;
        64          listen       [::]:443 ssl http2 default_server;
        65          server_name  hopewait.com;
        66          root         /usr/share/nginx/html;
        67
        68          ssl_certificate "/etc/letsencrypt/live/hopewait.com/fullchain.pem";
        69          ssl_certificate_key "/etc/letsencrypt/live/hopewait.com/privkey.pem"; 
        70          ssl_session_cache shared:SSL:1m;
        71          ssl_session_timeout  10m;
        72          ssl_ciphers HIGH:!aNULL:!MD5;
        73          ssl_prefer_server_ciphers on;
        74
        75          # Load configuration files for the default server block.
        76          include /etc/nginx/default.d/*.conf;
        77
        78          location / {
        79          }
        80
        81          error_page 404 /404.html;
        82              location = /40x.html {
        83          }
        84
        85          error_page 500 502 503 504 /50x.html;
        86              location = /50x.html {
        87          }
        88      }
        89
        90  }
        91

测试Nginx服务::

    [root@hopewait ~]# nginx -t 
    nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    nginx: configuration file /etc/nginx/nginx.conf test is successful
    [root@hopewait ~]# systemctl start nginx
    [root@hopewait ~]# netstat -tunlp|grep nginx
    tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      1715/nginx: master  
    tcp        0      0 0.0.0.0:443             0.0.0.0:*               LISTEN      1715/nginx: master  
    tcp6       0      0 :::443                  :::*                    LISTEN      1715/nginx: master 


使用google浏览器打开 http://hopewait.com/ 链接或 http://www.hopewait.com/  时，会自动跳转到  https://hopewait.com/ 链接，此时查看证书的详情:

.. image:: ./_static/images/LetsEncrypt_nginx.png

可以看到证书的颁发者是"Let's Encrypt Authority X3"和使用者是"hopewait.com"，有效期从2019年6月17日至2019年9月15日，并且浏览器提示"连接是安全的"、"证书有效"。

自动续签证书
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

手动续签证书::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto renew  --force-renewal       
    Saving debug log to /var/log/letsencrypt/letsencrypt.log

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Processing /etc/letsencrypt/renewal/hopewait.com.conf
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Plugins selected: Authenticator standalone, Installer None
    Renewing an existing certificate

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    new certificate deployed without reload, fullchain is
    /etc/letsencrypt/live/hopewait.com/fullchain.pem
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    Congratulations, all renewals succeeded. The following certs have been renewed:
      /etc/letsencrypt/live/hopewait.com/fullchain.pem (success)
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

安静模式手动续签证书::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto renew --quiet --force-renewal

增加定时任务::

    [root@hopewait ~]# crontab -l
    30 23 * * * /root/letsencrypt/certbot-auto renew --quiet --force-renewal

可以隔段时间再检查证书是否有效。

频繁续签证书会提示续签失败::

    [root@hopewait ~]# /root/letsencrypt/certbot-auto renew --force-renewal
    Saving debug log to /var/log/letsencrypt/letsencrypt.log

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Processing /etc/letsencrypt/renewal/hopewait.com.conf
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    Plugins selected: Authenticator standalone, Installer None
    Renewing an existing certificate
    Attempting to renew cert (hopewait.com) from /etc/letsencrypt/renewal/hopewait.com.conf produced an unexpected error: urn:ietf:params:acme:error:rateLimited :: There were too many requests of a given type :: Error creating new order :: too many certificates already issued for exact set of domains: hopewait.com,www.hopewait.com: see https://letsencrypt.org/docs/rate-limits/. Skipping.
    All renewal attempts failed. The following certs could not be renewed:
      /etc/letsencrypt/live/hopewait.com/fullchain.pem (failure)

    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    All renewal attempts failed. The following certs could not be renewed:
      /etc/letsencrypt/live/hopewait.com/fullchain.pem (failure)
    - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    1 renew failure(s), 0 parse failure(s)

参考 https://letsencrypt.org/docs/rate-limits/ 说明可知:

- Renewals are treated specially: they don’t count against your Certificates per Registered Domain limit, but they are subject to a Duplicate Certificate limit of 5 per week. (即每周的重复证书限制为5)
- There is a Failed Validation limit of 5 failures per account, per hostname, per hour. This limit is higher on our staging environment, so you can use that environment to debug connectivity problems.(每个账户每个主机名每小时有5个失败的失败验证限制！可以使用模拟环境测试连接问题)

模拟环境说明 https://letsencrypt.org/docs/staging-environment/ ：

- The Failed Validations limit is 60 per hour. (即每小时可以失败60次验证！比生产环境5次高多了！)

所以我们更新crontab的自动续签的频率::

    [root@hopewait ~]# crontab -l
    SHELL=/bin/bash
    PATH=/sbin:/bin:/usr/sbin:/usr/bin

    # For details see man 4 crontabs

    # Example of job definition:
    # .---------------- minute (0 - 59)
    # |  .------------- hour (0 - 23)
    # |  |  .---------- day of month (1 - 31)
    # |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
    # |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
    # |  |  |  |  |
    # *  *  *  *  * user-name  command to be executed
    # every two month to renew the CA at the first day 
    30 8 1 */2 * /root/letsencrypt/certbot-auto renew --quiet --force-renewal

这样每两个月的1号早上8:30会续签一次。下次续签后检查有效期是否续签成功！
  
参考文献：

CentOS 7搭建CA认证中心实现https取证  https://www.cnblogs.com/bigdevilking/p/9434444.html

openssl 命令(1): openssl req命令详解 https://blog.csdn.net/abccheng/article/details/82622899

快速签发 Let's Encrypt 证书指南 https://www.cnblogs.com/esofar/p/9291685.html

ACME Client Implementations https://letsencrypt.org/docs/client-options/

Certbot User Guide https://certbot.eff.org/docs/using.html#command-line-options

实战申请Let's Encrypt永久免费SSL证书过程教程及常见问题 https://www.cnblogs.com/tv151579/p/8268356.html

Let's Encrypt证书自动更新 https://blog.csdn.net/shasharoman/article/details/80915222

