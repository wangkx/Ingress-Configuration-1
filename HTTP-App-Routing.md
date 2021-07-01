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

After the cluster is deployed/updated, retrieve the DNS zone name.
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
Install kubectl locally, if not on Azure Cloud Shell
download the kubectl checksum file on linux:
```
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```
*Configure kubectl to connect to Kubernetes cluster:*
To configure kubectl to connect to your Kubernetes cluster, use the az aks get-credentials command. The following example gets credentials for the AKS cluster named MyAKSCluster in the MyResourceGroup
```
az aks get-credentials --resource-group MyResourceGroup --name MyAKSCluster
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
The HTTP routing solution can be removed using the Azure CLI. To do so run the following command, substituting your AKS cluster and resource group name.

```
az aks disable-addons --addons http_application_routing --name myAKSCluster --resource-group myResourceGroup --no-wait

```
Look for addon-http-application-routing resources using the following kubectl get commands:
```
kubectl get deployments 
kubectl get services 
kubectl get configmaps 
kubectl get secrets 
```
To delete resources, use the kubectl delete command. 

__Example output of kubectl get configmaps__ with namespace "kube-system"
```
$ kubectl get configmaps --namespace kube-system

NAMESPACE     NAME                                                       DATA   AGE
kube-system   addon-http-application-routing-nginx-configuration         0      9m7s
kube-system   addon-http-application-routing-tcp-services                0      9m7s
kube-system   addon-http-application-routing-udp-services                0      9m7s
```
Use the following command to delete one of the above configmaps:
```
kubectl delete configmaps addon-http-application-routing-nginx-configuration --namespace kube-system
```
