#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
cd ${PWD}
chmod +x *
source /root/demo-cfb/variable.sh

if [ -f ~/.ssh/id_rsa.pub ]; then
	echo ""
else
  echo -e "\n\n\n" | ssh-keygen -t rsa
fi

if [ -f /usr/local/bin/aws ]; then
        echo "AWS CLI OK"
else
	cd /root/
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install
	rm awscliv2.zip
fi


#key='/root/jenkins_ec2.pem'
ec2instancecreation () {
echo "Enter the number of instance required"
read inscount
if [  "$inscount" == "" ]; then
inscount=1
echo "Taking default respone as 1"
sleep 0.3
fi
echo -e "Instance Count ${inscount}"
for count in $(seq 1 ${inscount}); do
	aws ec2 run-instances --image-id ${ami} --count 1 --instance-type ${itype} --key-name ${keyname} --security-group-ids ${sgid} --subnet-id ${subid} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DemoInstance-No-'${count}'}]' --region ${region}
done
#for count in {1..${inscount}}
#do
#aws ec2 run-instances --image-id ${ami} --count 1 --instance-type ${itype} --key-name ${keyname} --security-group-ids ${sgid} --subnet-id ${subid} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DemoInstance-No-'${count}'}]' --region ${region}
#done
}
ec2instanceapp () {
#app="/tmp/app-deploy.txt"
#>${app}

#cat <<EOF >${app}
##!/bin/bash'
#date
#
#apt update && apt install docker.io git -y
#cd "/root/"
#codepath="/root/sentiment-analysis/containerized_webapp/"
#git clone https://github.com/BusinessOptimaCloud/sentiment-analysis.git
#cd ${codepath}
#cat_image_id=`docker images | grep -w sentimentapp:ver1 | awk '{print $3}'`
#if [ $cat_image_id=="" ]; then
#   continue;
#else
#   docker rmi ${cat_image_id} -f
#fi
#
#dockerprocess=`systemctl status docker|grep Active|grep dead|wc -l`
#
#if [ ${dockerprocess} -eq 1 ]; then
#    systemctl restart docker
#fi
#
#docker build -t sentimentapp:ver1 ${codepath}
#cat_image_id=`docker images | grep -w sentimentapp | awk '{print $3}'`
#container_id=`docker ps|grep "sentimentapp"|awk '{print $1}'`
#docker stop ${container_id}
#docker rm ${container_id}
#docker run -itd --name sentimentapp -p 80:5000 ${cat_image_id}
#app_status=`docker ps|grep sentimentapp|wc -l`
#public_ip=`curl http://checkip.amazonaws.com`
#
#
#################################################PLEASE OPEN PORT 80 in EC2 Container#############
#if [ ${app_status} -eq 1 ]; then
#	echo ""
#	echo ""
#	echo "YOUR SENTIMENT APP IS UP AND RUNNING"
#	echo "Please Use the below URL to OPEN SENTIMENT APP"
#	echo -e "http://${public_ip}"
#else
#	echo "Container not started please check"
#fi
#EOF
################APP#######
#aws ec2 run-instances --image-id ${ami} --count 1 --instance-type ${itype} --key-name ${keyname} --security-group-ids ${sgid} --subnet-id ${subid} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=DemoInstance-No-'${count}'}]' --region ${region}
#echo $app
aws ec2 run-instances --image-id ${ami} --count 1 --instance-type t2.medium --key-name ${keyname} --security-group-ids ${sgid} --subnet-id ${subid} --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Senti-Demo-App}]' --user-data file:///${app}  --region ${region}
}

s3mount () {
#key='/root/jenkins_ec2.pem'
#ip=`ec2 describe-instances  --region ap-south-1|grep PrivateIpAddress |cut -d'"' -f4|sort -u|tail -1`
echo "Enter the IP where S3 needs to be mounted"
read ip
echo "Enter Bucket name to be mounted"
read bucket
if [  "$bucket" == "" ]; then
bucket=businessoptima
echo "Mounting Default bucket"
sleep 0.3;
fi
	#ssh-copy-id -i ${key} ubuntu@${ip}
	ssh -i ${key} ubuntu@${ip} 'sudo apt update && sudo apt install awscli s3fs -y'
	ssh -i ${key} ubuntu@${ip} mkdir /home/ubuntu/.aws/
	scp -i ${key} ~/.aws/credentials ubuntu@${ip}:/home/ubuntu/.aws/
	ssh -i ${key} ubuntu@${ip} sudo mkdir /root/.aws/
	ssh -i ${key} ubuntu@${ip} sudo ln -s /home/ubuntu/.aws/credentials /root/.aws/credentials
	ssh -i ${key} ubuntu@${ip} mkdir /home/ubuntu/s3-mount/
	ssh -i ${key} ubuntu@${ip} umount /home/ubuntu/s3-mount/
	ssh -i ${key} ubuntu@${ip} s3fs ${bucket} /home/ubuntu/s3-mount/
	ssh -i ${key} ubuntu@${ip} df -h
	echo "Listing S3 Mount Path in remote instance"
	ssh -i ${key} ubuntu@${ip} ls -ltr /home/ubuntu/s3-mount/
}

s3list () {
	echo "Please enter the bucket name to be List"
read bucket
if [  "$bucket" == "" ]; then
bucket=businessoptima
echo "Listing default bucket"
fi

aws s3 ls s3://${bucket}

}
efsmount () {
key='/root/jenkins_ec2.pem'
#ip=`ec2 describe-instances  --region ap-south-1|grep PrivateIpAddress |cut -d'"' -f4|sort -u|tail -1`
echo "Enter the IP where S3 needs to be mounted"
read ip
if [  "$ip" == "" ]; then
echo "Default IP Applied"
sleep 0.3
sudo apt install nfs-common -y
sudo mkdir /efs-data-store/
sudo umount /efs-data-store/
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsendpointip}:/ /efs-data-store/
ls -lrt /efs-data-store/
else
	ssh -i ${key} ubuntu@${ip} sudo apt install nfs-common -y
	ssh -i ${key} ubuntu@${ip} sudo mkdir /efs-data-store/
	ssh -i ${key} ubuntu@${ip} sudo umount /efs-data-store/
	ssh -i ${key} ubuntu@${ip} sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.31.44.144:/ /efs-data-store/
        ssh -i ${key} ubuntu@${ip} ls -ltr /efs-data-store/; df -h
fi
}

terraformdeploy () {
echo "Enter the Server IP"
#read ip
#scp -i ${key} /opt/terraformdeploy.sh ubuntu@${ip}:/tmp/ 
#ssh -i ${key} ubuntu@${ip} cp /tmp/terraformdeploy.sh /root/terraformdeploy.sh
#ssh -i ${key} ubuntu@${ip} sudo bash -x /root/terraformdeploy.sh
!/bin/bash
export PATH=/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/bin/
apt install zip git unzip -y
cd "/root/"
wget https://releases.hashicorp.com/terraform/1.2.5/terraform_1.2.5_linux_amd64.zip
unzip terraform_1.2.5_linux_amd64.zip
mv /root/terraform /usr/local/bin
terraform version
cd /root/

git clone https://github.com/BusinessOptimaCloud/terraform-demo.git

cd /root/terraform-demo/demoapp-deploy/
#
terraform init
terraform plan
terraform apply

#terraform destroy
}
destroydemoapp () {
#	read ip
#	ssh -i ${key} ubuntu@${ip} sudo -i;cd "/root/terraform-demo/demoapp-deploy/";terraform destroy
	cd "/root/terraform-demo/demoapp-deploy/"
	terraform destroy
}

ecs-cluster () {
#aws ecs create-capacity-provider \
#    --name "MyCapacityProvider" \
#    --auto-scaling-group-provider "autoScalingGroupArn=arn:aws:autoscaling:ap-south-1:123456789012:autoScalingGroup:57ffcb94-11f0-4d6d-bf60-3bac5EXAMPLE:autoScalingGroupName/MyASG,managedScaling={status=ENABLED,targetCapacity=100},managedTerminationProtection=ENABLED"

aws ecs create-cluster --cluster-name MyCluster --region us-east-1

aws ecs create-service \
    --cluster MyCluster \
    --service-name MyService \
    --task-definition sample-fargate:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0993c7614890bd82a],securityGroups=[sg-0e166017f500eab8e],assignPublicIp=ENABLED}" \
    --region us-east-1


aws ecs create-task-set \
    --cluster MyCluster \
    --service MyService \
    --task-definition senti-app \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0993c7614890bd82a],securityGroups=[sg-0e166017f500eab8e]} --region us-east-1"

}

creatingefs () {
echo "Enter EFS File system name"
read efsname
aws efs create-file-system \
--tags Key=Name,Value=${efsname} \
--region ${region} \
--profile default

#--encrypted \
#--creation-token FileSystemForDemo \
echo "Please enter the file system id"
read filesystemid

if [  "$filesystemid" == "" ]; then
filesystemid=`aws efs describe-file-systems |grep ${efsname} -B5|grep FileSystemId|cut -d'"' -f4|head -1`
echo "Taking filesystem id automatically"
sleep 0.3
fi


#filesystemid=`aws efs describe-file-systems |grep ${efsname} -B5|grep FileSystemId|cut -d'"' -f4|head -1`

aws efs put-lifecycle-configuration \
--file-system-id ${filesystemid} \
--lifecycle-policies TransitionToIA=AFTER_30_DAYS \
--region ${region} \
--profile default

aws efs create-mount-target \
--file-system-id ${filesystemid} \
--subnet-id  ${subid} \
--security-group ${sgid} \
--region ${region} \
--profile default

aws efs describe-mount-targets \
--file-system-id ${filesystemid} \
--profile default \
--region ${region}


}

mountinguserefs () {
key='/root/jenkins_ec2.pem'
#ip=`ec2 describe-instances  --region ap-south-1|grep PrivateIpAddress |cut -d'"' -f4|sort -u|tail -1`
echo "Please enter the server IP where the EFS to be mounted"
read ip
echo "Please enter the EFS Endpoint IP"
read efsendpointip


if [[  "$efsendpointip" == "" ]] && [[  "$ip" == "" ]]; then
echo "Default Endpoint IP Applied"
sleep 0.3
sudo apt install nfs-common -y
sudo mkdir /efs-data-store1/
sudo mkdir /efs-data-store/
sudo umount /efs-data-store1/ -f
sudo umount /efs-data-store/ -f
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsendpointip}:/ /efs-data-store1/
fi

if [[  "$efsendpointip" == "" ]] | [[  "$ip" == "" ]] ; then
echo "Default Endpoint IP Applied"
sleep 0.3
ssh -i ${key} ubuntu@${ip} sudo apt install nfs-common -y
ssh -i ${key} ubuntu@${ip} sudo mkdir /efs-data-store1/
ssh -i ${key} ubuntu@${ip} sudo umount /efs-data-store1/ -f
ssh -i ${key} ubuntu@${ip} sudo umount /efs-data-store/ -f
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsendpointip}:/ /efs-data-store1/
ssh -i ${key} ubuntu@${ip} ls -ltr /efs-data-store1/; df -h
else
	echo "CUSTOM"
ssh -i ${key} ubuntu@${ip} sudo apt install nfs-common -y
ssh -i ${key} ubuntu@${ip} sudo mkdir /efs-data-store1/
ssh -i ${key} ubuntu@${ip} sudo umount /efs-data-store1/ -f
ssh -i ${key} ubuntu@${ip} sudo umount /efs-data-store/ -f

ssh -i ${key} ubuntu@${ip} sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efsendpointip}:/ /efs-data-store1/
sleep 0.5;
ssh -i ${key} ubuntu@${ip} sudo ls -ltr /efs-data-store1/
ssh -i ${key} ubuntu@${ip} sudo df -h
#sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.31.43.242:/ /efs-data-store1/
fi

}

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

echo "Please Select..."
echo ""
while true;
do

	echo -en "${BIGreen} !!! Welcome to PK Demo on Cloud Foundation!!! ${BICyan} \n"
	echo ""
	echo -e "1: Creating EC2 Instance(VM)"
	echo""
	echo -e "2: Creating EC2 Instance with Single Demo App"
	echo ""
	echo -e "3: Mount S3 Storage to EC2 Instance"
	echo ""
	echo -e "4: List files in S3 bucket"
	echo ""
	echo -e "5: Mounting Shared EFS drive to a specific EC2 Instance"
	echo ""
	echo -e "6: EC2 Instance Demo App with Load Balancer, Auto Scaling"
	echo ""
	echo -e "7: Destroy Demo App"
	echo ""
	echo -e "8: Creating ECS Cluster and Deploy Demo App"
	echo ""
        echo -e "9: Creating EFS file system"
	echo ""
	echo -e "10: Mounting User Created EFS file system"
	echo ""
	echo -e "${BIRed}0 Press zero to quit from the script${BIWhite} \n"
	echo ""
	echo -en "${BIRed}PRESS ENTER TO EXIT from Demo Script${BIWhite} \n"
	echo ""
  read INPUT_STRING
  case $INPUT_STRING in
	1)
		echo "Creating EC2 Instance(VM)";
		ec2instancecreation;
		continue;
		;;
	2)
		echo "Creating EC2 Instance with Single Demo App"
		ec2instanceapp;
		continue;
		;;
	3) 	echo "Mount S3 Storage to EC2 Instance"
		s3mount;
		continue;
		;;
	4)	echo "List files in S3 bucket"
		s3list;
		continue;
		;;
	5)      echo "Mount EFS to EC2 Instance"
	        efsmount;
		continue;
		;;
	6) 	echo "EC2 Instance Demo App with Load Balancer, Auto Scaling"
		terraformdeploy;
		continue;
		;;
	7)	echo "Destroy demo app"
		destroydemoapp;
		continue;
		;;
	8)	echo "Creating ECS Cluster and Deploy App"
		insertingdata;
		continue;
		;;
	9)	echo "Creating EFS file system"
		creatingefs;
		continue;
		;;
	10)	echo "Mounting Created EFS file system to a EC2 Instance"
		mountinguserefs
		continue;
		;;
	0)	esac
		break;
done
