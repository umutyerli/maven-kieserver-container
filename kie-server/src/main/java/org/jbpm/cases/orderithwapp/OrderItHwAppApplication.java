package org.jbpm.cases.orderithwapp;

import org.kie.server.api.KieServerConstants;
import org.kie.server.api.model.KieContainerResource;
import org.kie.server.api.model.KieContainerStatus;
import org.kie.server.api.model.ReleaseId;
import org.kie.server.services.impl.storage.KieServerState;
import org.kie.server.services.impl.storage.file.KieServerStateFileRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.HashSet;
import java.util.Set;

@SpringBootApplication
public class OrderItHwAppApplication {
    
    private static final String GROUP_ID = "mortgages";
    private static final String ARTIFACT_ID = "mortgages";
    private static final String VERSION = System.getProperty("KJAR_VERSION", "1.0.0-SNAPSHOT");

	public static void main(String[] args) {
	    String controller = System.getProperty(KieServerConstants.KIE_SERVER_CONTROLLER);
        
        if ( controller != null && !controller.isEmpty()) {
            System.out.println("Controller is configured ("+controller+") - no local kjars can be installed");
            return;
        }
        
        // proceed only when kie server id is given and there is no controller
        
        KieServerStateFileRepository repository = new KieServerStateFileRepository();
        KieServerState currentState = repository.load(ARTIFACT_ID);
        
        Set<KieContainerResource> containers = new HashSet<KieContainerResource>();
        

        ReleaseId releaseId = new ReleaseId(GROUP_ID, ARTIFACT_ID, VERSION);                     
        KieContainerResource container = new KieContainerResource(releaseId.getArtifactId() + "-" + releaseId.getVersion(), releaseId, KieContainerStatus.STARTED);
        containers.add(container);        
        
        currentState.setContainers(containers);
        
        repository.store(ARTIFACT_ID, currentState);
	    SpringApplication.run(OrderItHwAppApplication.class, args);
	}
	


}
