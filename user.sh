#!/bin/bash/
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Diabling Default nodejs Vesrions" 

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20  version"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Instlaling nodejs:20  version"

id roboshop | tee -a $LOG_FILE

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    echo -e "$G SUCESS USER HAS BEING CREATED $N"
else
    echo -e "$R User has been alredy created $N"
fi
mkdir -p /app
VALIDATE $? "app dir has been created"

rm -rf /app/*
cd /app 
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
unzip /tmp/user.zip
validate $? "Unzipping files using roboshop user"

npm install 
VALIDATE $? "Node js dependencies installing using server.js"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "user.service file has been copied"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "demaon-reload has been reloaded"

systemctl enable user &>>$LOG_FILE
VALIDATE $? "sysctl user has been enabled"

systemctl start user &>>$LOG_FILE
VALIDATE $? "sysctl has been started"


END_TIME=$(date +%s) 
TOTAL_TIME=$(( $END_TIME - $START_TIME )) &>>$LOG_FILE


echo -e "Script exection completed successfully, $Y Time has been Taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE





