{
    "description": "Terminate kubernetes pods",
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
                "kubernetesKind": "PodChaos",
                "kubernetesNamespace": "chaos-mesh",
                "kubernetesSpec": "{\"selector\":{\"namespaces\":[\"sockshop\"],\"labelSelectors\":{\"name\":\"carts\"}},\"mode\":\"one\",\"action\": \"pod-kill\",\"gracePeriod\":\"0\"}"
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
    "tags": {"Name": "Inject pod failure using chaos mesh"}
}
