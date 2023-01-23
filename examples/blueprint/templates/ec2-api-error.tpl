{
    "description": "Simulate AWS API internal error",
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
    "tags": { "Name": "AwsApiInternalError" }
}
