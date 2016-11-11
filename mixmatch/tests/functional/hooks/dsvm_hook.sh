#!/bin/bash -xe

# Copyright 2017 Massachusetts Open Cloud
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

function get_endpoint_ids {
    echo `openstack endpoint list --service $1 -c ID -f value`
}

function register_mixmatch {
    # Update the endpoints
    openstack endpoint delete `get_endpoint_ids image`
    openstack endpoint delete `get_endpoint_ids volume`
    openstack endpoint delete `get_endpoint_ids volumev2`
    openstack endpoint delete `get_endpoint_ids volumev3`

    get_or_create_endpoint \
        "image" \
        "$REGION_NAME" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/image" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/image" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/image"

    get_or_create_endpoint \
        "volume" \
        "$REGION_NAME" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v1/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v1/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v1/\$(project_id)s"

    get_or_create_endpoint \
        "volumev2" \
        "$REGION_NAME" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v2/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v2/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v2/\$(project_id)s"

    get_or_create_endpoint \
        "volumev3" \
        "$REGION_NAME" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v3/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v3/\$(project_id)s" \
        "$MIXMATCH_SERVICE_PROTOCOL://$HOST_IP:$MIXMATCH_SERVICE_PORT/volume/v3/\$(project_id)s"
}

register_mixmatch

exit 0
