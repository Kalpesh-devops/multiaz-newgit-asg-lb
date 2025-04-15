#!/bin/bash
yum update -y 
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>hello i am back bro my ip : $(hostname -i)</h1>" > /var/www/html/index.html