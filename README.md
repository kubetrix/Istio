**Production Grade Istio Setup using Istioctl Utility**

**Steps for istio setup installation**

**Pre-Validation**

	- Verify PVC size for jaeger storage 1.1_jaeger_cassandra-sts.yaml
	- Take backup of all VS, GW, DR in cluster
	- In case of reinstallation of Istio -> Please follow below mentioned Uninstall Istio process process. 
	- In case of reinstallation of Jaeger -> Delete Jaeger deployment, Job, Statefulset, Do not delete the namespace, As we have PVC present.
	- Go through the istio config file and modify the required things like LoadBalancer ResourceGroup,includeIPRanges(Include subnet Range and service IP range) , LoadBalancer IP, Make sure PILOT_TRACE_SAMPLING=1


***Installation***

**Auto**

 	- Download Folder from repo and go inside istio folder
 	- Run ./install.sh script

**Manual**
 
  Install new setup using below steps

   	- Create Jaeger Namespace -> "kubectl create ns jaeger"
    - Run -> "kubectl apply -f 1_jaeger_cassandra.yaml -n jaeger" and wait for completion	
	- Run -> "kubectl apply -f 1.1_jaeger_cassandra-sts.yaml -n jaeger" and wait for completion	
	- Run schema creation script -> "kubectl apply -f 2_jaeger-cassandra-schema.yaml"
	
Note:- Monitor Cassandra POD and check the JOB status, if JOB not completed then delete and recreate the same JOB, JOB will create the schema.

	- Run jaeger traces collector deployment script -> "kubectl apply -f 3_jaeger-collector.yaml -n jaeger"
	- Run jaeger query deployment script -> "kubectl apply -f 4_jaeger_query.yaml -n jaeger"
	- Download istioctl utility(Present in repo folder)- Make sure to use the same version which you are planning to deploy in this case it is 1.5.4
	- Install istio -> "./istioctl manifest apply -f 5_current-profile.yaml"
	- Once istio all pods is up run below commands
		- "kubectl apply -f 6_default-gateway.yaml  -n istio-system" # This is required for default gateway setup for all services, if missed by any application
		- "kubectl apply -f 7_default-dr.yaml -n istio-system" # This is required for Mesh Policy to apply on all workload
		- "kubectl apply -f 8_meshpolicy.yaml  -n istio-system" # This is for Mesh Policy setup to accept Non-MTLS+ MTLS traffic
		- "kubectl apply -f 9_kiali.yaml  -n istio-system" # This is for kiali configmap changes, It will remove grafana error
		- "kubectl -n istio-system delete po -l=app=kiali" Restart Kiali pod from istio-system namespace
		
**After-installation**
	
	- Install URL(DNS) certs 
	    
		- Run below command for installation(Pass additonal certs in the same way for installation with different keys - like cert1, cert2 etc, If need to add new cert to running istio-ingressgateway at runtime please follow below mentioned Addition Cert installation steps)
		   "kubectl -n istio-system create secret generic istio-ingressgateway-certs --from-file=tls.crt=<cert file> --from-file=tls.key=<key file>"			
	- Restart Ingressgateway pods 
		- command -> "kubectl -n istio-system delete po -l=app=istio-ingressgateway"
	- Restart all istio-injection enabled namespace application pods(Make sure before execution of below command there is no pod which is not allowed to delete because of stickiness)
	    - command -> "for i in $(kubectl get ns  -l=istio-injection=enabled | awk 'NR>1 {print $1}'); do kubectl delete po --all -n $i; done"
		
**Additional Cert Installation Steps**

*Note:- Please perform this step in lower environment first and monitor the rotation and errors for old applications because of old cert(istio-control-plane -> istio-data-plane(proxy)), As per istio discussions forum based on kubernetes version it usually varry so take this step carefully*

	- Download the certificates and store locally  
	- Create Temp Secret for cert to yaml template creation
		- Command -> "kubectl -n istio-system create secret generic istio-ingressgateway-ps_certs  --from-file=<new-cert>tls.crt=<cert file> --from-file=<new-cert-key>tls.key=<cert-key>"
	- Take existing "istio-ingressgateway-certs" secret in Yaml format, Update the copied new temp secret key/cert as a additional cert+key.
	- Delete the existing cert and apply the new cert using simple kubectl apply.
	- Restart Ingressgateway pods(Scale up then delete and scale down)
	- Make sure all other application is not impacted, if looks not working then make sure to restart other apps as well for new cert rotation(Handshake cert between istio-proxy to istio control plane)
	- Update the namespace level gateway where we need to use new certs with newly added key.
	- If pod already running for application make sure to restart the pods for new certs.

**Uninstall Istio**

	- Take backup of all VS, GW, DR in cluster
	- Make sure istio-system namespace was deleted and mutatingwebhookconfigurations->istio-sidecar-injector is deleted
		- kubectl delete ns istio-system 
		- kubectl delete mutatingwebhookconfigurations istio-sidecar-injector

*Note:- Please dont use any other deletion command, It will delete all application GW/VS/DR,*

**Validation Note**

- If Ingressgateway container is not up then please run below command and do the cleanup of existing istio. 
- ***Prior to execution please take the backup of existing VS/GW/DR, as below command will clean all istio native components.***
- ***Please verify cluster Prior to running below command-> just make sure you are pointing to correct cluster as it will clean up everything related to istio and your environment will be down.***

		Command -> ./istioctl manifest generate -f 5_current-profile.yaml | kubectl delete -f -

########################################################################################################################################################
########################################################################################################################################################
