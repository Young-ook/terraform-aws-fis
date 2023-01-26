{
    "description": "Simulate disk full on ec2 instances",
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
