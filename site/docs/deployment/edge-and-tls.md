---
sidebar_position: 2
title: Edge routing and TLS
---

# Choose one edge

Supported components include F5 NGINX Ingress Controller, NGINX Gateway Fabric,
Traefik in Ingress or Gateway API mode, and pure Envoy Gateway. New deployments
must not use the retired community `kubernetes/ingress-nginx` controller.

All options route the same `knowme-web` Service. Ingress examples select an
`IngressClass`; Gateway examples use `Gateway`, HTTPS listeners, and `HTTPRoute`.
The platform GitOps repository installs the selected controller and Gateway API
CRDs. The application overlay adds exactly one edge component.

cert-manager is the Kubernetes-native default. HTTP-01 is appropriate for an
individual public hostname. Wildcard certificates require DNS-01 and cloud workload
identity for Cloud DNS, Azure DNS, or Route 53. Certbot is supported as secured
external DNS-01 automation that writes to a cloud secret manager; certificate keys
and DNS credentials never enter Git.

## NGINX Ingress and Traefik Ingress

Install the active F5 NGINX Ingress Controller or Traefik through the platform
GitOps repository. The application overlay owns only the portable route. Select
`nginx` or `traefik`; never install both for the same hostname.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: knowme-web
  namespace: knowme
spec:
  ingressClassName: nginx # use traefik for Traefik Kubernetes Ingress
  tls:
    - hosts: [knowme.example.com]
      secretName: knowme-web-tls
  rules:
    - host: knowme.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: {name: knowme-web, port: {number: 8080}}
```

F5 also supplies NGINX-specific resources, and Traefik supplies middleware CRDs,
but add those only in optional controller-specific components. Keep the base route
portable.

## NGINX Gateway Fabric, Traefik Gateway, and Envoy Gateway

Install Gateway API CRDs and exactly one active implementation. The portable
objects are identical apart from `gatewayClassName`:

| Implementation | `gatewayClassName` |
|---|---|
| NGINX Gateway Fabric | `nginx` |
| Traefik Gateway provider | `traefik` |
| Envoy Gateway | `eg` |

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: knowme-edge, namespace: knowme}
spec:
  gatewayClassName: eg # nginx, traefik, or eg
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: knowme.example.com
      tls:
        mode: Terminate
        certificateRefs: [{kind: Secret, name: knowme-web-tls}]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: knowme-web, namespace: knowme}
spec:
  parentRefs: [{name: knowme-edge}]
  hostnames: [knowme.example.com]
  rules:
    - backendRefs: [{name: knowme-web, port: 8080}]
```

Envoy Gateway is the pure Envoy option: no NGINX or Traefik controller participates.
In a shared cluster, the platform may own the `Gateway` while the application owns
the `HTTPRoute`; use `allowedRoutes` to constrain attachment.

## Let’s Encrypt with cert-manager

Use the Let’s Encrypt staging endpoint until issuance, HTTPS routing, and renewal
all pass. HTTP-01 can issue one public hostname and requires port 80 to reach the
selected Ingress controller. A wildcard cannot use HTTP-01.

Use DNS-01 for the apex and wildcard names:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: {name: knowme-wildcard, namespace: knowme}
spec:
  secretName: knowme-wildcard-tls
  issuerRef: {name: letsencrypt-wildcard-production, kind: ClusterIssuer}
  dnsNames: [example.com, "*.example.com"]
```

Choose one narrowly scoped workload-identity solver—never a static cloud key:

```yaml
# GKE / Cloud DNS
dns01:
  cloudDNS: {project: PROJECT_ID}
```

```yaml
# AKS / Azure DNS
dns01:
  azureDNS:
    subscriptionID: SUBSCRIPTION_ID
    resourceGroupName: DNS_RESOURCE_GROUP
    hostedZoneName: example.com
    environment: AzurePublicCloud
    managedIdentity: {clientID: CERT_MANAGER_CLIENT_ID}
```

```yaml
# EKS / Route 53
dns01:
  route53: {region: us-east-1, hostedZoneID: HOSTED_ZONE_ID}
```

Point an Ingress `tls.secretName` or a Gateway listener `certificateRefs` at
`knowme-wildcard-tls`. A wildcard listener uses `hostname: "*.example.com"`.

## Wildcards with external Certbot

Certbot is an external automation option, not an unmanaged application sidecar:

```bash
certbot certonly --non-interactive --agree-tos \
  --email platform@example.com \
  --dns-PROVIDER \
  -d example.com -d '*.example.com'
```

Run it in a secured certificate environment. Write the renewed certificate to
Google Secret Manager, Azure Key Vault, or AWS Secrets Manager and let External
Secrets or Secrets Store CSI materialize `knowme-wildcard-tls`. Never commit the
certificate key, DNS credentials, or base64-encoded TLS Secret.

## Overlay and verification

An overlay composes one edge component with one certificate strategy:

```yaml
resources:
  - ../../cloud/gke
  - ../../../../components/edge/envoy-gateway
  - ../../../../components/certificates/dns01
```

Prove route acceptance, HTTP-to-HTTPS behavior, the served chain and hostname,
two wildcard subdomains, and renewal first against Let’s Encrypt staging. ArgoCD
owns reconciliation; application CI never runs a direct cluster deployment.

The complete tracked manifests live under `deploy/gitops/components/edge` and
`deploy/gitops/components/certificates`.
