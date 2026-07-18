#!/usr/bin/env bash
# TJ-ARCH-MOB-001 compliant
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
gitops="$repo_root/deploy/gitops"

if rg -n 'kubectl apply|helm upgrade|argocd sync' "$repo_root/.github/workflows"; then
  echo "direct deployment command found in CI" >&2
  exit 1
fi

if rg -n '^[[:space:]]+(data|stringData):' "$gitops" --glob '*.yaml'; then
  echo "inline Kubernetes secret data found" >&2
  exit 1
fi

while IFS= read -r kustomization; do
  kustomize build "$(dirname "$kustomization")" >/dev/null
done < <(find "$gitops" -name kustomization.yaml -type f | sort)

for component in nginx-ingress nginx-gateway traefik-ingress traefik-gateway envoy-gateway; do
  test -f "$gitops/components/edge/$component/kustomization.yaml" || {
    echo "missing edge component: $component" >&2
    exit 1
  }
done

test -f "$repo_root/docs/deployment/edge-routing-and-tls.md"
rg -q 'wildcard.*DNS-01|Wildcard.*DNS-01' "$repo_root/docs/deployment/edge-routing-and-tls.md"
rg -q 'Certbot' "$repo_root/docs/deployment/edge-routing-and-tls.md"

echo "GitOps validation passed"
