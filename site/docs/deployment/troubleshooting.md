---
sidebar_position: 3
title: Troubleshooting
---

# Diagnose from the public boundary

1. Verify the promoted image digest matches the registry and GitOps lock.
2. Inspect readiness before application logs; readiness names the failing dependency.
3. Confirm Ingress or Route acceptance and Gateway listener status.
4. Inspect `Certificate`, `CertificateRequest`, `Order`, and `Challenge` status.
5. Use the Let’s Encrypt staging issuer until routing and renewal are reliable.
6. Run the conversation smoke test through the public Axum endpoint.

Never resolve a deployment failure by changing requirements, bypassing the shared
Rust service, embedding a secret, or directly mutating production outside GitOps.
