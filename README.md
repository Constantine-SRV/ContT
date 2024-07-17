# ECS Task with Logging and Execute Command

This project demonstrates working with a C# container on AWS. It includes the following steps:

1. **Creating a Simple C# Container**: Based on the Blazor template with console output for button clicks on the Counter page. [Repository Link](https://github.com/Constantine-SRV/ContT/tree/master/ContT)
2. **GitHub Action for Building and Publishing the Container Image to AWS**: [GitHub Action Workflow](https://github.com/Constantine-SRV/ContT/blob/master/.github/workflows/docker-build.yml)
3. **GitHub Action for Terraform Deployment of the Container on AWS**: This includes enabling CloudWatch logging and root console access to the ECS cluster. [Terraform Deployment Workflow](https://github.com/Constantine-SRV/ContT/blob/master/.github/workflows/terraform-deploy.yml)

## Setup console access

Refer to the following resources for setup and access information:
- [AWS Knowledge Center](https://repost.aws/knowledge-center/fargate-ecs-exec-errors)
- [Non-root User Access](https://towardsthecloud.com/amazon-ecs-invalidparameterexception-executecommand)

### Commands for Console Access

Replace `simple-cluster` with the name of your cluster (line 159 in the Terraform code).

```console
C:\Users\Administrator>aws ecs list-tasks --cluster simple-cluster --query "taskArns" --output text
arn:aws:ecs:eu-north-1:637423446150:task/simple-cluster/f801f89ff0c94f1a9d85892e8768a9a3

C:\Users\Administrator>aws ecs execute-command --cluster simple-cluster --task arn:aws:ecs:eu-north-1:637423446150:task/simple-cluster/f801f89ff0c94f1a9d85892e8768a9a3 --container simple-container --interactive --command "/bin/bash"

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

Starting session with SessionId: ecs-execute-command-ng5b452mpexosbdxqx6x5oi73a
root@ip-10-0-1-133:/app# ls -lh
total 180K
-rwxr-xr-x 1 root root  71K Jul 16 18:45 ContT
-rw-r--r-- 1 root root  988 Jul 16 18:45 ContT.deps.json
-rw-r--r-- 1 root root  43K Jul 16 18:45 ContT.dll
-rw-r--r-- 1 root root  38K Jul 16 18:45 ContT.pdb
-rw-r--r-- 1 root root  469 Jul 16 18:45 ContT.runtimeconfig.json
-rw-r--r-- 1 root root  145 Jul 16 18:45 appsettings.Development.json
-rw-r--r-- 1 root root  142 Jul 16 18:45 appsettings.json
-rw-r--r-- 1 root root  481 Jul 16 18:45 web.config
drwxr-xr-x 3 root root 4.0K Jul 16 18:45 wwwroot
root@ip-10-0-1-133:/app# exit
exit

Exiting session with sessionId: ecs-execute-command-ng5b452mpexosbdxqx6x5oi73a.

C:\Users\Administrator>
```
Example of Online Container Logs Output
```console
C:\Users\Administrator>aws logs describe-log-streams --log-group-name /ecs/simple-container --query "logStreams[*].logStreamName" --output text
ecs-execute-command-arelm5xmkj4qxeahqsui6ajide  ecs-execute-command-ng5b452mpexosbdxqx6x5oi73a  ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3

C:\Users\Administrator>aws logs tail /ecs/simple-container --log-stream-name-prefix ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 --follow
2024-07-17T07:41:56.034000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 9 times 2024-07-17 07:41:56 ****
2024-07-17T07:41:56.314000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 10 times 2024-07-17 07:41:56 ****
2024-07-17T07:41:56.610000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 11 times 2024-07-17 07:41:56 ****
2024-07-17T07:41:56.779000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 12 times 2024-07-17 07:41:56 ****
2024-07-17T07:41:56.957000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 13 times 2024-07-17 07:41:56 ****
2024-07-17T07:41:57.128000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 14 times 2024-07-17 07:41:57 ****
2024-07-17T07:41:57.315000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 15 times 2024-07-17 07:41:57 ****
2024-07-17T07:41:57.506000+00:00 ecs/simple-container/f801f89ff0c94f1a9d85892e8768a9a3 **** The counter button pressed 16 times 2024-07-17 07:41:57 ****
