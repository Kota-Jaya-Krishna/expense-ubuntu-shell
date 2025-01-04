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

echo "Script started executing at: $TIMESTAMP" >> $LOG_FILE_NAME 2>&1

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
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

echo "Script started executing at: $TIMESTAMP" >> $LOG_FILE_NAME 2>&1

CHECK_ROOT

apt install mysql-server -y >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Installing MySQL Server"

systemctl enable mysql.service >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Enabling MySQL Server"

sudo sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf >> $LOG_FILE_NAME 2>&1
sudo sed -i 's/^mysqlx-bind-address\s*=\s*127.0.0.1/mysqlx-bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf >> $LOG_FILE_NAME 2>&1

systemctl restart mysql.service >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Starting MySQL Server"


mysql -h mysql.learndevopsacademy.online -u root -pHarini@2024 -e 'show databases;' >> $LOG_FILE_NAME 2>&1

if [ $? -ne 0 ]
then
    mysql < /root/expense-ubuntu-shell/databaseusercreation.sql >> $LOG_FILE_NAME 2>&1
    VALIDATE $? "Database user Created"
else
    echo "root user with all GRANTS already exists in Database"
fi

mysql -h mysql.learndevopsacademy.online -u root -pHarini@2024 -e 'show databases;' >> $LOG_FILE_NAME 2>&1
VALIDATE $? "Database Connectivity is Success with new root user"