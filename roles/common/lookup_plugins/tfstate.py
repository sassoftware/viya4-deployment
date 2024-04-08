#
# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import os
import subprocess
import json


from ansible.plugins.lookup import LookupBase
from ansible.module_utils._text import to_native, to_text

class LookupModule(LookupBase):
  def run(self, terms, variables=None, **kwargs):
    ret = []
    for term in terms:
      tmp_source = self._loader.get_real_file(term)
      with open(tmp_source, 'r') as jsonfile:
        jsonfile.seek(0)
        data = json.load(jsonfile)
        ret.append(data["outputs"])
    return ret
