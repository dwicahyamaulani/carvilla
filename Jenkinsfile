pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
      - cat
    tty: true
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker
      - name: workspace
        mountPath: /workspace
  volumes:
    - name: kaniko-secret
      secret:
        secretName: regcred
    - name: workspace
      emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY_URL = "registry.registry.svc.cluster.local:5000"
        IMAGE_NAME = "carvilla"
    }

    stages {
        stage('Checkout') {
            steps {
                container('kaniko') {
                    checkout scm
                }
            }
        }

        stage('Build and Push Image') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                      --context=/workspace \
                      --dockerfile=/workspace/Dockerfile \
                      --destination=${REGISTRY_URL}/${IMAGE_NAME}:${BUILD_ID} \
                      --insecure \
                      --skip-tls-verify
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kaniko') {
                    sh '''
                    sed -i "s/BUILD_NUMBER/${BUILD_ID}/g" kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('kaniko') {
                    sh "kubectl rollout status deployment/carvilla-web --timeout=60s"
                }
            }
        }
    }

    post {
        success {
            echo "🎉 Build & Deploy via Kaniko berhasil!"
        }
        failure {
            echo "❌ Pipeline Kaniko gagal. Cek log."
        }
    }
}
