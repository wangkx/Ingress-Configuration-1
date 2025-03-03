# Use TLS with Let's Encrypt

Use a dynamic public IP address to create an HTTPS ingress controller on AKS

## Create an Ingress controller

Use Helm to deploy an NGINX ingress controller

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```
An Azure public IP address will be created for the ingress controller.  To get this public IP address, use
```bash
kubectl get service
```

## Configure an FQDN for the ingress controller IP address

```bash
IP="MY_EXTERNAL_IP"
DNSNAME="demo-aks-ingress"
PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME
az network public-ip show --ids $PUBLICIPID --query "[dnsSettings.fqdn]" --output tsv

```

## Install cert-manager
Add the Jetstack Helm repository
```
helm repo add jetstack https://charts.jetstack.io
```
Update local Helm chart repository cache using 'helm repo update'

Install cert-manager using Helm chart
```
helm install cert-manager jetstack/cert-manager \
  --set installCRDs=true \
  --set nodeSelector."kubernetes\.io/os"=linux \
  --set webhook.nodeSelector."kubernetes\.io/os"=linux \
  --set cainjector.nodeSelector."kubernetes\.io/os"=linux
```

## Creating a CA cluster issuer
Create a cluster issuer, for example, cluster-issuer.yaml.  Replace the email address with a valid email address.

```YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: MY_EMAIL_ADDRESS
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - http01:
        ingress:
          class: nginx
```
Use 'kubectl apply' command to create the issuer.
```bash
kubectl apply -f cluster-issuer.yaml
```
## Creating an Ingress route
Create a file using the below example YAML (example-ingress.yaml). Replace the host and hostname with DNS name created previously.

```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    #nginx.ingress.kubernetes.io/ssl-redirect: "false"
    #nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - hpcc.eastus.cloudapp.azure.com
    secretName: aks-ingress-tls

  rules:
  - host: hpcc.eastus.cloudapp.azure.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
         service:
           name: eclwatch
           port:
             number: 8010
```
Create the ingress resource using 'kubectl apply' command.
```bash
kubectl apply -f example-ingress.yaml
```
## Verify the certificate object has been created

```
kubectl get certificate
```
Use this command to verify that *READY* is *True*.

## Test the ingress configuration

Test this configuration by opening a web browser, and go to

```
example-ingress.MY_CUSTOM_DOMAIN
```
of the ingress controller.

## Clean up Resources

Delete resources indiviudally:

```
kubectl delete -f cluster-issuer.yaml

helm uninstall cert-manager nginx

kubectl delete -f example-ingress.yaml
```
