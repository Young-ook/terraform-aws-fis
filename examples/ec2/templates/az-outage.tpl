{
    "description": "Run an AZ Outage fault injection on the specified availability zone",
    "targets": {},
    "actions": {
        "AZOutage": {
            "actionId": "aws:ssm:start-automation-execution",
            "description": "Run an az network outage using ssm",
            "parameters": {
                "documentArn": "${ssm_doc}",
                "documentParameters": "{\"Region\": \"${region}\", \"AvailabilityZone\": \"${az}\", \"VPCId\": \"${vpc}\", \"Duration\": \"${duration}\", \"AutomationAssumeRole\": \"${ssm_role}\"}",
                "maxDuration": "PT30M"
            },
            "targets": {}
        }
    },
    "stopConditions": [
        {
            "source": "aws:cloudwatch:alarm",
            "value": "${alarm}"
        }
    ],
    "roleArn": "${fis_role}",
    "logConfiguration": {
        "logSchemaVersion": 1,
        "cloudWatchLogsConfiguration": {
            "logGroupArn": "${logs}"
        }
    },
    "tags": {
        "Name": "AZOutage"
    }
}
