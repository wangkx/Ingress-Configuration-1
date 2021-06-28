# Create an HTTPS ingress controller and use your own TLS certificates on AKS
First deploy the NGINX ingress controller in an Azure Kubernetes Service (AKS) cluster.
Then, generate certificates, and create a Kubernetes secret for use with the ingress route. 
Two applications are run in the AKS cluster, both accessible over one IP address.
* Run Azure [CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) version 2.0.64 or later
* Use the latest release of [Helm](https://helm.sh/docs/intro/install/).

## Create an Ingress Controller

```
# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux
```
Azure public IP address is created for the ingress controller.
```
kubectl get services -o wide -w nginx-ingress-ingress-nginx-controller

```
## Generate TLS certificates
Generate a self-signed certificate with openssl.
*For production use, specify your own organizational values for the -subj parameter,
also request a trusted, signed certificate through a provider or your own certificate authority (CA)*
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out aks-ingress-tls.crt \
    -keyout aks-ingress-tls.key \
    #-subj "/CN=demo.azure.com/O=aks-ingress-tls"
```
## Create Kubernetes secret for TLS certificate
To allow Kubernetes to use the TLS certificate and private key for the ingress controller, create and use a Secret.
```
kubectl create secret tls <name> \
    --key <name>.key \
    --cert <name>.crt
 ```
## Run Demo Application
