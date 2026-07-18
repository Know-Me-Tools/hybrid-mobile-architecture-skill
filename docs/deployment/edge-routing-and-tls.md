# Kubernetes edge routing and TLS standard

This standard gives KnowMe deployments four supported edge choices while keeping
the application manifests independent of the controller. Choose exactly one edge
component per environment and let ArgoCD reconcile it. Terraform/OpenTofu owns the
controller prerequisites, public IP, DNS zone, workload identity, and cloud IAM.

## Controller decision

| Need | Recommended component | API |
|---|---|---|
| Familiar NGINX routing | F5 NGINX Ingress Controller | `Ingress` |
| NGINX with the Kubernetes direction of travel | NGINX Gateway Fabric | `Gateway` + `HTTPRoute` |
| Traefik compatibility | Traefik Kubernetes Ingress | `Ingress` |
| Traefik with portable routes | Traefik Gateway provider | `Gateway` + `HTTPRoute` |
| Kubernetes Gateway API with an Envoy data plane | Envoy Gateway | `Gateway` + `HTTPRoute` |

Do not select the community `kubernetes/ingress-nginx` controller for a new
deployment. The project received best-effort maintenance only through March 2026
and no longer receives releases or security fixes. Existing installations should
move to an active controller. “NGINX” below means the actively maintained F5
NGINX Ingress Controller or NGINX Gateway Fabric.

The deployable examples are under `deploy/gitops/components/edge/`. They all route
`knowme.example.com` to `knowme-web` and reference `knowme-web-tls`.

## F5 NGINX Ingress Controller

Provision the controller through the platform GitOps repository using the official
F5 chart. Render and inspect the pinned chart before committing the ArgoCD source:

```bash
helm template nginx-ingress oci://ghcr.io/nginx/charts/nginx-ingress \
  --version VERSION --namespace nginx-ingress > nginx-ingress.rendered.yaml
```

Add `deploy/gitops/components/edge/nginx-ingress` to the chosen environment
Kustomization. Its `Ingress` uses `ingressClassName: nginx`; change that value if
the platform installs a differently named `IngressClass`. F5 also supports
`VirtualServer`, but this catalog uses portable `Ingress` unless an NGINX-only
capability is required.

## NGINX Gateway Fabric

Install the Gateway API CRDs and NGINX Gateway Fabric through the platform GitOps
repository. Add `deploy/gitops/components/edge/nginx-gateway` to the application
overlay. The example expects a `GatewayClass` named `nginx` and binds an HTTPS
listener to `knowme-web-tls`.

Use this mode for new NGINX deployments that benefit from explicit listener and
route ownership. The platform may own a shared `Gateway` and grant application
namespaces access with `allowedRoutes`.

## Traefik Ingress

Enable Traefik's Kubernetes Ingress provider and expose the `websecure` entrypoint
in its platform-owned configuration. Add
`deploy/gitops/components/edge/traefik-ingress`. The example uses
`ingressClassName: traefik` and a cert-manager annotation. This is the least
disruptive path for an existing Traefik deployment based on Ingress resources.

## Traefik Gateway API

Enable the Kubernetes Gateway provider and Gateway API support in the pinned
Traefik release. Add `deploy/gitops/components/edge/traefik-gateway`. The example
expects a `GatewayClass` named `traefik`. Prefer this mode for new Traefik
deployments. Keep Traefik-specific middleware in a separate optional component so
the base `HTTPRoute` remains portable.

## Envoy Gateway

Install the Gateway API CRDs and Envoy Gateway controller through the platform
GitOps repository, then add `deploy/gitops/components/edge/envoy-gateway`. The
example expects the default Envoy `GatewayClass` named `eg`. This is the pure
Envoy option: Envoy Gateway manages the Envoy proxy data plane directly; no NGINX
or Traefik controller participates.

For multi-tenant clusters, let the platform own the `Gateway` and application
teams own `HTTPRoute`. Restrict attachment by namespace selector.

## Certificates with cert-manager

cert-manager is the default Kubernetes-native certificate reconciler. Use the
Let’s Encrypt staging endpoint while validating DNS, routes, and renewal; promote
to production only after staging issuance succeeds.

### Individual hostname with HTTP-01

`deploy/gitops/components/certificates/http01` contains a `ClusterIssuer` and
`Certificate` for `knowme.example.com`. HTTP-01 requires public port 80 routing.
Set the solver's `ingressClassName` to the selected Ingress controller.

For a Gateway implementation, enable cert-manager's Gateway API support and
annotate the `Gateway` or retain an explicit `Certificate`. The resulting TLS
Secret is referenced by the HTTPS listener's `certificateRefs`.

### Wildcard certificate with DNS-01

Wildcard certificates cannot be issued with HTTP-01. Use DNS-01 for the apex and
wildcard names:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: {name: knowme-wildcard, namespace: knowme}
spec:
  secretName: knowme-wildcard-tls
  issuerRef: {name: letsencrypt-wildcard-production, kind: ClusterIssuer}
  dnsNames: [example.com, "*.example.com"]
```

`deploy/gitops/components/certificates/dns01` demonstrates Cloud DNS. Replace only
the solver for the target cloud:

```yaml
# GKE: Google Cloud DNS with Workload Identity Federation
dns01:
  cloudDNS: {project: PROJECT_ID}
```

```yaml
# AKS: Azure DNS with Azure Workload Identity
dns01:
  azureDNS:
    subscriptionID: SUBSCRIPTION_ID
    resourceGroupName: DNS_RESOURCE_GROUP
    hostedZoneName: example.com
    environment: AzurePublicCloud
    managedIdentity: {clientID: CERT_MANAGER_CLIENT_ID}
```

```yaml
# EKS: Route 53 with EKS Pod Identity or IRSA
dns01:
  route53: {region: us-east-1, hostedZoneID: HOSTED_ZONE_ID}
```

Do not place cloud access keys in an Issuer or Kubernetes Secret. Bind the
cert-manager service account to a narrowly scoped cloud identity that may update
only the required DNS zone.

To reuse the wildcard on a Gateway, change its listener to:

```yaml
hostname: "*.example.com"
tls:
  mode: Terminate
  certificateRefs: [{kind: Secret, name: knowme-wildcard-tls}]
```

## Wildcard certificates with external Certbot

Certbot is supported as an external issuance workflow, not as an unmanaged sidecar
in the application Pod. Use the DNS plugin for the authoritative provider:

```bash
certbot certonly --non-interactive --agree-tos \
  --email platform@example.com \
  --dns-PROVIDER \
  -d example.com -d '*.example.com'
```

Run this from a secured certificate automation environment. Store the certificate
and key in Google Secret Manager, Azure Key Vault, or AWS Secrets Manager, then let
the cloud External Secrets/Secrets Store CSI integration produce
`knowme-wildcard-tls`. Never commit `fullchain.pem`, `privkey.pem`, DNS credentials,
or a base64-encoded TLS Secret. Renewal automation must renew early, update the
external secret atomically, and prove that the controller reloads it.

## Overlay composition

An environment overlay adds one edge component and one certificate strategy:

```yaml
resources:
  - ../../cloud/gke
  - ../../../../components/edge/envoy-gateway
  - ../../../../components/certificates/dns01
```

Replace hostnames, email, project identifiers, classes, and release digests in the
external GitOps repository. Application CI validates and promotes digests but
never directly installs a controller or applies resources.

## Required evidence

1. The controller reports accepted/attached status for the Ingress or Route.
2. HTTP redirects to HTTPS and HTTPS reaches `/api/v1/ready`.
3. The served certificate matches the hostname, chain, and expected issuer.
4. A wildcard certificate serves two distinct subdomains without exposing the key.
5. Renewal succeeds against Let’s Encrypt staging, then production.
6. The other edge components remain absent from that environment.

## Official references

- [Ingress NGINX retirement notice](https://kubernetes.github.io/ingress-nginx/)
- [F5 NGINX Ingress Controller](https://docs.nginx.com/nginx-ingress-controller/configuration/ingress-resources/basic-configuration/)
- [NGINX Gateway Fabric](https://docs.nginx.com/nginx-gateway-fabric/)
- [Traefik Gateway provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-gateway/)
- [Envoy Gateway with cert-manager](https://gateway.envoyproxy.io/docs/tasks/security/tls-cert-manager/)
- [cert-manager DNS-01](https://cert-manager.io/docs/configuration/acme/dns01/)
- [Certbot user guide](https://eff-certbot.readthedocs.io/en/stable/using.html)
