#!/bin/bash
# OPerator Pipeline (OPP) env script (opp-env.sh)

# from config
KIND_KUBE_VERSION_LATEST=1.1.1

set -e
declare -A KIND_SUPPORT_TABLE=(["1.24"]="0" ["1.23"]="6" ["1.22"]="9" ["1.21"]="12" ["1.20"]="15" ["1.19"]="16" ["1.18"]="20")
KIND_MIN_SUPPORTED=1.18
KIND_MAX_SUPPORTED=1.24 # DO NOT FORGET TO CHANGE WHEN CHANGING ^


function detect_k8s_max() {
    echo "Detecting if k8s max version is defined..."
    # OPERATOR_VERSION_PATH_LATEST_CSV_PATH=$(find $LATEST -name "*clusterserviceversion*")
    # echo "OPERATOR_VERSION_PATH_LATEST_CSV_PATH=$OPERATOR_VERSION_PATH_LATEST_CSV_PATH"
    # ls $OPERATOR_VERSION_PATH_LATEST_CSV_PATH
    # curl -L https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64 -o /tmp/yq
    # chmod +x /tmp/yq
    # yq --version
    # KIND_KUBE_VERSION_DETECTED_RAW=$(/tmp/yq r "$OPERATOR_VERSION_PATH_LATEST_CSV_PATH" "metadata.annotations.[operatorhub.io/ui-metadata-max-k8s-version]")
    
    
    KIND_KUBE_VERSION_DETECTED_RAW=1.99



    KIND_KUBE_VERSION_DETECTED_CORE=$(echo $KIND_KUBE_VERSION_DETECTED_RAW| cut -f -2 -d'.')
    
    if [ "$KIND_KUBE_VERSION_DETECTED_CORE" != "null" ]; then
            KIND_NOT_SUPPOTED=0
            SEMVER_BIGGER_OUT_OF_RANGE=0
            SEMVER_SMALLER_OUT_OF_RANGE=0

            function semver_compare() {
              local IFS=.
              local i ver1=($1) ver2=($2)
              for ((i=0; i<${#ver1[@]}; i++))
                  do
                      if ((10#${ver1[i]} > 10#${ver2[i]}))
                      then
                          SEMVER_BIGGER_OUT_OF_RANGE=1
                      fi
                      if ((10#${ver1[i]} < 10#${ver2[i]}))
                      then
                          SEMVER_SMALLER_OUT_OF_RANGE=1
                      fi
                  done
            }

            semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MIN_SUPPORTED

            if [ $SEMVER_SMALLER_OUT_OF_RANGE -eq 1 ]; then
              echo "Kubernetes $KIND_KUBE_VERSION_DETECTED_CORE defined in 'operatorhub.io/ui-metadata-max-k8s-version' is not supported.       [FAIL]"
              exit 1
            else

              semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MAX_SUPPORTED

              if [ $SEMVER_BIGGER_OUT_OF_RANGE -eq 1 ]; then
                echo "bigger detected"
                KIND_KUBE_VERSION_DETECTED="v$KIND_MAX_SUPPORTED.${KIND_SUPPORT_TABLE[$KIND_MAX_SUPPORTED]}"
                # KIND_KUBE_VERSION_DETECTED="v$KIND_KUBE_VERSION_DETECTED_CORE.${KIND_SUPPORT_TABLE[${!KIND_MAX_SUPPORTED}]}"
              else 
                KIND_KUBE_VERSION_DETECTED="v$KIND_KUBE_VERSION_DETECTED_CORE.${KIND_SUPPORT_TABLE[$KIND_KUBE_VERSION_DETECTED_CORE]}"
              fi
            fi

            echo "::set-output name=kind_kube_version::$KIND_KUBE_VERSION_DETECTED"
    else
            echo "::set-output name=kind_kube_version::$KIND_KUBE_VERSION_LATEST" # consider KIND_MAX_SUPPORTED instead of latest
            KIND_KUBE_VERSION_DETECTED="$KIND_KUBE_VERSION_LATEST"
    fi

    echo "Kind kube version $KIND_KUBE_VERSION_DETECTED will be installed in an appropriate step."

}


detect_k8s_max
