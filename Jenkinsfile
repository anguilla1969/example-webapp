        def builderImage
        def productionImage
        def ACCOUNT_REGISTRY_PREFIX
        def GIT_COMMIT_HASH
        def PRINT_ENV

        // REFERENCES:
        //      https://github.com/thearthur/example-webapp
        //      https://github.com/anguilla1969/example-webapp
        //
        // TODO:
        //      7.      Implement a way to push a commit to 'release' branch (e.g. tag)
        //              a. git push origin master:release
        //
        //              OPEN: 03/18/22022
        //              RESOLVED:
        //              NOTES:
        //
        //      6.      OpenJDK 64-Bit Server VM warning: INFO: os::commit_memory(0x00000000f90c4000, 196608, 0)
        //                  failed; error='Cannot allocate memory' (errno=12)
        //
        //                  REFERENCES:
        //                      https://stackoverflow.com/questions/18078859/java-run-out-of-memory-issue
        //
        //                  There is insufficient memory for the Java Runtime Environment to continue.
        //                  Native memory allocation (mmap) failed to map 196608 bytes for committing reserved memory.
        //
        //                  Possible reasons:
        //                      The system is out of physical RAM or swap space
        //                      The process is running with CompressedOops enabled, and the Java Heap may be blocking the growth of the native heap
        //
        //                  Possible solutions:
        //                      Reduce memory load on the system
        //                      Increase physical memory or swap space
        //                      Check if swap backing store is full
        //                      Decrease Java heap size (-Xmx/-Xms)
        //                      Decrease number of Java threads
        //                      Decrease Java thread stack sizes (-Xss)
        //                      Set larger code cache with -XX:ReservedCodeCacheSize=
        //                      JVM is running with Unscaled Compressed Oops mode in which the Java heap is
        //                          placed in the first 4GB address space. The Java Heap base address is the
        //                      maximum limit for the native heap growth. Please use -XX:HeapBaseMinAddress
        //                          to set the Java Heap base and to place the Java Heap above 4GB virtual address.
        //
        //                      [ec2-user@ip-172-31-46-153 example-webapp_master]$ date; cat /proc/meminfo | grep Mem -A5
        //                          Fri Mar 18 02:54:01 UTC 2022
        //                              MemTotal:        1005820 kB
        //                              MemFree:          165904 kB
        //                              MemAvailable:     216132 kB
        //                              Buffers:               0 kB
        //                              Cached:           171988 kB
        //                              SwapCached:            0 kB
        //                              Active:           647328 kB
        //                              Inactive:         105228 kB
        //
        //              [ec2-user@ip-172-31-46-153 example-webapp_master]$ date; sudo ps auxf | grep java | grep -v grep
        //              Fri Mar 18 03:03:30 UTC 2022
        //
        //              jenkins   3997  1.4 46.8 2475040 471656 ?
        //                      Ssl  00:31   2:13 /usr/bin/java -Djava.awt.headless=true -jar /usr/share/java/jenkins.war --webroot=%C/jenkins/war --httpPort=8080
        //
        //              OPEN: 3/17/2022
        //              RESOLVED:
        //              NOTES:
        //
        //      5.      When trying to push to github repo
        //              a. denied: Your authorization token has expired. Re-authenticate and try again.
        //
        //              OPEN: 03/17/2022
        //              RESOLVED:
        //              NOTES:
        //
        //      4.      do all changes/commits via the IDEA
        //
        //              OPEN: 03/15/2022
        //              RESOLVED: 03/16/2022
        //              NOTES: from windows: ssh -T git@github.com is working
        //
        //      3.      Run all stages without errors before processing with class
        //
        //              OPEN: 03/15/2022
        //              RESOLVED:
        //              NOTES: 03/17/2022: This is WIP but build#17 caused OOM error but webapp-builder did get built locally
        //
        //      2.      Execute Linux commands
        //
        //              OPEN: 03/15/2022
        //              RESOLVED:
        //
        //      1.      List all ENV variables
        //
        //              OPEN: 03/15/2022
        //              CLOSED: 3/17/2022
        //              NOTES:
        //

        pipeline {

            agent any

            stages {
                stage('Checkout Source Code and Logging Into Registry') {
                    steps {
                        echo 'Logging Into the Private ECR Registry'
                        script {
                            GIT_COMMIT_HASH = sh (script: "git log -n 1 --pretty=format:'%H'", returnStdout: true)
                            ACCOUNT_REGISTRY_PREFIX = "351403397006.dkr.ecr.us-east-1.amazonaws.com"
                            sh """
                            \$(aws ecr get-login --no-include-email --region us-east-1)
                            """
                        }
                    }
                }

                stage('Make A Builder Image') {
                    steps {

                        script {
                            PRINT_ENV = sh (script: "env|sort", returnStdout: true)
                        }

                        echo "ENV (start): \n\n"
                        echo  "${PRINT_ENV}"
                        echo "ENV (end): \n\n"
                        echo "Starting to build the project builder docker image"
                        echo "account: ${ACCOUNT_REGISTRY_PREFIX}"
                        echo "hash: ${GIT_COMMIT_HASH}"

                        script {

                            try {
                                builderImage = docker.build("${ACCOUNT_REGISTRY_PREFIX}/example-webapp-builder:${GIT_COMMIT_HASH}", "-f ./Dockerfile.builder .")
                            }
                            catch (Exception e)  {
                                error 'Build error. Exception'
                                throw e
                                exit 1
                            }

                            try {
                                builderImage.push()
                            }
                            catch (Exception e)  {
                                echo 'Build (with tag) error. Exception '
                                throw e
                                exit 1
                            }

                            try {
                                builderImage.push("${env.GIT_BRANCH}")
                            }
                            catch (Exception e)  {
                                echo 'Build (with tag) error. Exception '
                                throw e
                                exit 1
                            }

                            try {
                                builderImage.inside('-v $WORKSPACE:/output -u root') {
                                    sh """
                                    cd /output
                                    lein uberjar
                                    """
                                }
                            }
                            catch (Exception e)  {
                                echo 'Exception '
                                throw e
                                exit 1
                            }
                        }
                    }
                }

                stage('Unit Tests') {
                    steps {
                        echo 'running unit tests in the builder image.'
                        script {
                            builderImage.inside('-v $WORKSPACE:/output -u root') {
                            sh """
                               cd /output
                               lein test
                            """
                            }
                        }
                    }
                }

                stage('Build Production Image') {
                    steps {
                        echo 'Starting to build docker image'
                        script {
                            productionImage = docker.build("${ACCOUNT_REGISTRY_PREFIX}/example-webapp:${GIT_COMMIT_HASH}")
                            productionImage.push()
                            productionImage.push("${env.GIT_BRANCH}")
                        }
                    }
                }


                stage('Deploy to Production fixed server') {
                     when {
                         branch 'release'
                     }
                     steps {
                         echo 'Deploying release to production'
                         script {
                             productionImage.push("deploy")
                             sh """
                                aws ec2 reboot-instances --region us-east-1 --instance-ids i-0499258c088415b71
                             """
                         }
                     }
                }

                stage('Integration Tests') {
                    when {
                        branch 'master'
                    }
                    steps {
                        echo 'Deploy to test environment and run integration tests'
                        script {
                            TEST_ALB_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:351403397006:listener/app/testing-website/b683de8989fc1cab/9e4dbb8d525774c5"
                            sh """
                            ./run-stack.sh example-webapp-test ${TEST_ALB_LISTENER_ARN}
                            """
                        }
                        echo 'Running tests on the integration test environment'
                        script {
                            sh """
                               curl -v testing-website-1542857192.us-east-1.elb.amazonaws.com | grep '<title>Welcome to example-webapp</title>'
                               if [ \$? -eq 0 ]
                               then
                                   echo tests pass
                               else
                                   echo tests failed
                                   exit 1
                               fi
                            """
                        }
                    }
                }


                stage('Deploy to Production') {
                     when {
                         branch 'master'
                     }
                     steps {
                         script {
                             PRODUCTION_ALB_LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:351403397006:listener/app/production-website/27e6120c7cc2ea33/a70d24280d76ceb3"
                             sh """
                             ./run-stack.sh example-webapp-production ${PRODUCTION_ALB_LISTENER_ARN}
                             """
                         }
                     }
                }
            }
        }
