#!/bin/bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
kubectl create namespace ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--set controller.replicaCount=2

