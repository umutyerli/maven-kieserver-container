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

Login to the RedHat Repository. Will need customer credentials to access registry.redhat.io RHEL Image. Docker will need to be running.
```
docker login registry.redhat.io
Username: xxxx
Password: xxxx
Login Succeeded
```

A Docker Image Repository will be needed for the next step. For this example, an image repository will be created on DockerHub.

In order to create a repository, sign into Docker Hub on hub.docker.com , click on `Repositories` then `Create Repository`:

Put the repository in your Docker ID namespace (your username). In this example, the repository is called `kie-server` for the demo purpose.

Inside the `maven-kieserver-container` project, build the docker image with the image name `kie-server`. 
```
docker build -t kie-server .
```

Login to Docker on CLI in order to access the repository on DockerHub.
```
docker login docker.io

Username: xxxx
Password: xxxx
Login Succeeded
```

Push Docker image to docker repo.

The local `kie-server` docker image has already been built so it will need to be pushed to the `kie-server` repository created on DockerHub. 

```
docker tag <existing-image> <docker-repo-url>/<namespace>/<repo-name>[:<tag>]
docker push <docker-repo-url>/<namespace>/<repo-name>:<tag>
```

For this example, the command will look like this if `dockeruser` represents the namespace of the repository and `kie-server` represents the repository name:
```
docker tag kie-server:latest docker.io/dockeruser/kie-server:latest
docker push docker.io/dockeruser/kie-server:latest
```

### Part 2: Deploy Kie Server Image to OpenShift

Access your OpenShift Server via CLI. 
```
oc login -u <username> -p <password> http://console.openshift.example.com:6443
```

Create a new project. In this example, the namespace/project is called `project1`.
```
oc new-project project1
```

Deploy the Docker image to Openshift
```
oc new-app docker.io/dockeruser/kie-server:latest

--> Found container image 2a807bf (20 minutes old) from docker.io for "docker.io/dockeruser/kie-server:latest"

    Java Applications
    -----------------
    Platform for building and running plain Java applications (fat-jar and flat classpath)

    Tags: builder, java

    * An image stream tag will be created as "kie-server:latest" that will track this image

--> Creating resources ...
    imagestream.image.openshift.io "kie-server" created
    deployment.apps "kie-server" created
    service "kie-server" created
--> Success
    Application is not exposed. You can expose services to the outside world by executing one or more of the commands below:
     'oc expose svc/kie-server'
    Run 'oc status' to view your app.
```

The image has been deployed at this point. The next information that is needed will be the deployment/deployment config name. 2 Important lines to take note are:

`deployment.apps "kie-server" created`

`service "kie-server" created`


Create the route for the kie-server application. The name of the service created on this line `service "kie-server" created` will be needed. In this case, it is called `kie-server`
```
oc expose service kie-server
```


Give `kie-server` deployment pods privileged access. 
```
oc create sa kie-sa -n project1
oc adm policy add-scc-to-user anyuid -z kie-sa -n project1
```

Set the serviceaccount `kie-sa` to the deployment or deploymentconfig (depending on which one was automatically created) for kie-server. In this example, since `deployment.apps "kie-server" created`, the serviceaccount would be set to the deployment for kie-server. 
```
oc set serviceaccount deployment.apps/kieserver kie-sa
```

Validate kie server application successfully started and the kie container was created.
```
oc get route kie-server

NAME         HOST/PORT                                                         PATH   SERVICES     PORT       TERMINATION   WILDCARD
kie-server   kie-server-project2.console.openshift.example.com          kie-server   8080-tcp                 None

curl kie-server-project1.console.openshift.example.com/rest/server/containers
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