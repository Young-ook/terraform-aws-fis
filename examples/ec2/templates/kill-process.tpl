{
    "description": "Run a process kill fault injection on the specified instance",
    "targets": {
        "ec2-instances": {
            "resourceType": "aws:ec2:instance",
            "resourceTags": {
                "Name": "${asg}"
            },
            "filters": [
                {
                    "path": "Placement.AvailabilityZone",
                    "values": [
                        "${az}"
                    ]
                },
                {
                    "path": "State.Name",
                    "values": [
                        "running"
                    ]
                }
            ],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "KillProcess": {
            "actionId": "aws:ssm:send-command",
            "description": "run to kill process using ssm",
            "parameters": {
                "duration": "PT2M",
                "documentArn": "arn:aws:ssm:${region}::document/AWSFIS-Run-Kill-Process",
                "documentParameters": "{\"ProcessName\": \"${process}\"}"
            },
            "targets": {
                "Instances": "ec2-instances"
            }
        }
    },
    "stopConditions": [
        {
            "source": "aws:cloudwatch:alarm",
            "value": "${alarm}"
        }
    ],
    "roleArn": "${role}",
    "logConfiguration": {
        "logSchemaVersion": 1,
        "cloudWatchLogsConfiguration": {
            "logGroupArn": "${logs}"
        }
    },
    "tags": {
        "Name": "KillProcess"
    }
}
