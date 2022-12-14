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
#
ln -sf setup-amazon-linux.sh setup.sh

sed -i 's/ami-.*/'${ami}'"''/g' /root/terraform-demo/demoapp-deploy/variable.tf
sed -i 's/give-existing-key-pair/'${keyname}'"''/g' /root/terraform-demo/demoapp-deploy/variable.tf

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

aws ecs create-cluster --cluster-name MyCluster --region ${region}

aws ecs create-service \
    --cluster MyCluster \
    --service-name MyService \
    --task-definition ${taskdefinition} \
    --desired-count 2 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[${subid}],securityGroups=[${sgid}],assignPublicIp=ENABLED}" \
    --region ${region}


aws ecs create-task-set \
    --cluster MyCluster \
    --service MyService \
    --task-definition ${taskdefinition} \
    --network-configuration "awsvpcConfiguration={subnets=[${subid}],securityGroups=[${sgid}]}" \
    --region ${region}
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

s3bucket () {
echo -e "Please enter the bucket name to be ecreated"
read bucketname
aws s3 mb s3://${bucketname} --region ${region}
echo ""
sleep 0.4
echo "Listing all the available Buckets"
echo ""
aws s3 ls
echo "Listing ${bucketname} bucket"
echo ""
sleep 0.3
echo ""
aws s3 ls s3://${bucketname}
echo ""
count=`aws s3 ls s3://${bucketname}|wc -l`
echo ""
if [ $count = 0 ]; then
echo "${bucketname} Bucket is empty now"
fi
}

s3push () {
echo -e "Please enter the bucket name where the files need to be pushed"
read bucketname
echo -e "Please enter the full file path to upload to S3 / Press enter to upload a sample file"
read s3file
if [ "${s3file}" == "" ]; then
echo "Creating Sample file and Uploading"
echo "Cloud Foundation Demos" >> /tmp/sample-cloud-foundation-demo.txt
s3file='/tmp/sample-cloud-foundation-demo.txt'
else
echo Uploading file: ${s3file}
fi
if [ "${bucketname}" == "" ]; then
bucketname='businessoptima'
fi

aws s3 cp ${s3file} s3://${bucketname}/
}

lists3 () {
	echo ""
	echo "Available Buckets for the User"
	aws s3 ls
	echo "Please Enter Bucket name to be listed"
	read bucketname
	if [ "${bucketname}" == "" ]; then
		bucketname='businessoptima'
	fi

aws s3 ls s3://${bucketname}/
}

syncs3 () {
	echo ""
        echo "Please Enter Bucket name where demo files to be synced / Enter for default bucket"
        read bucketname
        if [ "${bucketname}" == "" ]; then
                bucketname='businessoptima'
        fi
	mkdir /tmp/s3-demo-sync
	for dat in $(seq 20220801 20220831)
	do
	echo "$dat" >> /tmp/s3-demo-sync/out-$dat.log
	done
	cd "/tmp/s3-demo-sync/"
	aws s3 sync . s3://${bucketname}/s3-demo-sync/
}

ec2ami () {
	echo ""
	echo "Please wait"
	echo "List of available Instances running in the current Region"
	aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region ${region}|egrep "PrivateIpAddress|InstanceId"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A1
	echo "Please Enter the Instance Id"
	read instanceid
	if [ "${instanceid}" == "" ]; then
	echo -e "Please Enter the EC2 Instance Id, default values are not accepted here"
	else
	aws ec2 create-image --instance-id ${instanceid} --name ec2-custom-ami-`date +%Y%m%d-%H%M%s` --region ${region}
	fi
}

ec2snap () {
	echo ""
	echo "Please wait"
	echo "List of available Instances running in the current Region"
	aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region ${region}|egrep "PrivateIpAddress|InstanceId|Vol"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A2
	echo "Please Enter the Volume Id"
	read volid
	if [ "${volid}" == "" ]; then
        echo -e "Please Enter the Volume Id, default values are not accepted"
        else
	aws ec2 create-snapshot  --volume-id ${volid} --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=ec2-snapshot-'`date +%Y%m%d-%H%M%S`'}]' --region ${region}
	fi
}

elasticip () {
	echo "Please type 'yes' to Create Elastic IP, no to discard"
	read input
	if [ "${input}" == "yes" ]; then
	aws ec2 allocate-address
	else
	echo "Bye"
	fi

}
assignip() {
	echo "List of available Instances running in the current Region"
	aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region ${region}|egrep "PrivateIpAddress|InstanceId"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A1
	echo ""
	echo "List of Available PublicIP in Amazon Pool"
	aws ec2 describe-addresses|egrep "PublicIp|AllocationId"
	echo ""
	echo "Please enter the Instance  Id  where you want to attach Elastic IP"
	read instanceid
	echo "Please enter the Public IP"
	read publicip
	if [[  "$instanceid" != "" ]] && [[  "$publicip" != "" ]]; then
		aws ec2 associate-address --instance-id ${instanceid} --public-ip ${publicip}
	else
		echo "Please Enter the EC2 Instance Id and the Public IP, default values are not accepted"
	fi
}

listingeip () {
	        echo "List of Available PublicIP in Amazon Pool"
	        aws ec2 describe-addresses|egrep "PublicIp|AllocationId|InstanceId"

}

stopec2 () {
	echo "Please wait"
	echo "List of available Instances running in the current Region"
        aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region ${region}|egrep "PrivateIpAddress|InstanceId|Vol"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A2
	echo "Please Enter the Instance Id"
        read instanceid
        if [ "${instanceid}" == "" ]; then
        echo -e "Please Enter the EC2 Instance Id, default values are not accepted here"
	echo "Bye"
        else
		aws ec2 stop-instances --instance-ids ${instanceid} --region ${region}
        fi
}

startec2 () {
        echo "Please wait"
        echo "List of available Instances running in the current Region"
        aws ec2 describe-instances --region ${region}|egrep "PrivateIpAddress|InstanceId|Vol"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A2
        echo "Please Enter the Instance Id"
        read instanceid
        if [ "${instanceid}" == "" ]; then
        echo -e "Please Enter the EC2 Instance Id, default values are not accepted here"
        echo "Bye"
        else
                aws ec2 start-instances --instance-ids ${instanceid} --region ${region}
        fi
}

rebootec2 () {
	        echo "Please wait"
        echo "List of available Instances running in the current Region"
        aws ec2 describe-instances --filters Name=instance-state-name,Values=running --region ${region}|egrep "PrivateIpAddress|InstanceId|Vol"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A2
        echo "Please Enter the Instance Id"
        read instanceid
        if [ "${instanceid}" == "" ]; then
        echo -e "Please Enter the EC2 Instance Id, default values are not accepted here"
        echo "Bye"
        else
                aws ec2 reboot-instances --instance-ids ${instanceid} --region ${region}
        fi
}

terminateec2() {
	                echo "Please wait"
        echo "List of available Instances running in the current Region"
        aws ec2 describe-instances --region ${region}|egrep "PrivateIpAddress|InstanceId|Vol"|cut -d: -f1,2|grep -v PrivateIpAddresses|grep InstanceId -A2
        echo "Please Enter the Instance Id"
        read instanceid
        if [ "${instanceid}" == "" ]; then
        echo -e "Please Enter the EC2 Instance Id, default values are not accepted here"
        echo "Bye"
        else
                aws ec2 terminate-instances --instance-ids ${instanceid} --region ${region}
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
#echo "Please Press enter for option"
while true;
do
	echo ""
	echo -e "${BIYellow}Please Press enter for option${BIWhite}"
	read opt
	echo ""
	echo -en "${BIGreen} 			!!! Welcome to PK Demo on Cloud Foundation!!! ${BICyan} \n"
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
	echo -e "11: Creating S3 Bucket"
	echo ""
	echo -e "12: Creating files and pushing/copying Sample files to S3 Bucket"
	echo ""
	echo -e "13: Listing the S3 bucket"
	echo ""
	echo -e "14: Syncing files to S3 bucket"
	echo ""
	echo -e "15: Creating EC2 AMI"
	echo ""
	echo -e "16: Creating EC2 Volume Snapshot"
	echo ""
	echo -e "17: Creating Elastic IP"
	echo ""
	echo -e "18: Attaching Elastic IP to an EC2 Instance"
	echo ""
	echo -e "19: Listing Available Elastic IP Addess"
	echo ""
	echo -e "20: Stop EC2 Instance"
	echo ""
	echo -e "21: Start EC2 Instance"
	echo ""
	echo -e "22: Reboot EC2 Instance"
	echo ""
	echo -e "23: Terminate EC2 Instance"
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
		ecs-cluster;
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
	11)	echo "Creating S3 Bucket"
		s3bucket
		continue;
		;;
	12)	echo "Creating files and pushing/copying Sample files to S3 Bucket"
		s3push
		continue;
		;;
	13) 	echo "Listing the S3 bucket"
		lists3
		continue;
		;;
	14) 	echo "Syncing the files to S3"
		syncs3
		continue;
		;;
	15)	echo "Creating AMI of an EC2 Instance"
		ec2ami
		continue;
		;;
	16)	echo "Creating Snapshot"
		ec2snap
		continue;
		;;
	17)	echo "Creating Elastic IP"
		elasticip
		continue;
		;;
	18) 	echo "Assigning Elastic IP"
		assignip
		continue;
		;;
	19)	echo "Listing Available EIP"
		listingeip
		continue;
		;;
	20)	echo "Stop EC2 Instance"
		stopec2
		continue;
		;;
	21)	echo "Start EC2 Instance"
		startec2
		continue;
		;;
	22)	echo "Reboot EC2 Instance"
		rebootec2
		continue;
		;;
	23)	echo "Terminate EC2 Instance"
		terminateec2
		continue;
		;;
	0)	esac
		break;
done
