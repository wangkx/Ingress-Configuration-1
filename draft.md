# Use NGINX to implement canary Release 
Canary testing would be used to test new production features and functionalities with minimal impact to users.  Canary release refers to the software being used for testing.  Canary testing refers to using the canary releases to test out new features or software versions with real users in a production environment.
Using canary testing has the advantage, that a potential bug would only affect a small number of users, which reduces risk for an organization. 

The following examples show the usage of canary based on header, cookies, and service weight.

## Prerequisites
* Have the NGINX controller deployed
* Have HPCC Helm chart deployed

To install the Nginx controller, follow this tutorial.  It requires for Helm to be installed: [link](https://github.com/amy88ma/Ingress-Configuration/blob/acb11aefe8ab6585248d6707974acc190056d102/Deployment/Nginx_Install%20(1).ipynb)

To deploy the HPCC Helm chart, follow this tutorial: [link](https://github.com/amy88ma/Ingress-Configuration/blob/acb11aefe8ab6585248d6707974acc190056d102/Deployment/Deploy_HPCC.ipynb)

## Annotation descriptions
The following annotations to configure canary can be enabled after ```nginx.ingress.kubernetes.io/canary: "true"``` is set:

```nginx.ingress.kubernetes.io/canary-by-header:``` The header to use for notifying the Ingress to route the request to the service specified in the Canary Ingress. When the request header is set to always, it will be routed to the canary. When the header is set to never, it will never be routed to the canary. For any other value, the header will be ignored and the request compared against the other canary rules by precedence.

```nginx.ingress.kubernetes.io/canary-by-header-value:``` The header value to match for notifying the Ingress to route the request to the service specified in the Canary Ingress. When the request header is set to this value, it will be routed to the canary. For any other header value, the header will be ignored and the request compared against the other canary rules by precedence. This annotation has to be used together with . The annotation is an extension of the nginx.ingress.kubernetes.io/canary-by-header to allow customizing the header value instead of using hardcoded values. It doesn't have any effect if the nginx.ingress.kubernetes.io/canary-by-header annotation is not defined.

```nginx.ingress.kubernetes.io/canary-by-header-pattern:``` This works the same way as canary-by-header-value except it does PCRE Regex matching. Note that when canary-by-header-value is set this annotation will be ignored. When the given Regex causes error during request processing, the request will be considered as not matching.

```nginx.ingress.kubernetes.io/canary-by-cookie:``` The cookie to use for notifying the Ingress to route the request to the service specified in the Canary Ingress. When the cookie value is set to always, it will be routed to the canary. When the cookie is set to never, it will never be routed to the canary. For any other value, the cookie will be ignored and the request compared against the other canary rules by precedence.

```nginx.ingress.kubernetes.io/canary-weight:``` The integer based (0 - 100) percent of random requests that should be routed to the service specified in the canary Ingress. A weight of 0 implies that no requests will be sent to the service in the Canary ingress by this canary rule. A weight of 100 means implies all requests will be sent to the alternative service specified in the Ingress.

Canary rules are evaluated in order of precedence. Precedence is as follows: canary-by-header => canary-by-cookie => canary-weight

Note: 
When you mark an ingress as canary, then all the other non-canary annotations will be ignored (inherited from the corresponding main ingress) except ```nginx.ingress.kubernetes.io/load-balance``` and ```nginx.ingress.kubernetes.io/upstream-hash-by```

#### Known Limitations

Currently a maximum of one canary ingress can be applied per Ingress rule.

## Deploy a service
1. Create an Ingress, open the service to external access, and point to the v1 service. The YAML sample, with the name hpcc-ingress, is as follows:
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hpcc-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /eclwatch(/|$)(.*)
      - backend:
          serviceName: eclqueries
          servicePort: 8002
        path: /eclqueries(/|$)(.*)
      - backend:
          serviceName: esdl-sandbox
          servicePort: 8899
        path: /esdl(/|$)(.*)
      - backend:
          serviceName: sql2ecl
          servicePort: 8510
        path: /wssql(/|$)(.*)
      - backend:
          serviceName: eclservices
          servicePort: 8010
        path: /(.*)  
```
2. Use the command line to create the resources provided in the YAML file:
```
kubectl apply -f hpcc-ingress.yaml
```

## 1) Traffic Spitting based on header
Using the above ingress file, specify the server, eclwatch, and add the annotations to enable requests with the Region field in the header and the corresponding value of eastus to be forwarded to the current Canary Ingress.  
For example, if you select users in the east United States for the beta test of the new version, the YAML sample, named ingress-header, is as follows:
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hpcc-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "Region"
    nginx.ingress.kubernetes.io/canary-by-header-pattern: "eastus"
spec:
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /eclwatch(/|$)(.*)
      - backend:
          serviceName: eclqueries
          servicePort: 8002
        path: /eclqueries(/|$)(.*)
      - backend:
          serviceName: esdl-sandbox
          servicePort: 8899
        path: /esdl(/|$)(.*)
      - backend:
          serviceName: sql2ecl
          servicePort: 8510
        path: /wssql(/|$)(.*)
      - backend:
          serviceName: eclservices
          servicePort: 8010
        path: /(.*)  
```
Create the resources for this file with:
```
kubectl apply -f ingress-header.yaml
```

To perform an access test, you will need the External IP address of the ingress-nginx controller.  To get the IP address, use the following command.  The example output is as shown:
```
kubectl get svc
```
```
NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.0.18.48     52.138.122.26   80:32372/TCP,443:32006/TCP   93s
```

Run the following commands to perform an access test, specifying the region, with http://External-IP:

The region specified in this example is the specified value of the header field, so the service only responds to this region.

```curl -H "Region: eastus" http://52.138.122.26```

The region specified in this example is Chengdu, a city in China, so the service does not respond to this region.

```curl -H "Region: cd" http://52.138.122.26```

When the region is not specified at all, the service does not repsond either.

```curl -I http://52.138.122.26```
## 2) Traffic splitting based on cookies
Note:
If you have created the sample ingress file from the above steps, delete the file: ```kubectl delete -f ingress-header.yaml```.

To use cookies, you cannot set a custom value.  When the cookie value is set to ```always```, it will be routed to the canary. When the cookie is set to ```never```, it will never be routed to the canary. For any other value, the cookie will be ignored and the request compared against the other canary rules by precedence.

For example, if you want to select users in east United States region for the beta test, then only requests with the cookie of user_from_eastus will be forwarded to the current Canary ingress. The YAML sample, named ingress-cookie, is as follows:
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hpcc-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-cookie: "user_from_eastus"
spec:
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /eclwatch(/|$)(.*)
      - backend:
          serviceName: eclqueries
          servicePort: 8002
        path: /eclqueries(/|$)(.*)
      - backend:
          serviceName: esdl-sandbox
          servicePort: 8899
        path: /esdl(/|$)(.*)
      - backend:
          serviceName: sql2ecl
          servicePort: 8510
        path: /wssql(/|$)(.*)
      - backend:
          serviceName: eclservices
          servicePort: 8010
        path: /(.*)  
  ```
  Run the following commands to perform an access test.  The External-IP was obtained previously, using the command: ```kubectl get svc```.
```
curl -s --cookie "user_from_eastus=always" http://52.138.122.26
```
```
curl -s --cookie "user_from_cd=always" http://52.138.122.26
```
```
curl -s http://52.138.122.26
```
You can view that the service responds only to requests in which the value of the cookie user_from_eastus is always.

## 3) Traffic splitting based on service weight
To use a Canary Ingress based on service weight, you only need to specify the proportion of traffic to be imported. For example, to import 10% of traffic to the service, the annotations would be added as follows.

Create a YAML file, named ingress-weight, and add the following:
```YAML
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: hpcc-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"
spec:
  rules:
   - http:
      paths:
      - backend:
          serviceName: eclwatch
          servicePort: 8010
        path: /eclwatch(/|$)(.*)
      - backend:
          serviceName: eclqueries
          servicePort: 8002
        path: /eclqueries(/|$)(.*)
      - backend:
          serviceName: esdl-sandbox
          servicePort: 8899
        path: /esdl(/|$)(.*)
      - backend:
          serviceName: sql2ecl
          servicePort: 8510
        path: /wssql(/|$)(.*)
      - backend:
          serviceName: eclservices
          servicePort: 8010
        path: /(.*)  
```
Run the following command to perform an access test.
```
for i in {1..10}; do curl -H http://52.138.122.26; done;
```
You can see that the chance of the service responding is 10%, which corresponds to the 10% service weight setting.
