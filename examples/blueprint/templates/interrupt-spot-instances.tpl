{
    "description": "Interrupt EC2 Spot Instance",
    "targets": {
        "one-instance": {
            "resourceType": "aws:ec2:spot-instance",
            "resourceTags": ${targets},
            "filters": [
                {
                    "path": "State.Name",
                    "values": [
                        "running"
                    ]
                }
            ],
            "selectionMode": "COUNT(1)"
        }
    },
    "actions": {
        "TerminateInstances": {
            "actionId": "aws:ec2:send-spot-instance-interruptions",
            "description": "interrupt ec2 spot instances",
            "parameters": {
                "durationBeforeInterruption": "PT2M"
            },
            "targets": {
                "SpotInstances": "one-instance"
            }
        }
    },
    "stopConditions": ${alarm},
    "roleArn": "${role}",
    "logConfiguration": {
        "logSchemaVersion": 1,
        "cloudWatchLogsConfiguration": {
            "logGroupArn": "${logs}"
        }
    },
    "tags": {"Name": "InterruptSpotEC2"}
}
