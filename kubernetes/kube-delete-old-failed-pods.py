from kubernetes import client, config
from datetime import datetime, timedelta
# Load the kube config from the default location
config.load_kube_config()
# Create a client for the Kubernetes API
v1 = client.CoreV1Api()
# Get the current date and time
now = datetime.now()
# Get all the pods in the namespace
pods = v1.list_namespaced_pod("default")
# Iterate over the pods
for pod in pods.items:
    # Check if the pod is in a failed or error state
    if pod.status.phase in ["Failed", "Error"]:
        # Get the start time of the pod
        start_time = pod.status.start_time
        # Check if the pod is older than one week
        if now - start_time > timedelta(weeks=1):
            # Delete the pod
            v1.delete_namespaced_pod(pod.metadata.name, "default")
