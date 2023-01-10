{
    "description": "Simulate network delay on ec2 instances",
    "targets": {
        "ec2-instances": {
            "resourceType": "aws:ec2:instance",
            "resourceTags": {
                "env": "prod"
            },
            "filters": [
                {
                    "path": "State.Name",
                    "values": ["running"]
                }
            ],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "NetworkLatency": {
            "actionId": "aws:ssm:send-command",
            "parameters": {
                "duration": "PT5M",
                "documentArn": "arn:aws:ssm:${region}::document/AWSFIS-Run-Network-Latency",
                "documentParameters": "{\"DurationSeconds\": \"300\", \"InstallDependencies\": \"True\", \"DelayMilliseconds\": \"100\"}"
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
    "tags": {"Name": "EC2NetworkDelay"}
}
