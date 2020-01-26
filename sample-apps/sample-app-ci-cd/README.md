# sample-app-ci-cd

`sample-app-ci-cd` is a sample project that is used to test the CI/CD capabilities of the [azure-aks-aci-devops](https://github.com/damianmcdonald/azure-aks-aci-devops) Proof of Concept project.

# Description

`sample-app-ci-cd` is packaged as a `war` file and it can be run as a _fat-jar_ or it can be deployed in a Tomcat server.

If you wish to test the application, execute the commands below:

```bash
mvn clean package spring-boot:repackage
java -jar target/sample-app-ci-cd-X.X.X-SNAPSHOT.war
```
The application is published on http://localhost:9090/sample-app-ci-cd

# Add the project to the Proof of Concept GitLab

```bash
cd sample-app-ci-cd
git init
git remote add origin https://${AZURE_GITLAB_IP}/root/sample-app-ci-cd.git
git add .
git commit -m "Initial commit"
git -c http.sslVerify=false push origin master
```

# Making changes to the application

The application includes a `src/main/resources/application.properties` file which contains settings that can be easily modified in order to invoke the CI/CD pipeline and see some visible changes in the UI of the application.

```properties
server.port = 9090
server.servlet.contextPath=/sample-app-ci-cd
# Valid values for the greeting.message
greeting.message=Hello world!
# Valid values for the greeting.flag.image
# alemania
# australia
# espana
# francia
# italia
greeting.flag.image=australia
```

## Test the CI-CD integration

1. Make sure that you have the latest upstream changes; `git -c http.sslVerify=false pull origin master`
1. Navigate to `sample-app-ci-cd/src/main/resources/application.properties`
1. Modify the `application.properties` file by changing the `greeting.message` text and the `greeting.flag.image`
1. Add the change; `git add src/main/resources/application.properties`
1. Commit the change; `git commit -m "Add commit message here"`
1. Push the changes to Gitlab to invoke the pipeline; `git -c http.sslVerify=false push origin master`
1. Check the Jenkins pipleine; `http://${AZURE_JENKINS_IP}/job/sample-app-ci-cd-pipeline/`
1. Check the project quality status in Sonarqube; `http://${AZURE_CONTAINER_DNS_NAME}:9000`
1. Check that the release has been pushed to Nexus; `http://${AZURE_NEXUS_IP}:8081/#browse/browse:maven-releases`
1. Verify that the `pom.xml` file has been incremented in Gitlab; `https://${AZURE_GITLAB_IP}/root/sample-app-ci-cd/blob/master/pom.xml`
1. Verify that the changes defined in `application.properties` have been deployed; `http://${AZURE_TOMCAT_IP}/sample-app-ci-cd`
