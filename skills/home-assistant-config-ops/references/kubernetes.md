# Kubernetes Operations

Use the current `kubectl` context. Read values from `.deployment_info`.

Target the recorded workload directly for ordinary single-shot operations.
`kubectl exec` and `kubectl logs` accept workload targets such as
`deployment/<name>` and remove unnecessary pod-selection plumbing:

```bash
kubectl get -n <namespace> <workload>
kubectl exec -n <namespace> <workload> -c <container> -- hass --version
kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> status --short
kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> remote -v
kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> branch --show-current
kubectl logs -n <namespace> <workload> -c <container> --tail=200
```

This default fits the usual single-replica Home Assistant Deployment. If the
workload has multiple replicas or a rolling update is active, use an exact pod
only when replica identity affects the result. Report a workload that is not
Available instead of compensating with a more complicated selector.

For an approved Git fast-forward, save the revision, transfer the approved
branch, and validate before restart:

```bash
PREVIOUS_SHA=$(kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> rev-parse HEAD)
kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> pull --ff-only <remote> <branch>
kubectl exec -n <namespace> <workload> -c <container> -- hass --script check_config -c <config-path>
```

If validation fails, do not restart. Restore only after approval:

```bash
kubectl exec -n <namespace> <workload> -c <container> -- git -C <config-path> reset --hard "$PREVIOUS_SHA"
```

Resolve an exact pod only for commands that require a pod name, such as
`kubectl cp` or a pod-replacement restart. First list pods with the smallest
verified selector from `.deployment_info`. For a single-replica workload,
continue only when it shows exactly one intended Running pod:

```bash
kubectl get pod -n <namespace> -l <pod-selector>
POD=$(kubectl get pod -n <namespace> -l <pod-selector> --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
test -n "$POD"
kubectl wait -n <namespace> --for=condition=Ready "pod/$POD" --timeout=60s
```

For an approved pod-replacement restart, delete only that verified pod and
wait for its deletion and a Ready replacement:

```bash
kubectl delete pod -n <namespace> "$POD"
kubectl wait -n <namespace> --for=delete "pod/$POD" --timeout=60s
kubectl wait -n <namespace> --for=condition=Ready pod -l <pod-selector> --timeout=120s
```

`kubectl cp` requires the pod name. Use it only for an explicitly approved copy
and never to bypass the normal Git flow:

```bash
kubectl cp -n <namespace> <local-path> "$POD":<remote-path> -c <container>
```

Reverse source and destination to copy from the pod.
