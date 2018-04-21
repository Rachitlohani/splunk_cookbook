pipeline {
  agent {
    docker {
      image 'test'
    }

  }
  stages {
    stage('') {
      steps {
        sleep 2
      }
    }
    stage('testing') {
      steps {
        sh 'echo test'
      }
    }
  }
  environment {
    test = 'value'
  }
}