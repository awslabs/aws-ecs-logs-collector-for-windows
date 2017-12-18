# AWS ECS Logs Collector For Windows

This project was created to collect Amazon ECS log files and OS logs for troubleshooting Amazon ECS on Windows customer support cases.


## Supported Operating System

Windows 2016

## Collected information

System and Application Event Logs

OS System Information

Docker logs

Amazon ECS agent Logs

## Results

Creates a collect.zip file in the same folder as the script 

## Usage

Run this script as an elevated user:

# .\ecs-logs-collector.ps1


The script can be used in normal(Brief) or debug mode.

## Example output

This script can be used in normal or debug mode

### Example output in normal mode

The following output shows this project running in normal mode:

# .\ecs-logs-collector.ps1
Running Default(Brief) Mode

Cleaning up directory
OK

Creating temporary directory
OK

Collecting System information
OK

Checking free disk space
C: drive has 75% free space
OK

Collecting System Logs
OK

Collecting Application Logs
OK

Collecting Volume info
OK

Collecting Windows Firewall info

Collecting Rules for Domain profile

Collecting Rules for Private profile

Collecting Rules for Public profile
OK

Collecting installed applications list
OK

Collecting Services list
OK

Collecting Docker daemon information
OK

Collecting ECS Agent logs
OK

Inspect running Docker containers and gather Amazon ECS container agent data
OK

Collecting Docker daemon logs
OK

Archiving gathered data
OK

### Example output in debug mode

The following output shows this script running with debug mode. Note that running in debug mode restarts Docker and the Amazon ECS agent.

# .\ecs-logs-collector.ps1 -RunMode debug
Running Debug Mode

Cleaning up directory
OK

Enabling debug mode for the Docker Service
[SC] ChangeServiceConfig SUCCESS
OK

Enabling debug mode for the Amazon ECS container agent
Restarting the Amazon ECS container agent to enable debug mode
OK

Creating temporary directory
OK

Collecting System information
OK

Checking free disk space
C: drive has 75% free space
OK

Collecting System Logs
OK

Collecting Application Logs
OK

Collecting Volume info
OK

Collecting Windows Firewall info

Collecting Rules for Domain profile

Collecting Rules for Private profile

Collecting Rules for Public profile
OK

Collecting installed applications list
OK

Collecting Services list
OK

Collecting Docker daemon information
OK

Collecting ECS Agent logs
OK

Inspect running Docker containers and gather Amazon ECS container agent data
OK

Collecting Docker daemon logs
OK

Archiving gathered data
OK


## Contributing

Please [create a new GitHub issue](https://github.com/awslabs/aws-ecs-logs-collector-for-windows/issues/new) for any feature requests, bugs, or documentation improvements.

Where possible, [submit a pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/) for the change.


## License

This library is licensed under the Apache 2.0 License. 


