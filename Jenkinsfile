pipeline {
  agent any

  environment {
    APP_NAME       = 'devsecops-sample-app'
    IMAGE_REPO     = 'ghcr.io/pranay9-h/devsecops-sample-app'
    IMAGE_TAG      = "${BUILD_NUMBER}"
    NAMESPACE      = 'devsecops-demo'
    DEPLOYMENT     = 'sample-api'
    KUBECONFIG_CRED = 'eks-kubeconfig'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        sh '''
          python3 -m venv .venv
          . .venv/bin/activate
          python -m pip install --upgrade pip
          pip install -r app/requirements.txt -r app/requirements-dev.txt
          cd app
          pytest -q
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonarqube') {
          sh 'sonar-scanner'
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('OWASP Dependency Check') {
      steps {
        dependencyCheck additionalArguments: '--scan app --format HTML --format JSON', odcInstallation: 'dependency-check'
        dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
      }
    }

    stage('Docker Build') {
      steps {
        sh 'docker build -t $IMAGE_REPO:$IMAGE_TAG .'
      }
    }

    stage('Trivy Scan') {
      steps {
        sh '''
          trivy image             --exit-code 1             --severity HIGH,CRITICAL             --ignore-unfixed             $IMAGE_REPO:$IMAGE_TAG
        '''
      }
    }

    stage('Push Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'container-registry',
          usernameVariable: 'REGISTRY_USER',
          passwordVariable: 'REGISTRY_TOKEN'
        )]) {
          sh '''
            echo "$REGISTRY_TOKEN" | docker login ghcr.io -u "$REGISTRY_USER" --password-stdin
            docker push $IMAGE_REPO:$IMAGE_TAG
            docker logout ghcr.io
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CRED, variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG="$KUBECONFIG_FILE"
            kubectl apply -f kubernetes/namespace.yaml
            kubectl apply -f kubernetes/service.yaml
            kubectl apply -f kubernetes/deployment.yaml
            kubectl -n "$NAMESPACE" set image deployment/"$DEPLOYMENT"               sample-api="$IMAGE_REPO:$IMAGE_TAG"
            kubectl -n "$NAMESPACE" set env deployment/"$DEPLOYMENT" APP_VERSION="$IMAGE_TAG"
          '''
        }
      }
    }

    stage('Deployment Health Check') {
      steps {
        withCredentials([file(credentialsId: env.KUBECONFIG_CRED, variable: 'KUBECONFIG_FILE')]) {
          sh '''
            export KUBECONFIG="$KUBECONFIG_FILE"
            chmod +x scripts/health-check.sh scripts/rollback.sh
            scripts/health-check.sh
          '''
        }
      }
    }
  }

  post {
    failure {
      script {
        if (env.STAGE_NAME == 'Deployment Health Check' || env.STAGE_NAME == 'Deploy to Kubernetes') {
          withCredentials([file(credentialsId: env.KUBECONFIG_CRED, variable: 'KUBECONFIG_FILE')]) {
            sh '''
              export KUBECONFIG="$KUBECONFIG_FILE"
              chmod +x scripts/rollback.sh
              scripts/rollback.sh || true
            '''
          }
        }
      }
    }

    always {
      archiveArtifacts artifacts: '**/dependency-check-report.*', allowEmptyArchive: true
      cleanWs()
    }
  }
}
