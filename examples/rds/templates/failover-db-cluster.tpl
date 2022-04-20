{
    "tags": {
        "Name": "FailoverCluster"
    },
    "description": "Runs the failover action on the target Aurora DB cluster",
    "targets": {
        "rds-cluster": {
            "resourceType": "aws:rds:cluster",
            "resourceArns": [
                "${cluster}"
            ],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "FailOverCluster": {
            "actionId": "aws:rds:failover-db-cluster",
            "description": "Failover Aurora cluster",
            "parameters": {},
            "targets": {
                "Clusters": "rds-cluster"
            }
        }
    },
    "stopConditions": [
        {
            "source": "aws:cloudwatch:alarm",
            "value": "${alarm}"
        }
    ],
    "roleArn": "${role}"
}
