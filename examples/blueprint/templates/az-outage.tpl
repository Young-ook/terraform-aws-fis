{
    "description": "Siulate an AZ outage",
    "targets": {
        "az": {
            "resourceType": "aws:ec2:subnet",
            "parameters": {
                "availabilityZoneIdentifier": "${az}",
                "vpc": "${vpc}"
            },
            "selectionMode": "ALL"
        },
        "rds-cluster": {
            "resourceType": "aws:rds:cluster",
            "resourceArns": ${rds},
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "AZOutage": {
            "actionId": "aws:network:disrupt-connectivity",
            "description": "Block all EC2 traffics from and to the subnets",
            "parameters": {
                "duration": "${duration}",
                "scope": "availability-zone"
            },
            "targets": {
                "Subnets": "az"
            }
        },
        "FailOverCluster": {
            "actionId": "aws:rds:failover-db-cluster",
            "description": "Failover Aurora cluster",
            "parameters": {},
            "targets": {
                "Clusters": "rds-cluster"
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
    "tags": {
        "Name": "AZOutage"
    }
}
