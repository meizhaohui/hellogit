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

修改/etc/pki/tls/openssl.cnf文件第172行::

    [root@localhost ~]# sed -i '172s/basicConstraints=CA:FALSE/basicConstraints=CA:TRUE/g' /etc/pki/tls/openssl.cnf 

修改完成后，/etc/pki/tls/openssl.cnf文件第172行处附近的内容如下::

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

- CA认证根证书文件/etc/pki/CA/cacert.pem

查看/etc/pki/CA/cacert.pem文件内容::

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
 
- CA查看根证书的私钥/etc/pki/CA/private/cakey.pem

查看根证书的私钥/etc/pki/CA/private/cakey.pem文件内容::    
    
    [root@server ~]# ls -lah /etc/pki/CA/private/cakey.pem
    -rw-r--r--. 1 root root 1.8K Jun  5 06:43 /etc/pki/CA/private/cakey.pem
    [root@server ~]# cat -n /etc/pki/CA/private/cakey.pem
         1  -----BEGIN ENCRYPTED PRIVATE KEY-----
         2  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
        29  GBA=
        30  -----END ENCRYPTED PRIVATE KEY-----    
    
    



参考文献


CentOS 7搭建CA认证中心实现https取证  https://www.cnblogs.com/bigdevilking/p/9434444.html

