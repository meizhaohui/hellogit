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

参考文献


CentOS 7搭建CA认证中心实现https取证  https://www.cnblogs.com/bigdevilking/p/9434444.html

