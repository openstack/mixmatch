#   Copyright 2017 Massachusetts Open Cloud
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.

from mixmatch import auth
from mixmatch.config import CONF, service_providers
from mixmatch.extend import base
from mixmatch import utils

import flask
from neutronclient.v2_0 import client as neutron
from neutronclient.common import exceptions as n_ex
from oslo_serialization import jsonutils


class ExtendNetwork(base.Extension):

    ROUTES = [
        base.Route(service='network', version='v2.0',
                   action=['networks/extended'], method='POST')
        # note that 'extended" is an adjective,
        # analogous to Sahara's POST /clusters/multiple
        # this should smell a lot like POST /networks, because user should be
        #  able to set everything they usually set during network creation
    ]

    @staticmethod
    def _get_remote_project_id(request_project_id):
        # TODO(jfreud): cache me
        return request_project_id  # FIXME

    def handle_request(self, request):
        body = jsonutils.loads(request.body)
        destination_sp = utils.safe_get(request.headers, 'MM-SERVICE-PROVIDER')
        existing_net_id = utils.safe_pop(body, 'existing_net')
        if destination_sp is None or existing_net_id is None:
            flask.abort(400)
        # TODO(jfreud): avoid copy-paste of getting enabled SPs
        enabled_sps = filter(
            lambda sp: (request.service in
                        service_providers.get(CONF, sp).enabled_services),
            CONF.service_providers
        )
        if destination_sp not in enabled_sps:
            flask.abort(422)
        # TODO(jfreud): get session directly!
        admin_session = auth.get_client(destination_sp).session
        admin_neutronclient = neutron(admin_session)
        try:
            # TODO(jfreud): cache me
            original = admin_neutronclient.show_network(existing_net_id)
        except n_ex.NotFound:
            flask.abort(422)
        remote_project_id = self._get_remote_project_id(request.project_id)
        if original['network']['project_id'] != remote_project_id:
            flask.abort(403)
        body['network']['provider:network_type'] = 'vxlan'
        vxlan_id = original['network']['provider:segmentation_id']
        # TODO(jfreud): avoid various vxlan collisions
        body['network']['provider:segmentation_id'] = vxlan_id
        body['network']['project_id'] = remote_project_id
        new_net = admin_neutronclient.create_network(body)
        # TODO(jfreud): logging, actually need logging everywhere
        return flask.Response(jsonutils.dumps(new_net),
                              201,
                              content_type='application/json')
