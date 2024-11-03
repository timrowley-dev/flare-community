#!/bin/bash


# WARNING: For automated pipelines, make a private copy of any scripts you use, never pull from a public repository in automated setups.
# Designed to run with named docker instance; makes regional snapshots in the zone of the instance


# Example: ./gcp-snapshot-script.sh <diskname> <dockerContainer> <retentionDays> 
# Example Cronjob: 0 0 */3 * * /home/ubuntu/gcp-snapshot-script.sh <diskname> <dockerContainer> <retentionDays> /home/ubuntu/snapshot-cronjob.log 2>&1

# Example (needs additional configuration): ./gcp-snapshot-script.sh <diskname> <dockerContainer> <STANDARD|ARCHIVE> <retentionDays> 

START_TIME=$(date +%s)

# Check if disk name is provided
if [ -z "$1" ]; then
    echo "Error: Please provide a disk name."
    exit 1
fi

# Docker container name
if [ -z "$2" ]; then
    echo "Error: Please provide a docker container name."
    exit 1
fi


# Days to retain snapshot (will delete via this script)
if [ -z "$3" ]; then
    echo "Error: Please provide snapshot rentention days"
    exit 1
fi

# Snapshot type (e.g. STANDARD or ARCHIVE)
# if [ -z "$4" ]; then
#     echo "Error: Please provide a snapshot type."
#     exit 1
# fi

curl_output=$(curl -s http://localhost:9650/ext/health)

HEALTHY_VALUE=$(echo "$curl_output" | jq -r '.healthy')
if [ -z "$HEALTHY_VALUE" ]; then HEALTHY_VALUE="false"; fi
DISK_NAME="$1"
DOCKER_CONTAINER="$2"
ZONE=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google" | awk -F/ '{print $NF}')
REGION=$(echo "$ZONE" | awk -F- '{print $1"-"$2}')
SNAPSHOT_NAME="$DISK_NAME-$(date +%Y-%m-%d)"
RETENTION_DAYS="$3"
# SNAPSHOT_TYPE="$4"

# Pause node service
echo "Stopping $DOCKER_CONTAINER container..."
docker stop "$DOCKER_CONTAINER"


# Create snapshot (requires https://www.googleapis.com/auth/cloud-platform scope and permissions: compute.disks.createSnapshot, compute.snapshots.create, compute.snapshots.get, and compute.zoneOperations.get)
# Readmore: https://cloud.google.com/sdk/gcloud/reference/compute/disks/snapshot
/snap/bin/gcloud compute disks snapshot "$DISK_NAME" --zone="$ZONE" --snapshot-names="$SNAPSHOT_NAME" --description="Snapshot for $SNAPSHOT_NAME" --labels=healthy="$HEALTHY_VALUE" --storage-location="$REGION" 

# compute snapshots create requires different permissions, worthwhile testing for ability to create archive snapshots
# Readmore: https://cloud.google.com/compute/docs/disks/create-snapshots
# /snap/bin/gcloud compute snapshots create "$SNAPSHOT_NAME" --source-disk-region="$REGION" --source-disk="$DISK_NAME" --snapshot-type="$SNAPSHOT_TYPE" --storage-location="$REGION" --description="Snapshot for $SNAPSHOT_NAME" --labels=healthy="$HEALTHY_VALUE"

# Resume node service
echo "Starting $DOCKER_CONTAINER container..."
docker start "$DOCKER_CONTAINER"

# Delete snapshots older than RETENTION_DAYS
# This assumes snapshot names have the format "$DISK_NAME-YYYY-MM-DD"
for old_snapshot in $(/snap/bin/gcloud compute snapshots list --filter="creationTimestamp<'$(date -d "-$RETENTION_DAYS days" +%Y-%m-%d)' AND name~^$DISK_NAME-" --uri); do
    /snap/bin/gcloud compute snapshots delete "$old_snapshot" --quiet
done

END_TIME=$(date +%s)
DIFF_TIME=$((END_TIME - START_TIME))
echo "Script executed in $DIFF_TIME seconds."
