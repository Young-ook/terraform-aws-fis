{
    "description": "Simulate cpu stress on kubernetes pods",
    "targets": {
        "eks-cluster": {
            "resourceType": "aws:eks:cluster",
            "resourceArns": ["${eks}"],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "eks-pod-cpu": {
            "actionId": "aws:eks:inject-kubernetes-custom-resource",
            "parameters": {
                "maxDuration": "PT5M",
                "kubernetesApiVersion": "chaos-mesh.org/v1alpha1",
                "kubernetesKind": "StressChaos",
                "kubernetesNamespace": "chaos-mesh",
                "kubernetesSpec": "{\"mode\": \"all\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"stressors\": {\"cpu\": {\"workers\": 1,\"load\": 60}},\"duration\":\"1m\"}"
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
    "tags": {"Name": "StressPodCpu"}
}
