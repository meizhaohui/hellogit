#!/bin/bash
# Filename: init_GITLAB_CONF.sh
# Author: Zhaohui Mei
# Date: 2019-08-18
# Email: mzh_love_linux@163.com
# Function: 
# Function 1: Install the GitLab 11.10
# Function 2: Configure the GitLab /etc/gitlab/gitlab.rb
################################################################################


################################################################################
# Define the key information that need to use
TIMEZONE="Asia/Shanghai"
GITLAB_CONF="/etc/gitlab/gitlab.rb"
DOMAIN_NAME="hellogitlab.com"
SMTP_EMAIL_FROM="mzh_love_linux@163.com"
SMTP_HOST_ADDRESS="smtp.163.com"
SMTP_DOMAIN="163.com"
SMTP_HOST_POST=465
SMTP_AUTH_CODE="authCode" # is not the password
SMTP_EMAIL_DISPLAY_NAME="GitLab"
SMTP_EMAIL_SUBJECT_SUFFIX="[GitLab]"
GIT_HOME="/home/git"
GIT_DATA_ROOT_DIR="/home/git/git-data"
IP=$(ip a show|grep 192|awk -F'[ /]+' '{print $3}')
TRUSTED_PROXY=$(echo ${IP}|awk -F'.' '{print $1"."$2"."$3".0"}')

################################################################################


################################################################################
### Check the GitLab version
### [root@localhost ~]# cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
### 11.10.0
export LANG="zh_CN.UTF-8"

echo -e "1) Install Dependencies"
yum install curl policycoreutils-python openssh-server deltarpm -y
################################################################################


################################################################################
echo -e "2) Add the Gitlab-ce yum repo"
cat > /etc/yum.repos.d/gitlab-ce.repo << EOF
[gitlab-ce]
name=Gitlab CE Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el\$releasever/
gpgcheck=0
enabled=1
EOF
################################################################################


################################################################################
echo -e "3) Install Gitlab 11.10.0"
yum install gitlab-ce-11.10.0 -y
################################################################################


################################################################################
echo -e "4) Check Gitlab version"
cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
################################################################################


################################################################################
echo -e "5) backup gitlab configuration"
NOW_TIME=$(date +"%Y%m%d-%H%M%S")
cp "${GITLAB_CONF}" "${GITLAB_CONF}".${NOW_TIME}.bak
################################################################################


################################################################################
echo -e "6) Add tinghua yum repo and Install git"
yum install epel-release -y
yum install https://centos7.iuscommunity.org/ius-release.rpm -y
# replace the yum repo to tsinghua repo
cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.original
cp /etc/yum.repos.d/ius.repo /etc/yum.repos.d/ius.repo.original

cat > /etc/yum.repos.d/epel.repo << EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch/debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF

cat > /etc/yum.repos.d/ius.repo << EOF
[ius]
name = IUS for Enterprise Linux 7 - \$basearch
baseurl = https://mirrors.tuna.tsinghua.edu.cn/ius/7/\$basearch/
enabled = 1
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-debuginfo]
name = IUS for Enterprise Linux 7 - \$basearch - Debug
baseurl = https://mirrors.tuna.tsinghua.edu.cn/ius/7/\$basearch/debug/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

[ius-source]
name = IUS for Enterprise Linux 7 - Source
baseurl = https://mirrors.tuna.tsinghua.edu.cn/ius/7/src/
enabled = 0
repo_gpgcheck = 0
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7
EOF

yum install git2u-2.16.5 -y && git --version
################################################################################


################################################################################
echo -e "7) Install Nginx"
yum install nginx -y && nginx -V
################################################################################


################################################################################
echo -e "8) Create git data root folder and set the permission"
if test -d "${GIT_DATA_ROOT_DIR}" ; then
    echo "The Folder ${GIT_DATA_ROOT_DIR} exist"
else
    mkdir -p "${GIT_DATA_ROOT_DIR}"
fi
chown -R git:root "${GIT_DATA_ROOT_DIR}"
################################################################################


################################################################################
echo -e "9) Create the IP / Domain map file"
echo -e "${IP}\t${DOMAIN_NAME}" >> /etc/hosts
################################################################################


################################################################################
echo -e "10) Modify the Nginx configuration"
wget https://gitlab.com/gitlab-org/gitlab-recipes/raw/master/web-server/nginx/gitlab-omnibus-ssl-nginx.conf
mv gitlab-omnibus-ssl-nginx.conf /etc/nginx/conf.d/gitlab-omnibus-ssl-nginx.conf
ls -lah /etc/nginx/conf.d/
sed -i 's/YOUR_SERVER_FQDN/hellogitlab.com/g' /etc/nginx/conf.d/gitlab-omnibus-ssl-nginx.conf
cat -n /etc/nginx/conf.d/gitlab-omnibus-ssl-nginx.conf
# forbiden the default 80 server
sed -i "38,57s@^@# @g" /etc/nginx/nginx.conf
cat -n /etc/nginx/nginx.conf|sed -n '38,57p'
################################################################################


################################################################################
echo -e "11) Create self ssl files"
mkdir -p /etc/nginx/ssl
echo -e "Create OpenSSL configuration"
cat > req.conf << EOF
# The default config file : /etc/pki/tls/openssl.cnf
# set prompt = no will read config data from file directly.
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no

[ req_distinguished_name ]
countryName            = CN
stateOrProvinceName    = hubei
localityName           = wuhan
0.organizationName     = IT
organizationalUnitName = ${DOMAIN_NAME}
commonName             = ${DOMAIN_NAME}
emailAddress           = ${SMTP_EMAIL_FROM}
EOF
echo -e "Create self CA"
openssl req -x509 -nodes -days 1095 -config req.conf -newkey rsa:2048 -keyout /etc/nginx/ssl/gitlab.key -out /etc/nginx/ssl/gitlab.crt
echo -e "Check Nginx configuration"
nginx -t
################################################################################


################################################################################
echo -e "11) firewall allow 80 and 443 port"
port_80=$(firewall-cmd --list-all|grep '  ports'|grep 80|wc -l)
port_443=$(firewall-cmd --list-all|grep '  ports'|grep 443|wc -l)
if [[ "${port_80}" -eq 0 ]]; then
    firewall-cmd --zone=public --add-port=80/tcp --permanent
fi
if [[ "${port_443}" -eq 0 ]]; then
    firewall-cmd --zone=public --add-port=443/tcp --permanent
fi
firewall-cmd --reload
firewall-cmd --list-all
################################################################################


################################################################################
# Set the gitlab configuration
echo -e "Step 1: set external url"
sed -i "13s@external_url 'http://gitlab.example.com'@external_url \"https://${DOMAIN_NAME}\"@g" "${GITLAB_CONF}"

echo -e "Step 2: set Time Zone ans Sync Time to time5.aliyun.com IP:182.92.12.11"
sed -i "49s@^# gitlab_rails\['time_zone'\] = 'UTC'@gitlab_rails\['time_zone'\] = '${TIMEZONE}'@g" "${GITLAB_CONF}"
yum install ntp -y && ntpdate 182.92.12.11 && echo "Time Sync Done!"
echo "Step 3: Email Setting"
sed -i "52s@^# gitlab_rails\['gitlab_email_enabled'\] = true@gitlab_rails\['gitlab_email_enabled'\] = true@g" "${GITLAB_CONF}"
sed -i "53s/^# gitlab_rails\['gitlab_email_from'\] = 'example@example.com'/gitlab_rails\['gitlab_email_from'\] = '${SMTP_EMAIL_FROM}'/g" "${GITLAB_CONF}"
sed -i "54s@^# gitlab_rails\['gitlab_email_display_name'\] = 'Example'@gitlab_rails\['gitlab_email_display_name'\] = '${SMTP_EMAIL_DISPLAY_NAME}'@g" "${GITLAB_CONF}"
sed -i "55s/^# gitlab_rails\['gitlab_email_reply_to'\] = 'noreply@example.com'/gitlab_rails\['gitlab_email_reply_to'\] = '${SMTP_EMAIL_FROM}'/g" "${GITLAB_CONF}"
sed -i "56s@^# gitlab_rails\['gitlab_email_subject_suffix'\] = ''@gitlab_rails\['gitlab_email_subject_suffix'\] = '${SMTP_EMAIL_SUBJECT_SUFFIX}'@g" "${GITLAB_CONF}"

echo -e "Step 4: Disallow users creating top-level groups"
sed -i "59s@# gitlab_rails\['gitlab_default_can_create_group'\] = true@gitlab_rails\['gitlab_default_can_create_group'\] = false@g" "${GITLAB_CONF}"

echo -e "Step 5: Disallow users changing usernames"
sed -i "60s@# gitlab_rails\['gitlab_username_changing_enabled'\] = true@gitlab_rails\['gitlab_username_changing_enabled'\] = false@g" "${GITLAB_CONF}"

echo -e "Step 6: Configuring GitLab trusted_proxies"
sed -i "113s@^# gitlab_rails\['trusted_proxies'\] = \[\]@gitlab_rails['trusted_proxies'] = \['${TRUSTED_PROXY}/24'\]@g" "${GITLAB_CONF}"

echo -e "Step 7: Git data dirs Settings"
sed -i "380s@^# git_data_dirs@git_data_dirs@g" "${GITLAB_CONF}"
sed -i "381s@^#   \"default@    \"default@g" "${GITLAB_CONF}"
sed -i "382s@^#     \"path\" => \"/mnt/nfs-01/git-data\"@        \"path\" => \"${GIT_DATA_ROOT_DIR}\"@g" "${GITLAB_CONF}"
sed -i "383s@^#    }@    }@g" "${GITLAB_CONF}"
sed -i "384s@^# })@})@g" "${GITLAB_CONF}"

echo -e "Step 8: SMTP settings"
sed -i "511s@# gitlab_rails\['smtp_enable'\] = true@gitlab_rails\['smtp_enable'\] = true@g" "${GITLAB_CONF}"
sed -i "512s/# gitlab_rails\['smtp_address'\] = \"smtp.server\"/gitlab_rails\['smtp_address'\] = \"${SMTP_HOST_ADDRESS}\"/g" "${GITLAB_CONF}"
sed -i "513s@# gitlab_rails\['smtp_port'\] = 465@gitlab_rails\['smtp_port'\] = ${SMTP_HOST_POST}@g"  "${GITLAB_CONF}"
sed -i "514s/# gitlab_rails\['smtp_user_name'\] = \"smtp user\"/gitlab_rails\['smtp_user_name'\] = \"${SMTP_EMAIL_FROM}\"/g"  "${GITLAB_CONF}"
sed -i "515s@# gitlab_rails\['smtp_password'\] = \"smtp password\"@gitlab_rails\['smtp_password'\] = \"${SMTP_AUTH_CODE}\"@g"  "${GITLAB_CONF}"
sed -i "516s@# gitlab_rails\['smtp_domain'\] = \"example.com\"@gitlab_rails\['smtp_domain'\] = \"${SMTP_DOMAIN}\"@g"  "${GITLAB_CONF}"
sed -i "517s@# gitlab_rails\['smtp_authentication'\] = \"login\"@gitlab_rails\['smtp_authentication'\] = \"login\"@g"  "${GITLAB_CONF}"
sed -i "518s@# gitlab_rails\['smtp_enable_starttls_auto'\] = true@gitlab_rails\['smtp_enable_starttls_auto'\] = true@g"  "${GITLAB_CONF}"
sed -i "519s@# gitlab_rails\['smtp_tls'\] = false@gitlab_rails\['smtp_tls'\] = true@g"  "${GITLAB_CONF}"

echo -e "Step 9: GitLab User Settings"
sed -i "653s@^# user\['username'\]@user\['username'\]@g" "${GITLAB_CONF}"
sed -i "654s@^# user\['group'\]@user\['group'\]@g" "${GITLAB_CONF}"
sed -i "662s@^# user\['home'\] = \"/var/opt/gitlab\"@user\['home'\] = \"${GIT_HOME}\"@g" "${GITLAB_CONF}"
sed -i "665s/^# user\['git_user_email'\] = \"gitlab@#{node\['fqdn'\]}\"/user\['git_user_email'\] = \"${SMTP_EMAIL_FROM}\"/g" "${GITLAB_CONF}"

echo -e "Step 10: Set the username of the non-bundled web-server user"
sed -i "970s@^# web_server\['external_users'\] = \[\]@web_server\['external_users'\] = \['nginx', 'root'\]@g" "${GITLAB_CONF}"
sed -i "971s@^# web_server\['username'\] = 'gitlab-www'@web_server\['username'\] = 'nginx'@g" "${GITLAB_CONF}"
sed -i "972s@^# web_server\['group'\] = 'gitlab-www'@web_server\['group'\] = 'nginx'@g" "${GITLAB_CONF}"

echo -e "Step 11: Disable bundled Nginx"
sed -i "983s@^# nginx\['enable'\] = true@nginx\['enable'\] = false@g" "${GITLAB_CONF}"
echo -e "OK. Great Done!!!"
################################################################################


################################################################################
echo -e "You can run the command to test the configuration"
echo -e "Start the gitlab: gitlab-ctl reconfigure"
echo -e "Start the gitlab-runsvdir: systemctl start gitlab-runsvdir"
echo -e "Start the gitlab: gitlab-ctl start"
echo -e "Start the nginx: systemctl start nginx"
echo -e "You can set the Chinese i18n by yourself"

