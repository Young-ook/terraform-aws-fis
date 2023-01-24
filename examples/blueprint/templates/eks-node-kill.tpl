{
    "description": "Simulate shutdown of EKS nodes",
    "targets": {
        "eks-nodes": {
            "resourceType": "aws:eks:nodegroup",
            "resourceArns": [
                "${nodegroup}"
            ],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "eks-node-termination": {
            "actionId": "aws:eks:terminate-nodegroup-instances",
            "parameters": {
                "instanceTerminationPercentage": "40"
            },
            "targets": {
                "Nodegroups": "eks-nodes"
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
        "Name": "TerminateEKSNodes"
    }
}
