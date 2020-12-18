#!/bin/bash

kubectl create ns jaeger
kubectl -n jaeger apply -f 1_jaeger_cassandra.yaml
kubectl -n jaeger apply -f 1.1_jaeger_cassandra-sts.yaml
echo "Waiting for 10 mins for cassandra db setup"
date +"%H:%M:%S"
sleep 10m 0s
echo "Pass for 10 mins"
date +"%H:%M:%S"
kubectl -n jaeger apply -f 2_jaeger-cassandra-schema.yaml
echo "Waiting for 1 mins for cassandra schema setup"
date +"%H:%M:%S"
sleep 1m 0s
kubectl -n jaeger apply -f 3_jaeger-collector.yaml
kubectl -n jaeger apply -f 4_jaeger_query.yaml
./istioctl manifest apply -f 5_current-profile.yaml
kubectl -n istio-system apply -f 6_default-gateway.yaml
kubectl -n istio-system apply -f 7_default-dr.yaml
kubectl -n istio-system apply -f 8_meshpolicy.yaml
kubectl -n istio-system apply -f 9_kiali.yaml
kubectl -n istio-system delete po -l=app=kiali