# Canary Deployments with NGINX
This is used for running two versions of a service parallel to eachother(Kevin? space), to validate the expected behavior of the new version.  The annotations allow a small percentage of
traffic to be directed to a new version and the larger set of users to be directed to the other version.  The canary annotation enables the Ingress spec to act as an alternative service for requests to route to depending on the rules applied. 

## Enable canary annotations
open a yaml file named deployment.yaml and use the following content:
```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  -  http:
      paths:
      - path: /
        pathType: Prefix
        backend:
         service:
           name: eclwatch
           port:
             number: 8010

```
Apply this yaml file using

```
kubectl apply -f deployment.yaml

```

Then, open another file and save it as canary-ingress.yaml, and use the following content to add the annotations to.

```YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: eclwatch-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "30"
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  -  http:
      paths:
      - path: /
        pathType: Prefix
        backend:
         service:
           name: eclqueries
           port:
             number: 8002

```

The annotations to configure canary can be enabled after the following annotation is set.

```
nginx.ingress.kubernetes.io/canary: "true"

```

This annotation can be set, integer based 0-100, percent of random requests will be routed to the service specified in the canary ingress.  0 implies that 0 requests will be sent to 
the service in the canary ingress. 100 implies that all requests will be sent to the alternative service specified in the Ingress.

```
nginx.ingress.kubernetes.io/canary-weight: "integer"

```
In the yaml file it is set to 30, so 30% of requests will be routed to 'eclqueries' IP ( the alternative service) , and the other 70% of requests will be directed to 'eclwatch' service IP.

Apply this file.
```
kubectl apply -f canary-ingress.yaml

```

## Notes
* When you mark an ingress as canary, all other non-canary annotations will be ignored (inherited from the corresponding main ingress) except *nginx.ingress.kubernetes.io/load-balance* and *nginx.ingress.kubernetes.io/upstream-hash-by*.

**Known Limitations**

Currently a maximum of one canary ingress can be applied per Ingress rule.

(Kevin? We need to explain how to test)
