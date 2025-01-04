#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

apt update -y >> $LOG_FILE_NAME 2>&1

apt install unzip >> $LOG_FILE_NAME 2>&1

echo "Script started executing at: $TIMESTAMP"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

mkdir -p $LOGS_FOLDER

CHECK_ROOT

apt install nginx -y  >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Installing Nginx Server"

systemctl enable nginx >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Enabling Nginx server"

systemctl start nginx >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Starting Nginx Server"

rm -rf /usr/share/nginx/html/* >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Removing existing version of code"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Downloading Latest code"

cd /usr/share/nginx/html
VALIDATE $? "Moving to HTML directory"

unzip /tmp/frontend.zip >> $LOG_FILE_NAME 2>&1
VALIDATE $? "unzipping the frontend code"

cp /root/expense-ubuntu-shell/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copied expense config"

systemctl restart nginx >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Restarting nginx"