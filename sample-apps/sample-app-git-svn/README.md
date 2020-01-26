# sample-app-svn-git

`sample-app-svn-git` is a sample project that is used to test the SVN-GIT synchronization bridge of the [azure-aks-aci-devops](https://github.com/damianmcdonald/azure-aks-aci-devops) Proof of Concept project.

# Description

`sample-app-svn-git` is packaged as a `war` file and it can be run as a _fat-jar_ or it can be deployed in a Tomcat server.

If you wish to test the application, execute the commands below:

```bash
mvn clean package spring-boot:repackage
java -jar target/sample-app-svn-git-X.X.X-SNAPSHOT.war
```
The application is published on http://localhost:9090/sample-app-svn-git

# Add the project to the Proof of Concept Subversion

1. In the [Azure Portal](https://portal.azure.com/), navigate to the PoC Container Instance and connect to the `subversion` container
1. Create the project in Subversion by issuing the commands below:

```bash
# install a text editor
apt update && apt install nano

# create the project
cd /home/svn
svnadmin create sample-app-svn-git

# edit the svnserve.conf file
# uncomment the line password-db = passwd and save the file
nano /home/svn/sample-app-svn-git/conf/svnserve.conf

# edit the passwd file as shown below and save the file
# in the  [users] section add new users as
# svnuser1=unisys2020
# svnuser2=unisys2020
nano /home/svn/sample-app-svn-git/conf/svnserve.conf

# set permissions on the svn dir
chmod -R 777 /home/svn
```

# Checkout the subversion project and add the sample project code

```bash
# define the path to the Proof of Concept sample project
export POC_SVN_GIT_SAMPLE_PROJECT=/path/to/poc/sample-projects/sample-app-svn-git
# LOCAL_SVN_PROJECT_FOLDER shou8ld be a folder outside of the Proof of Concept project folder
export LOCAL_SVN_PROJECT_FOLDER=/path/to/local/svn

# cheeckout the project
svn checkout --username svnuser1 --password unisys2020 http://${AZURE_SUBVERSION_IP}:7243/svn/sample-app-svn-git/ $LOCAL_SVN_PROJECT_FOLDER

# create the svn director4y structure
mkdir -p $LOCAL_SVN_PROJECT_FOLDER/{trunk,tags,branches}

# copy the sample project to the trunk of the svn project
cp -rv $POC_SVN_GIT_SAMPLE_PROJECT/* $LOCAL_SVN_PROJECT_FOLDER/trunk/

# add the code to subversion
svn add $LOCAL_SVN_PROJECT_FOLDER/*

# commit the code to subversion
svn commit -m "Initial commit" --username svnuser1 --password unisys2020
```

# Create the SVN - GIT synchronization bridge

```bash
# checkout the svn project into a tracked local git repository
git svn --authors-file=/path/to/local/local-svn/trunk/authors.txt clone -s http://${AZURE_SUBVERSION_IP}:7243/svn/sample-app-svn-git/ sample-app-svn-git

# navigate to the new git checkout
cd sample-app-svn-git

# add the gitlab remote repository
git remote add origin https://${AZURE_GITLAB_IP}/root/sample-app-svn-git.git

# pull the svn changes into git
git svn rebase

# push the changes to Gitlab
git -c http.sslVerify=false push origin master
```

# SVN to Git synchronization commands

To sync changes from SVN to Git, enter the following commands:

```bash
# in the SVN project, add/commit changes
svn commit -m "COMMIT_MESSAGE"

# in the Git project, rebase to the svn project and push the changes to Gitlab

# pull the svn changes into git
git svn rebase

# push the changes to Gitlab
git -c http.sslVerify=false push origin master
```

# Making changes to the application

The application includes a `src/main/resources/application.properties` file which contains settings that can be easily modified in order to invoke the SVN-GIT bridge and see some visible changes in the UI of the application.

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

# Test the SVN-GIT bridge

1. Navigate to `$SVN_LOCAL_PROJECT/trunk/src/main/resources/application.properties`
1. Modify the `application.properties` file by changing the `greeting.message` text and the `greeting.flag.image`
1. Navigate to `$GIT_LOCAL_PROJECT"`
1. Execute: `git svn rebase`
1. Execute: `git -c http.sslVerify=false push origin master`
1. Check the Jenkins pipleine; http://${AZURE_SUBVERSION_IP}:7575/job/sample-app-svn-git-pipeline/
1. Check the project quality status in Sonarqube; http://${AZURE_SONARQUBE_IP}:9000
1. Check that the release has been pushed to Nexus; http://${AZURE_NEXUS_IP}:8081/#browse/browse:maven-snapshots
1. Verify that the changes defined in `application.properties` have been deployed; `http://${AZURE_TOMCAT_IP}:7895/sample-app-svn-git/`
