#! /bin/bash -ex
yum update -y
yum install -y httpd

### run httpd
rm /etc/httpd/conf.d/welcome.conf
sed -i -e '$aProxyPass \"/carts\" \"http://fis-ec2-b.corp.internal\"' /etc/httpd/conf/httpd.conf
systemctl start httpd
