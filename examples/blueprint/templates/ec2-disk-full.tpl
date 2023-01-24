{
    "description": "Simulate EC2 disk full error",
    "targets": ${targets},
    "actions": ${actions},
    "stopConditions": ${alarms},
    "roleArn": "${role}",
    "logConfiguration": {
        "logSchemaVersion": 1,
        "cloudWatchLogsConfiguration": {
            "logGroupArn": "${logs}"
        }
    },
    "tags": { "Name": "Ec2DiskFull" }
}
