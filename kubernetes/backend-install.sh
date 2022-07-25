#!/bin/bash

portforward=0

kind create cluster --config kind-example-config.yaml

# dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
kubectl get pod -n kubernetes-dashboard
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
token=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
echo $token

# ingress
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml

# etcd
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install myetcd --set persistence.enabled=false --set auth.rbac.enabled=false --set ingress.enabled=true bitnami/etcd
if [[ ${portforward} -eq 1 ]]; then
    # kubectl port-forward --namespace default svc/myetcd 2379:2379 &
    kubectl port-forward $(kubectl get pods -l app.kubernetes.io/name=etcd -o jsonpath='{.items[0].metadata.name}') 2379:2379 &
fi
#kubectl expose service myetcd --type=LoadBalancer --port=2379 --target-port=80 --name=myetcdexposition

# pulsar
helm repo add datastax-pulsar https://datastax.github.io/pulsar-helm-chart
helm repo update
curl -LOs https://datastax.github.io/pulsar-helm-chart/examples/dev-values.yaml
helm install pulsar -f dev-values.yaml datastax-pulsar/pulsar

if [[ ${portforward} -eq 1 ]]; then
    kubectl port-forward $(kubectl get pods -l component=adminconsole -o jsonpath='{.items[0].metadata.name}') 8888:80 & 
    kubectl port-forward $(kubectl get pods -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') 3001:3000 &
    kubectl port-forward $(kubectl get pods -l component=proxy -o jsonpath='{.items[0].metadata.name}') 8080:8080 &
    kubectl port-forward $(kubectl get pods -l component=proxy -o jsonpath='{.items[0].metadata.name}') 6650:6650 &
    # kubectl exec $(kubectl get pods -l component=bastion -o jsonpath="{.items[*].metadata.name}") -it -- /bin/bash
fi

