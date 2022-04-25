{
    "description": "Reboot DB instances on the target DB instance",
    "targets": {
        "rds-instances": {
            "resourceType": "aws:rds:db",
            "resourceArns": [
                "${db}"
            ],
            "filters": [
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
        "RebootDBInstances": {
            "actionId": "aws:rds:reboot-db-instances",
            "description": "Reboot DB instances",
            "parameters": {
                "forceFailover": "false"
            },
            "targets": {
                "DBInstances": "rds-instances"
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
        "Name": "RebootDBInstances"
    }
}
