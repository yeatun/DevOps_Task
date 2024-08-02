kubectl describe statefulset testelasticsearch1 -n testels
Name:               testelasticsearch1
Namespace:          testels
CreationTimestamp:  Fri, 02 Aug 2024 11:15:31 +0000
Selector:           app=testelasticsearch1
Labels:             app=testelasticsearch1
                    app.kubernetes.io/managed-by=Helm
Annotations:        esMajorVersion: 7
                    meta.helm.sh/release-name: testelasticsearch1
                    meta.helm.sh/release-namespace: testels
Replicas:           1 desired | 1 total
Update Strategy:    RollingUpdate
Pods Status:        1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=testelasticsearch1
  Init Containers:
   configure-sysctl:
    Image:      docker.elastic.co/elasticsearch/elasticsearch:7.17.3
    Port:       <none>
    Host Port:  <none>
    Command:
      sysctl
      -w
      vm.max_map_count=262144
    Environment:  <none>
    Mounts:       <none>
  Containers:
   elasticsearch:
    Image:       docker.elastic.co/elasticsearch/elasticsearch:7.17.3
    Ports:       9200/TCP, 9300/TCP
    Host Ports:  0/TCP, 0/TCP
    Limits:
      cpu:     1
      memory:  2Gi
    Requests:
      cpu:      500m
      memory:   1Gi
    Readiness:  exec [bash -c set -e
# If the node is starting up wait for the cluster to be ready (request params: "wait_for_status=green&timeout=1s" )
# Once it has started only check that the node itself is responding
START_FILE=/tmp/.es_start_file

# Disable nss cache to avoid filling dentry cache when calling curl
# This is required with Elasticsearch Docker using nss < 3.52
export NSS_SDB_USE_CACHE=no

http () {
  local path="${1}"
  local args="${2}"
  set -- -XGET -s

  if [ "$args" != "" ]; then
    set -- "$@" $args
  fi

  if [ -n "${ELASTIC_PASSWORD}" ]; then
    set -- "$@" -u "elastic:${ELASTIC_PASSWORD}"
  fi

  curl --output /dev/null -k "$@" "http://127.0.0.1:9200${path}"
}

if [ -f "${START_FILE}" ]; then
  echo 'Elasticsearch is already running, lets check the node is healthy'
  HTTP_CODE=$(http "/" "-w %{http_code}")
  RC=$?
  if [[ ${RC} -ne 0 ]]; then
    echo "curl --output /dev/null -k -XGET -s -w '%{http_code}' \${BASIC_AUTH} http://127.0.0.1:9200/ failed with RC ${RC}"
    exit ${RC}
  fi
  # ready if HTTP code 200, 503 is tolerable if ES version is 6.x
  if [[ ${HTTP_CODE} == "200" ]]; then
    exit 0
  elif [[ ${HTTP_CODE} == "503" && "7" == "6" ]]; then
    exit 0
  else
    echo "curl --output /dev/null -k -XGET -s -w '%{http_code}' \${BASIC_AUTH} http://127.0.0.1:9200/ failed with HTTP code ${HTTP_CODE}"
    exit 1
  fi

else
  echo 'Waiting for elasticsearch cluster to become ready (request params: "wait_for_status=yellow&timeout=1s" )'
  if http "/_cluster/health?wait_for_status=green&timeout=1s" "--fail" ; then
    touch ${START_FILE}
    exit 0
  else
    echo 'Cluster is not yet ready (request params: "wait_for_status=green&timeout=1s" )'
    exit 1
  fi
fi
] delay=180s timeout=10s period=10s #success=3 #failure=3
    Environment:
      node.name:                              (v1:metadata.name)
      cluster.initial_master_nodes:          elasticsearch1-0
      discovery.seed_hosts:                  tetselasticsearch1
      cluster.name:                          testelasticsearch1
      network.host:                          0.0.0.0
      cluster.deprecation_indexing.enabled:  false
      ES_JAVA_OPTS:                          -Xmx1g -Xms1g
      node.data:                             true
      node.ingest:                           true
      node.master:                           true
      node.ml:                               true
      node.remote_cluster_client:            true
    Mounts:
      /usr/share/elasticsearch/data from testelasticsearch1 (rw)
      /usr/share/elasticsearch/logs from elasticsearch-log (rw)
   elasticsearch-exporter:
    Image:      quay.io/prometheuscommunity/elasticsearch-exporter:v1.5.0
    Port:       9114/TCP
    Host Port:  0/TCP
    Limits:
      cpu:     100m
      memory:  128Mi
    Requests:
      cpu:     100m
      memory:  128Mi
    Environment:
      ES_URI:  <set to the key 'esURI' in secret 'es-secret'>  Optional: false
    Mounts:    <none>
   elasticsearch-logrotate:
    Image:      blacklabelops/logrotate:latest
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     50m
      memory:  200Mi
    Requests:
      cpu:     50m
      memory:  200Mi
    Environment:
      LOGS_DIRECTORIES:              /usr/share/elasticsearch/logs
      LOGROTATE_INTERVAL:            hourly
      LOGROTATE_COPIES:              1
      LOGROTATE_POSTROTATE_COMMAND:  pkill -SIGUSR1 elasticsearch >/dev/null 2>&1
      LOGROTATE_SIZE:                10M
    Mounts:
      /usr/share/elasticsearch/logs/ from elasticsearch-log (rw)
   elasticsearch-fluentd:
    Image:      fluent/fluentd:v1.4.2-debian-2.0
    Port:       <none>
    Host Port:  <none>
    Args:
      -c
      /etc/fluentd-config/fluentd.conf
    Limits:
      cpu:     50m
      memory:  200Mi
    Requests:
      cpu:     25m
      memory:  100Mi
    Environment:
      TINI_SUBREAPER:
    Mounts:
      /etc/fluentd-config/fluentd.conf from config-volume (rw,path="fluentd.conf")
      /usr/share/elasticsearch/logs/ from elasticsearch-log (rw)
  Volumes:
   elasticsearch-log:
    Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    Medium:
    SizeLimit:  <unset>
   config-volume:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      elasticsearch-fluentd-config
    Optional:  false
Volume Claims:
  Name:          testelasticsearch1
  StorageClass:  longhorn
  Labels:        <none>
  Annotations:   <none>
  Capacity:      20Gi
  Access Modes:  [ReadWriteOnce]
Events:
  Type    Reason            Age   From                    Message
  ----    ------            ----  ----                    -------
  Normal  SuccessfulCreate  39m   statefulset-controller  create Pod testelasticsearch1-0 in StatefulSet testelasticsearch1 successful