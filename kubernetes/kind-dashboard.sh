#/bin/bash

# kubectl delete --cascade=true ns kubernetes-dashboard --force
# kubectl delete csr kubernetes-dashboard

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
kubectl get pod -n kubernetes-dashboard
kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
token=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
echo $token

echo "run : kubectl proxy"
echo "go to : http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
echo "clean with : kubectl delete --cascade=true ns kubernetes-dashboard --force"
