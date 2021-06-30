# HTTP Application routing
Access applications deployed in your AKS cluster.   When the solution's enabled, it configures an Ingress controller in your AKS cluster.
As applications are deployed, the solution creates publicly accessible DNS names for application endpoints.
When the add-on is enabled, it creates a [DNS](https://azure.microsoft.com/en-us/pricing/details/dns/) Zone in your subscription.
## Use Azure [CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) to deploy HTTP routing
This add-on can be enabled when deploying a cluster. 
```
az aks create --resource-group myResourceGroup --name myAKSCluster --enable-addons http_application_routing

```
**Enable add-on in an existing cluster**
```
az aks enable-addons --resource-group myResourceGroup --name myAKSCluster --addons http_application_routing

```

After the cluster is deployed/updated, retreive (Kevin? typo) the DNS zone name.
```
az aks show --resource-group myResourceGroup --name myAKSCluster --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName -o table

```
Example output:

```
9f9c1fe7-21a1-416d-99cd-3543bb92e4c3.eastus.aksapp.io
```

## Use Azure Portal to deploy HTTP routing
The HTTP application routing add-on can be enabled through the Azure portal when deploying an AKS cluster.
* When creating a kubernetes cluster, click the networking tab, and choose "Yes" for HTTP Application routing.
* After the cluster is deployed, browse to the auto-created AKS resource group and select the DNS zone.  This name is needed to deploy applications to the AKS cluster.

## Connect to the AKS cluster
Install kubectl locally, if not on Azure Cloud Shell (Kevin? Install aks cli? Why need: az aks install-cli?)
```
az aks install-cli

```
Connect to Kubernetes cluster:
```
az aks get-credentials --resource-group MyResourceGroup --name MyAKSCluster (Kevin? Why under the 'Connect to Kubernetes cluster'?)
```
## Use HTTP Application routing
The HTTP application routing solution may only be triggered on Ingress resources that are annotated as follows:

```YAML
annotations:
  kubernetes.io/ingress.class: addon-http-application-routing
```
Create a file named http-application-routing.yaml, update DNS zone name.

```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: addon-http-application-routing
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: eclwatch-ingress.<DNS_ZONE>
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
```
kubectl apply -f http-application-routing.yaml
```

## Remove HTTP application routing
The HTTP routing solution can be removed using the Azure CLI. (Kevin? remove - not before)To do so run the following command, substituting your AKS cluster and resource group name.

```
az aks disable-addons --addons http_application_routing --name myAKSCluster --resource-group myResourceGroup --no-wait

```
To delete resources, use the kubectl delete command. Specify the resource type (Kevin?where), resource name (Kevin?where), and namespace. 

```
kubectl delete configmaps addon-http-application-routing-nginx-configuration --namespace kube-system
```
