{
    "description": "Simulate memory stress on kubernetes pods",
    "targets": {
        "eks-cluster": {
            "resourceType": "aws:eks:cluster",
            "resourceArns": ["${eks}"],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "eks-kill-pod": {
            "actionId": "aws:eks:inject-kubernetes-custom-resource",
            "parameters": {
                "maxDuration": "PT5M",
                "kubernetesApiVersion": "chaos-mesh.org/v1alpha1",
                "kubernetesKind": "StressChaos",
                "kubernetesNamespace": "chaos-mesh",
                "kubernetesSpec": "{\"mode\": \"one\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"stressors\": {\"memory\": {\"workers\": 4,\"size\": \"256MB\"}}}"
            },
            "targets": {"Cluster": "eks-cluster"}
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
    "tags": {"Name": "StressPodMem"}
}
