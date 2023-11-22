# Demo to Setup a Pipeline for a Java Maven Project in Jenkins from Scratch

## Prerequisites

### Install Java:

```bash
sudo apt update
sudo apt install fontconfig openjdk-17-jre
java -version
```

### Create a simple Java application with Maven for your Jenkins pipeline:

1. Install Maven:
    
    You can download it from the [Apache Maven Project website](https://maven.apache.org/download.cgi):

    ```bash
    wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
    tar xzvf apache-maven-3.9.5-bin.tar.gz
    sudo mv apache-maven-3.9.5 /usr/local/bin
    #Add the bin directory of apache-maven-3.9.5 to yout PATH environment variable:
    echo "export PATH=\$PATH:/usr/local/bin/apache-maven-3.9.5/bin/" >> .profile
    #Logout and test:
    mvn -v
    ```

2. Create a New java project:
    - Create a Directory:
    ```bash
    mkdir my-jenkins-java-project
    cd my-jenkins-java-project
    ```
    - Use Maven to generate a new project. You can use an archetype, like maven-archetype-quickstart, to create a simple project structure:  

    ```bash
    mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-jenkins-java-project -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false
    ```
    - Navigate to the Project: Go into the newly created project directory:  

    ```bash
    cd my-jenkins-java-project
    ```
    - Write Your Application: Edit the App.java file under src/main/java/com/mycompany/app to create a simple Java application. Here's an example of a basic Java application that calculates Fibonacci numbers in an infinite loop, which should load the CPU:  

    ```java
    package com.mycompany.app;

    public class App {
        public static void main(String[] args) {
            System.out.println("Starting CPU Load Application");

            while (true) {
                fibonacci(30); // Calculate the 30th Fibonacci number repeatedly
            }
        }

        public static long fibonacci(int n) {
            if (n <= 1) return n;
            else return fibonacci(n - 1) + fibonacci(n - 2);
        }
    }
    ```  
    - Review pom.xml: Maven generates a pom.xml file in your project directory. This file is used to define your project's build configuration. Here's the reviewed version of pom.xml to fit the jenkins pipeline demo purpose:  
    ```xml
    <project xmlns="http://maven.apache.org/POM/4.0.0" 
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.mycompany.app</groupId>
    <artifactId>my-jenkins-java-project</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>my-jenkins-java-project</name>
    <url>http://maven.apache.org</url>
    
    <dependencies>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>3.8.1</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <addClasspath>true</addClasspath>
                            <mainClass>com.mycompany.app.App</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
    </project>
    ```
    -  Build the Application Locally running this command from the root of your project directory:  
```bash
mvn clean install
```
Ensuring the build completes successfully without errors you can now run your java application and get your processor warmed up a bit 🔥:
```bash
java -jar ~/my-jenkins-java-project/my-jenkins-java-project/target/my-jenkins-java-project-1.0-SNAPSHOT.jar
```
> ⚠️ It will continue running until you manually stop it, so don't forget to press Ctrl+C in the terminal ;-)

### Push your application to your preferred Git hosting service:

From the root of your project directory:
```bash
#Set Your Email Address
git config --global user.email "you@example.com"
#Set Your Username
git config --global user.name "Your Name"
#Verify Configuration
git config --global --list
#Initialize Git:
git init
#To rename your branch to 'main' (default in Gitlab)
git branch -m main
#Stage Files
git add .
#Commit Changes:
git commit -m "Initial commit of my Jenkins Java project"
#Add Remote Repository
git remote add origin YOUR_GIT_REPOSITORY_URL
#Push to Git
git push -u origin main
```
> If your new project includes a README, for instance, you should rebase your local changes on top of the remote main branch's changes using 'git pull --rebase origin main' before pushing.

## Install Jenkins LTS:

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins
```

> Jenkins by default runs on port 8080. Ensure this port is not in use by another service and is not blocked by a firewall.

### Initial Setup of Jenkins

- Open Jenkins: Access Jenkins in your browser (http://localhost:8080).
- Unlock Jenkins: Use the initial admin password found in the Jenkins home directory (/var/lib/jenkins/secrets/initialAdminPassword on Linux) to unlock.
- Install Plugins: Choose to install suggested plugins or select specific plugins you need.
- Create Admin User: Set up an admin user with a username, password, and email.

## Pipeline

### Add Maven to the jenkins PATH

- Add the PATH in Jenkins service file:
    - Open Jenkins Dashboard: Access Jenkins in your web browser.
    - Manage Jenkins: Click on System
    - Under "Global properties", check "Environment variables"
    - Add a new environment variable with the name PATH and the value including your Maven path:
```
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/bin/apache-maven-3.9.5/bin
```

##### OR

- Add the PATH editing Jenkins service file:

```bash
sudo vim /lib/systemd/system/jenkins.service
```
- Add the PATH in an Environment line under the [Service] section and save

```vim
[Service]
...
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin/apache-maven-3.9.5/bin/"
```
- Reload and restart the service

```bash
sudo systemctl daemon-reload
sudo systemctl restart jenkins.service
```

### Configure your Git service credential

- Open Jenkins Dashboard: Access Jenkins in your web browser.
- Manage Jenkins: Click on Credentials
- Click on the “(global)” domain or the domain you want to add credentials to.
- Click on “Add Credentials” on the right side.
- Kind: Select “Username with password”.
- Scope: Choose "Global" if you want these credentials to be available across all Jenkins projects.
- Username: Enter your GitLab username or the username of a GitLab account with access to the repository.

### Create a New Pipeline Job

- Open Jenkins Dashboard: Access Jenkins in your web browser.
- New Item: Click on "New Item" at the top left of the dashboard.
- Name Your Pipeline: Enter a name, e.g., "BasicPipeline", and select "Pipeline".
- Click OK: This takes you to the pipeline configuration page.

### Configure Your Pipeline

- Pipeline Description (Optional): Add a brief description of your pipeline.
- Pipeline Definition: Choose "Pipeline script" in the Pipeline section.

### The Pipeline Script

```groovy
pipeline {
    agent any

    environment {
        GIT_URL = 'https://gitlab.com/demo410946/my-jenkins-java-project.git'
        GIT_CREDENTIALS_ID = 'mqx5uzxm-534d-fg63-3mhp-hgcpuwra4mac'
    }

    stages {
        stage('Clean') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GIT_URL}", credentialsId: "${GIT_CREDENTIALS_ID}"
            }
        }

        stage('Hello') {
            steps {
                echo 'Hello, this is the beginning of the pipeline.'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -U'
            }
        }
    }
}
```

### Save and Run Your Pipeline

- Save: Click "Save" at the bottom of the configuration page.
- Build: Back on the project page, click "Build Now" to run your pipeline.
- Build History: A new build will appear in the "Build History".
- Console Output: Click on the build number and then "Console Output" to see the results.

If everything went well, you should find your built in /var/lib/jenkins/workspace/BasicPipeline.  
You can run the jar to test:

```bash
java -jar /var/lib/jenkins/workspace/BasicPipeline/target/my-jenkins-java-project-1.0-SNAPSHOT.jar
```

### Thus, you have successfully created a simple pipeline that cleans the workspace, checks out the main branch of your Java application Git repository and then builds the project using Maven 😎