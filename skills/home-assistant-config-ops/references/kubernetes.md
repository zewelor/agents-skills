# Kubernetes Operations

Use the current `kubectl` context. Read values from `.deployment_info`.

Select the newest Running pod and wait until Ready. Use that exact pod for
exec, logs, validation, restart, and copies:

```bash
POD=$(kubectl get pod -n <namespace> -l <pod-selector> --field-selector=status.phase=Running --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')
test -n "$POD"
kubectl wait -n <namespace> --for=condition=Ready "pod/$POD" --timeout=60s
```

If selection or readiness fails, report and stop. Read-only checks:

```bash
kubectl get -n <namespace> <workload>
kubectl exec -n <namespace> "$POD" -c <container> -- hass --version
kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> status --short
kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> remote -v
kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> branch --show-current
kubectl logs -n <namespace> "pod/$POD" -c <container> --tail=200
```

For an approved Git fast-forward, save the revision, transfer the approved
branch, and validate before restart:

```bash
PREVIOUS_SHA=$(kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> rev-parse HEAD)
kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> pull --ff-only <remote> <branch>
kubectl exec -n <namespace> "$POD" -c <container> -- hass --script check_config -c <config-path>
```

If validation fails, do not restart. Restore only after approval:

```bash
kubectl exec -n <namespace> "$POD" -c <container> -- git -C <config-path> reset --hard "$PREVIOUS_SHA"
```

For an approved pod-replacement restart, delete only the selected current pod,
then select and wait for the replacement using the same procedure:

```bash
kubectl delete pod -n <namespace> "$POD"
```

`kubectl cp` requires the pod name. Use it only for an explicitly approved copy
and never to bypass the normal Git flow:

```bash
kubectl cp -n <namespace> <local-path> "$POD":<remote-path> -c <container>
```

Reverse source and destination to copy from the pod.
