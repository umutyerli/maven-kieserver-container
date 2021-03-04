# maven-kieserver-container

Maven Kieserver Container is a Maven project that builds a custom kieserver that can pull Binary Artifacts from Artifact Repositories and deploy the artifact into the Kie Container. This Project can be containerized and deployed onto OpenShift.

### Prerequisites 

Main Prerequisites
- Maven 3.xx
- Java 1.8
- Docker
- Artifact Repository w/ Artifact Deployed
- Access to Images on registry.redhat.io

Deploying on Openshift
- OpenShift Cluster 4.x
- Docker Repository


### Projects Being Used

#### Mortage Application: Example DM Project

The example DM project being used by the Kie Server is an Example Mortgage Application, the project can be found here https://github.com/jbossdemocentral/rhdm7-loan-demo.

### TODO

- [ ] Custom Ansible Script for Part 1
- [ ] Custom Ansible Script for Part 2

## Steps to Install

### Part 1: Create and Build Image from DockerFile

```
git clone https://github.com/umutyerli/maven-kieserver-container.git
cd maven-kieserver-container
```

Install the Maven Project
```
mvn clean install
```

Build the docker image. Will need customer credentials to access registry.redhat.io RHEL Image
```
docker login registry.redhat.io
Username: xxxx
Password: xxxx
Login Succeeded

docker build -t kieserver .
```

Push Docker image to docker repo 
```
docker tag kieserver:latest dockerrepo.io:5000/namespace/kieserver:latest
docker push dockerrepo.io:5000/namespace/kieserver:latest
```

### Part 2: Deploy Kie Server Image to OpenShift

Access OpenShift Server via CLI
```
oc login -u <username> -p <password> http://console.openshift.example.com:6443
```

Create a new project
```
oc new-project project1
```

Deploy Docker image to Openshift
```
oc new-app dockerrepo.io:5000/namespace/kieserver:latest
oc expose svc kieserver
```

Give kieserver pod privileged access
```
oc create sa kie-sa
oc adm policy add-scc-to-user anyuid -z kie-sa
oc set serviceaccount dc/kieserver

## Redeploy Container
oc deploy dc/kieserver
```

Validate kie server application successfully started and the kie container was created 
```
oc get route kieserver

NAME         HOST/PORT                                                         PATH   SERVICES     PORT       TERMINATION   WILDCARD
kieserver   kieserver-project2.console.openshift.example.com          kieserver   8080-tcp                 None

curl kieserver-project2.console.openshift.example.com:8080/rest/server/containers
```
If CURL response is as follows, deployment has been validated
``` 
<response type="SUCCESS" msg="List of created containers">
  <kie-containers>
    <kie-container container-alias="mortgages-kjar" container-id="mortgages-1.0.0-SNAPSHOT" status="STARTED">
      <config-items>
        <itemName>KBase</itemName>
        <itemValue/>
        <itemType>BPM</itemType>
      </config-items>
      <config-items>
        <itemName>KSession</itemName>
        <itemValue/>
        <itemType>BPM</itemType>
      </config-items>
      <config-items>
        <itemName>MergeMode</itemName>
        <itemValue>MERGE_COLLECTIONS</itemValue>
        <itemType>BPM</itemType>
      </config-items>
      <config-items>
        <itemName>RuntimeStrategy</itemName>
        <itemValue>PER_CASE</itemValue>
        <itemType>BPM</itemType>
      </config-items>
      <messages>
        <content>Container mortgages-1.0.0-SNAPSHOT successfully created with module mortgages:mortgages:1.0.0-SNAPSHOT.</content>
        <severity>INFO</severity>
        <timestamp>2021-03-02T22:08:51.330Z</timestamp>
      </messages>
      <release-id>
        <artifact-id>mortgages</artifact-id>
        <group-id>mortgages</group-id>
        <version>1.0.0-SNAPSHOT</version>
      </release-id>
      <resolved-release-id>
        <artifact-id>mortgages</artifact-id>
        <group-id>mortgages</group-id>
        <version>1.0.0-SNAPSHOT</version>
      </resolved-release-id>
      <scanner status="DISPOSED"/>
    </kie-container>
  </kie-containers>
</response>
```