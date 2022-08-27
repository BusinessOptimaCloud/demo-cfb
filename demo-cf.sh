#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"
source /root/demo-cfb/variable.sh
source /root/demo-cfb/demo-cfb/variable.sh


if [ -f ~/.ssh/id_rsa.pub ]; then
	echo ""
else
  echo -e "\n\n\n" | ssh-keygen -t rsa
fi

#key='/root/jenkins_ec2.pem'
ec2instancecreation () {
echo "Enter the number of instance required"
read inscount
if [  "$inscount" == "" ]; then
inscount=1
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
app="/tmp/app-deploy.txt"
>${app}

cat <<EOF >${app}
#!/bin/bash'
date

apt update && apt install docker.io git -y
cd "/root/"
codepath="/root/sentiment-analysis/containerized_webapp/"
git clone https://github.com/BusinessOptimaCloud/sentiment-analysis.git
cd ${codepath}
cat_image_id=`docker images | grep -w sentimentapp:ver1 | awk '{print $3}'`
if [ $cat_image_id=="" ]; then
   continue;
else
   docker rmi ${cat_image_id} -f
fi

dockerprocess=`systemctl status docker|grep Active|grep dead|wc -l`

if [ ${dockerprocess} -eq 1 ]; then
    systemctl restart docker
fi

docker build -t sentimentapp:ver1 ${codepath}
cat_image_id=`docker images | grep -w sentimentapp | awk '{print $3}'`
container_id=`docker ps|grep "sentimentapp"|awk '{print $1}'`
docker stop ${container_id}
docker rm ${container_id}
docker run -itd --name sentimentapp -p 80:5000 ${cat_image_id}
app_status=`docker ps|grep sentimentapp|wc -l`
public_ip=`curl http://checkip.amazonaws.com`


################################################PLEASE OPEN PORT 80 in EC2 Container#############
if [ ${app_status} -eq 1 ]; then
	echo ""
	echo ""
	echo "YOUR SENTIMENT APP IS UP AND RUNNING"
	echo "Please Use the below URL to OPEN SENTIMENT APP"
	echo -e "http://${public_ip}"
else
	echo "Container not started please check"
fi
EOF

app="/opt/deployapp.txt"
aws ec2 run-instances --image-id ami-068257025f72f470d --count 1 --instance-type t2.medium --key-name jenkins_ec2 --security-group-ids sg-07fc867927cc40d18 --subnet-id subnet-0d0270077596be3a6 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Senti-App-DemoInstance}]' --user-data file:///${app}  --region ap-south-1
}

s3mount () {
key='/root/jenkins_ec2.pem'
#ip=`ec2 describe-instances  --region ap-south-1|grep PrivateIpAddress |cut -d'"' -f4|sort -u|tail -1`
echo "Enter the IP where S3 needs to be mounted"
read ip
	ssh -i ${key} ubuntu@${ip} sudo apt install s3fs -y
	ssh -i ${key} ubuntu@${ip} sudo echo "thomasinnovation /s3-mount/          fuse.s3fs rw,nosuid,nodev,allow_other,umask=0022,connect_timeout=600,readwrite_timeout=300,_netdev 0 0" >> /etc/fstab
	ssh -i ${key} ubuntu@${ip} sudo mkdir /s3-mount
	ssh -i ${key} ubuntu@${ip} sudo mount -a
	ssh -i ${key} ubuntu@${ip} df -h
	ssh -i ${key} ubuntu@${ip} ls -ltr /s3-mount/
}

efsmount () {
key='/root/jenkins_ec2.pem'
#ip=`ec2 describe-instances  --region ap-south-1|grep PrivateIpAddress |cut -d'"' -f4|sort -u|tail -1`
echo "Enter the IP where S3 needs to be mounted"
read ip
	ssh -i ${key} ubuntu@${ip} sudo apt install nfs-common -y
	ssh -i ${key} ubuntu@${ip} sudo mkdir /efs-data-store/
	sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.31.44.144:/ /efs-data-store/
        ssh -i ${key} ubuntu@${ip} ls -ltr /efs-data-store/; df -h
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

echo "Please Select ..."
while true;
do
	echo -e "1: Creating EC2 Instance(VM)"
	echo -e "2: Creating EC2 Instance with Single Demo App"
	echo -e "3: Mount S3 Storage to EC2 Instance"
	echo -e "4: Mount EFS to EC2 Instance"
	echo -e "5: EC2 Instance Demo App with Load Balancer, Auto Scaling"
	echo -e "6: Destroy Demo App"
	echo -e "7: Creating ECS Cluster and Deploy Demo APp"
	echo -e "8: Quit from the script"
	echo -e "PRESS ENTER TO EXIT"
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
	4)      echo "Mount EFS to EC2 Instance"
	        efsmount;
		continue;
		;;
	5) 	echo "EC2 Instance Demo App with Load Balancer, Auto Scaling"
		terraformdeploy;
		continue;
		;;
	6)	echo "Destroy demo app"
		destroydemoapp;
		continue;
		;;
	7)	echo "Creating ECS Cluster and Deploy App"
		insertingdata;
		continue;
		;;
	8)	esac
		break;
done
