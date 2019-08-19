#!/bin/bash
# Filename: init_gitlab_conf.sh
# Author: Zhaohui Mei
# Email: mzh_love_linux@163.com
# Function: init the configuration /etc/gitlab/gitlab.rb.

### Note: You need install at first!
### [root@localhost ~]# rpm -ivh gitlab-ce-11.10.0-ce.0.el7.x86_64.rpm 
### [root@localhost ~]# rpm -ivh gitlab-ce-11.10.0-ce.0.el7.x86_64.rpm 
### warning: gitlab-ce-11.10.0-ce.0.el7.x86_64.rpm: Header V4 RSA/SHA1 Signature, key ID f27eab47: NOKEY
### Preparing...                          ################################# [100%]
### Updating / installing...
###    1:gitlab-ce-11.10.0-ce.0.el7       ##################                ( 54%)
### ################################# [100%]
### 
### It looks like GitLab has not been configured yet; skipping the upgrade script.
### 
###        *.                  *.
###       ***                 ***
###      *****               *****
###     .******             *******
###     ********            ********
###    ,,,,,,,,,***********,,,,,,,,,
###   ,,,,,,,,,,,*********,,,,,,,,,,,
###   .,,,,,,,,,,,*******,,,,,,,,,,,,
###       ,,,,,,,,,*****,,,,,,,,,.
###          ,,,,,,,****,,,,,,
###             .,,,***,,,,
###                 ,*,.
###   
### 
### 
###      _______ __  __          __
###     / ____(_) /_/ /   ____ _/ /_
###    / / __/ / __/ /   / __ `/ __ \
###   / /_/ / / /_/ /___/ /_/ / /_/ /
###   \____/_/\__/_____/\__,_/_.___/
###   
### 
### Thank you for installing GitLab!
### GitLab was unable to detect a valid hostname for your instance.
### Please configure a URL for your GitLab instance by setting `external_url`
### configuration in /etc/gitlab/gitlab.rb file.
### Then, you can start your GitLab instance by running the following command:
###   sudo gitlab-ctl reconfigure
### 
### For a comprehensive list of configuration options please see the Omnibus GitLab readme
### https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md

### Check the GitLab version
### [root@localhost ~]# cat /opt/gitlab/embedded/service/gitlab-rails/VERSION
### 11.10.0

### gitlab configuration init
export LANG="zh_CN.UTF-8"
TIMEZONE="Asia/Shanghai"
gitlab_conf="/etc/gitlab/gitlab.rb"
NOW_TIME=$(date +"%Y%m%d-%H%M%S")
cp "${gitlab_conf}" "${gitlab_conf}".${NOW_TIME}.bak
IP=$(ip a show|grep 192|awk -F'[ /]+' '{print $3}')
TRUSTED_PROXY=$(echo ${IP}|awk -F'.' '{print $1"."$2"."$3}')
GIT_DATA_DIR="/home/git/git-data"
if test -d "${GIT_DATA_DIR}" ; then
    echo "The Folder ${GIT_DATA_DIR} exist"
else
    mkdir -p "${GIT_DATA_DIR}"
fi
chown -R git:root "${GIT_DATA_DIR}"

echo -e "Step 1: set external url"
sed -i "13s@external_url 'http://gitlab.example.com'@external_url \"http://${IP}\"@g" "${gitlab_conf}"

echo -e "Step 2: set Time Zone ans Sync Time to time5.aliyun.com IP:182.92.12.11"
sed -i "49s@^# gitlab_rails\['time_zone'\] = 'UTC'@gitlab_rails\['time_zone'\] = '${TIMEZONE}'@g" "${gitlab_conf}"
yum install ntp -y && ntpdate 182.92.12.11 && echo "Time Sync Done!"

echo "Step 3: Email Setting"
sed -i "52s@^# gitlab_rails\['gitlab_email_enabled'\] = true@gitlab_rails\['gitlab_email_enabled'\] = true@g" "${gitlab_conf}"
sed -i "53s@^# gitlab_rails\['gitlab_email_from'\] = 'example\@example.com'@gitlab_rails\['gitlab_email_from'\] = 'mzh_love_linux\@163.com'@g" "${gitlab_conf}"
sed -i "54s@^# gitlab_rails\['gitlab_email_display_name'\] = 'Example'@gitlab_rails\['gitlab_email_display_name'\] = 'GitLab'@g" "${gitlab_conf}"
sed -i "55s@^# gitlab_rails\['gitlab_email_reply_to'\] = 'noreply\@example.com'@gitlab_rails\['gitlab_email_reply_to'\] = 'mzh_love_linux\@163.com'@g" "${gitlab_conf}"
sed -i "56s@^# gitlab_rails\['gitlab_email_subject_suffix'\] = ''@gitlab_rails\['gitlab_email_subject_suffix'\] = '[GitLab]'@g" "${gitlab_conf}"

echo -e "Step 4: Disallow users creating top-level groups"
sed -i "59s@# gitlab_rails\['gitlab_default_can_create_group'\] = true@gitlab_rails\['gitlab_default_can_create_group'\] = false@g" "${gitlab_conf}"

echo -e "Step 5: Disallow users changing usernames"
sed -i "60s@# gitlab_rails\['gitlab_username_changing_enabled'\] = true@gitlab_rails\['gitlab_username_changing_enabled'\] = false@g" "${gitlab_conf}"

echo -e "Step 6: Configuring GitLab trusted_proxies"
sed -i "113s@^# gitlab_rails\['trusted_proxies'\] = \[\]@gitlab_rails['trusted_proxies'] = \['${TRUSTED_PROXY}.0/24'\]@g" "${gitlab_conf}"

echo -e "Step 7: Git data dirs Settings"
sed -i "380s@^# git_data_dirs@git_data_dirs@g" "${gitlab_conf}"
sed -i "381s@^#   \"default@    \"default@g" "${gitlab_conf}"
sed -i "382s@^#     \"path\" => \"/mnt/nfs-01/git-data\"@        \"path\" => \"/home/git/git-data\"@g" "${gitlab_conf}"
sed -i "383s@^#    }@    }@g" "${gitlab_conf}"
sed -i "384s@^# })@})@g" "${gitlab_conf}"

echo -e "Step 8: SMTP settings"
sed -i "511s@# gitlab_rails\['smtp_enable'\] = true@gitlab_rails\['smtp_enable'\] = true@g" "${gitlab_conf}"
sed -i "512s@# gitlab_rails\['smtp_address'\] = \"smtp.server\"@gitlab_rails\['smtp_address'\] = \"smtp.163.com\"@g" "${gitlab_conf}"
sed -i "513s@# gitlab_rails\['smtp_port'\] = 465@gitlab_rails\['smtp_port'\] = 465@g"  "${gitlab_conf}"
sed -i "514s@# gitlab_rails\['smtp_user_name'\] = \"smtp user\"@gitlab_rails\['smtp_user_name'\] = \"mzh_love_linux\@163.com\"@g"  "${gitlab_conf}"
sed -i "515s@# gitlab_rails\['smtp_password'\] = \"smtp password\"@gitlab_rails\['smtp_password'\] = \"authCode\"@g"  "${gitlab_conf}"
sed -i "516s@# gitlab_rails\['smtp_domain'\] = \"example.com\"@gitlab_rails\['smtp_domain'\] = \"163.com\"@g"  "${gitlab_conf}"
sed -i "517s@# gitlab_rails\['smtp_authentication'\] = \"login\"@gitlab_rails\['smtp_authentication'\] = \"login\"@g"  "${gitlab_conf}"
sed -i "518s@# gitlab_rails\['smtp_enable_starttls_auto'\] = true@gitlab_rails\['smtp_enable_starttls_auto'\] = true@g"  "${gitlab_conf}"
sed -i "519s@# gitlab_rails\['smtp_tls'\] = false@gitlab_rails\['smtp_tls'\] = true@g"  "${gitlab_conf}"

echo -e "Step 9: GitLab User Settings"
sed -i "653s@^# user\['username'\]@user\['username'\]@g" "${gitlab_conf}"
sed -i "654s@^# user\['group'\]@user\['group'\]@g" "${gitlab_conf}"
sed -i "662s@^# user\['home'\] = \"/var/opt/gitlab\"@user\['home'\] = \"/home/git\"@g" "${gitlab_conf}"
sed -i "665s@^# user\['git_user_email'\] = \"gitlab\@#{node\['fqdn'\]}\"@user\['git_user_email'\] = \"mzh_love_linux\@163.com\"@g" "${gitlab_conf}"

echo -e "Step 10: Set the username of the non-bundled web-server user"
sed -i "970s@^# web_server\['external_users'\] = \[\]@web_server\['external_users'\] = \['nginx', 'root'\]@g" "${gitlab_conf}"
sed -i "971s@^# web_server\['username'\] = 'gitlab-www'@web_server\['username'\] = 'nginx'@g" "${gitlab_conf}"
sed -i "972s@^# web_server\['group'\] = 'gitlab-www'@web_server\['group'\] = 'nginx'@g" "${gitlab_conf}"

echo -e "Step 11: Disable bundled Nginx"
sed -i "983s@^# nginx\['enable'\] = true@nginx\['enable'\] = false@g" "${gitlab_conf}"
echo -e "OK. Great Done!!!"

echo -e "=============================================================="
echo -e "You can run the command to test the configuration"
echo -e "Start the gitlab-runsvdir: systemctl start gitlab-runsvdir"
echo -e "Start the gitlab: gitlab-ctl reconfigure"
echo -e "Start the gitlab: gitlab-ctl start"
echo -e "modiry the Nginx configuration"
echo -e "Start the nginx: systemctl start nginx"

