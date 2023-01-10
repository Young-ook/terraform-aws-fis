{
    "description": "Simulate network delay on kubernetes pods",
    "targets": {
        "eks-cluster": {
            "resourceType": "aws:eks:cluster",
            "resourceArns": ["${eks}"],
            "selectionMode": "ALL"
        }
    },
    "actions": {
        "eks-pod-netdelay": {
            "actionId": "aws:eks:inject-kubernetes-custom-resource",
            "parameters": {
                "maxDuration": "PT5M",
                "kubernetesApiVersion": "chaos-mesh.org/v1alpha1",
                "kubernetesKind": "NetworkChaos",
                "kubernetesNamespace": "chaos-mesh",
                "kubernetesSpec": "{\"mode\": \"one\",\"selector\": {\"labelSelectors\": {\"name\": \"carts\"}},\"action\":\"delay\",\"delay\": {\"latency\":\"10ms\"},\"duration\":\"40s\"}"
            },
            "targets": {"Cluster": "eks-cluster"}
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
    "tags": {"Name": "PodNetworkDelay"}
}
