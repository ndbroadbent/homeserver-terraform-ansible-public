# Traefik Routes

This directory contains IngressRoute configurations for external services
proxied through Traefik.

## Adding a New Route

To add a new external service:

1. Create a new YAML file in this directory (e.g., `myservice.yaml`)
2. Include both the IngressRoute and ExternalName service
3. Use the `traefik` namespace for all resources
4. Reference the wildcard certificate: `home-youruser-com-tls`

## Template

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: myservice
  namespace: traefik
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`myservice.home.example.com`)
      kind: Rule
      services:
        - name: myservice-external
          port: 80
  tls:
    secretName: home-youruser-com-tls
---
apiVersion: v1
kind: Service
metadata:
  name: myservice-external
  namespace: traefik
spec:
  type: ExternalName
  externalName: 10.11.12.xxx # Replace with actual IP
  ports:
    - port: 80 # Replace with actual port
      targetPort: 80
      protocol: TCP
```
