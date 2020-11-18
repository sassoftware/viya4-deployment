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
      stuff = subprocess.check_output(['terraform', 'output', '-json','-state', tmp_source])
      j = json.loads(stuff)
      ret.append(j)
    return ret