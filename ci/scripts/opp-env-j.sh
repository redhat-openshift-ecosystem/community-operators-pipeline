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
    
    
    KIND_KUBE_VERSION_DETECTED_RAW=1.19



    KIND_KUBE_VERSION_DETECTED_CORE=$(echo $KIND_KUBE_VERSION_DETECTED_RAW| cut -f -2 -d'.')
    echo "KIND_KUBE_VERSION_DETECTED_CORE=$KIND_KUBE_VERSION_DETECTED_CORE"
    
    if [ "$KIND_KUBE_VERSION_DETECTED_CORE" != "null" ]; then



            function semver_compare() {
            SEMVER_BIGGER_OUT_OF_RANGE=0
            SEMVER_SMALLER_OUT_OF_RANGE=0
              VER1_A=$(echo $1|cut -f 1 -d'.')
              echo "VER1_A=$VER1_A"
              VER1_B=$(echo $1|cut -f 2 -d'.')
              echo "VER1_B=$VER1_B"
              VER2_A=$(echo $2|cut -f 1 -d'.')
              echo "VER2_A=$VER2_A"
              VER2_B=$(echo $2|cut -f 2 -d'.')
              echo "VER2_B=$VER2_B"
              

              if (($VER1_A > $VER2_A))
              then
                  SEMVER_BIGGER_OUT_OF_RANGE=1
                  echo "$VER1_A is bigger than $VER2_A"
              elif (($VER1_A == $VER2_A))
              then
                  if (($VER1_B > $VER2_B))
                  then
                    SEMVER_BIGGER_OUT_OF_RANGE=1
                    echo "$VER1_B is bigger than $VER2_B"
                  fi
              
              fi

              if (($VER1_A < $VER2_A))
              then
                  SEMVER_SMALLER_OUT_OF_RANGE=1
                  echo "$VER1_A is smaller than $VER2_A"
              elif (($VER1_A == $VER2_A))
              then
                  if (($VER1_B < $VER2_B))
                  then
                    SEMVER_SMALLER_OUT_OF_RANGE=1
                    echo "$VER1_B is smaller than $VER2_B"
                  fi
              
              fi

            }

            semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MIN_SUPPORTED

            if [ $SEMVER_SMALLER_OUT_OF_RANGE -eq 1 ]; then
              echo "Kubernetes $KIND_KUBE_VERSION_DETECTED_CORE defined in 'operatorhub.io/ui-metadata-max-k8s-version' is not supported.       [FAIL]"
              exit 1
            else

              semver_compare $KIND_KUBE_VERSION_DETECTED_CORE $KIND_MAX_SUPPORTED

              if [ $SEMVER_BIGGER_OUT_OF_RANGE -eq 1 ]; then
                KIND_KUBE_VERSION_DETECTED="v$KIND_MAX_SUPPORTED.${KIND_SUPPORT_TABLE[$KIND_MAX_SUPPORTED]}"
                echo "Bigger, setting KIND_KUBE_VERSION_DETECTED to $KIND_KUBE_VERSION_DETECTED"
              else 
                KIND_KUBE_VERSION_DETECTED="v$KIND_KUBE_VERSION_DETECTED_CORE.${KIND_SUPPORT_TABLE[$KIND_KUBE_VERSION_DETECTED_CORE]}"
                echo "In range, setting KIND_KUBE_VERSION_DETECTED to $KIND_KUBE_VERSION_DETECTED"
              fi
            fi

            echo "::set-output name=kind_kube_version::$KIND_KUBE_VERSION_DETECTED"
            echo "Exported $KIND_KUBE_VERSION_DETECTED"
    else
            echo "::set-output name=kind_kube_version::$KIND_KUBE_VERSION_LATEST" # consider KIND_MAX_SUPPORTED instead of latest
            KIND_KUBE_VERSION_DETECTED="$KIND_KUBE_VERSION_LATEST"
            echo "K8S UI version not defined, using from config $KIND_KUBE_VERSION_DETECTED"
    fi

    echo "Kind kube version $KIND_KUBE_VERSION_DETECTED will be installed in an appropriate step."

}


detect_k8s_max
