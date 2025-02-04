"""
Apply a TTL logic to delete pods in the current namespace.
Input parameters from environment variables:
    - MAX_AGE_HOURS: if a pod not in state (Running, Pending) has its creation time older than this, then delete it.
    - MAX_AGE_PENDING_HOURS: [optional] if a pod in state Pending has its creation time older than this, then delete it. Disabled by default.
    - MAX_AGE_SUCEEDED_HOURS: [optional] if a pod in state Suceeded has its creation time older than this, then delete it.
    - NAMESPACE: [optional] default to current namespace.
"""

from kubernetes import client, config
from datetime import datetime, timedelta, timezone
import os


def delete_old_pods(namespace, max_age_hours, max_age_pending_hours=0, max_age_succeeded_hours=0, verbose=False):
    now = datetime.now(timezone.utc)
    print(f"calling delete_old_pods at {now} on NS {namespace} with parameters: {max_age_hours} / {max_age_pending_hours} / {max_age_succeeded_hours}")

    try:
        # use the kube config from the pod itself
        config.load_incluster_config()
        v1 = client.CoreV1Api()
        # set default namespace
        if not namespace:
            namespace = open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read()
        print(f"list pods in namespace {namespace}")
        pods = v1.list_namespaced_pod(namespace)
    except:
        # use the kube config from the default config file (fallback)
        config.load_kube_config()
        v1 = client.CoreV1Api()
        # set default namespace
        if not namespace:
            namespace = open("/var/run/secrets/kubernetes.io/serviceaccount/namespace").read()
        print(f"list pods in namespace {namespace}")
        pods = v1.list_namespaced_pod(namespace)

    # Iterate over the pods
    for pod in pods.items:
        if verbose:
            print(f"checking pod {namespace}/{pod.metadata.name} with status {pod.status.phase} created at {pod.metadata.creation_timestamp} started at {str(pod.status.start_time)}")
        # Check if the pod is in a Failed or Unknown or Succeeded or Pending state
        if pod.status.phase not in ["Running"]:
            # Get the start time of the pod
            creation_time = pod.metadata.creation_timestamp
            start_time = pod.status.start_time

            mark_for_deletion = False
            # Check if the pod is older than expected
            try:
                if max_age_pending_hours and pod.status.phase == "Pending" and now - creation_time > timedelta(hours=max_age_pending_hours):
                    mark_for_deletion = True
                elif max_age_succeeded_hours and pod.status.phase == "Succeeded" and now - creation_time > timedelta(hours=max_age_succeeded_hours):
                    mark_for_deletion = True
                elif pod.status.phase != "Pending" and now - creation_time > timedelta(hours=max_age_hours):
                    mark_for_deletion = True
            except:
                print(f"skipped pod {namespace}/{pod.metadata.name} in status {pod.status.phase} created at {creation_time} started at {str(pod.status.start_time)}")

            if mark_for_deletion:
                print(f"delete pod {namespace}/{pod.metadata.name} in status {pod.status.phase} created at {creation_time} started at {str(pod.status.start_time)}")
                v1.delete_namespaced_pod(pod.metadata.name, namespace)

    print("Done")


if __name__ == "__main__":
    namespace = os.environ.get("NAMESPACE", None)
    # default to 1 week
    max_age_hours = int(os.environ.get("MAX_AGE_HOURS", 168))
    max_age_pending_hours = int(os.environ.get("MAX_AGE_PENDING_HOURS", 0))
    max_age_succeeded_hours = int(os.environ.get("MAX_AGE_SUCEEDED_HOURS", 0))
    delete_old_pods(namespace, max_age_hours, max_age_pending_hours, max_age_succeeded_hours)
