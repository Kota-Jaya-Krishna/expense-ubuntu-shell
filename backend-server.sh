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

CHECK_ROOT

apt install nodejs -y >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Installing NodeJS"

id expense >> $LOG_FILE_NAME 2>&1
if [ $? -ne 0 ]
then
    useradd expense >> $LOG_FILE_NAME 2>&1
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user already exists ... $Y SKIPPING $N"
fi

mkdir -p /app >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*

unzip /tmp/backend.zip >> $LOG_FILE_NAME 2>&1
VALIDATE $? "unzip backend"

npm install >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# Prepare MySQL Schema

apt install mysql -y >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.learndevopsacademy.online -uroot -pHarini@2024 < /app/schema/backend.sql >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Daemon Reload"

systemctl enable backend >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Enabling backend"

systemctl restart backend >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Starting Backend"