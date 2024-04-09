#
# Copyright © 2020-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
from ansible.module_utils.basic import AnsibleModule
from packaging.version import parse as parse_version
import os


def main():
  module_args = {
    "add": {"default": [], "type": list},
    "existing": {"required": True, "type": dict},
    "cadence_number": {"default": "0.0.0", "type": str},
    "cadence_name": {"default": "lts", "type": str},
}

  results = dict(
    changed=False,
    ansible_facts=dict(),
    result=dict()
  )

  module = AnsibleModule(
    argument_spec=module_args,
    supports_check_mode=True
  )

  if module.check_mode:
    module.exit_json(**results)

  try:
    if len(module.params['add']) > 0:
      for overlay in module.params['add']:
        
        # Version checks
        minVersion = parse_version(str(overlay.setdefault("min", "0.0.0")))
        if "max" in overlay and module.params["cadence_name"].lower() == "fast":
          continue
        maxVersion = parse_version(str(overlay.setdefault("max", "9999.9999.9999")))
        existingVersion = parse_version(module.params['cadence_number'])
        if ((existingVersion < minVersion) and module.params["cadence_name"].lower() != "fast") or (existingVersion > maxVersion):
          continue

        priority = str(overlay.setdefault("priority", 1))
        phase = "pre" if int(priority) < 50 else "post"
        overlay.pop("priority", None)
        overlay_type = list(overlay.keys())[0]

        # set correct path for vdm or sas-bases patches
        folderPath = os.path.join("site-config/vdm", overlay_type) if bool(overlay.setdefault("vdm", False)) else "sas-bases/"
        overlay_path = os.path.join(folderPath, overlay[overlay_type])
        
        module.params['existing'].setdefault(overlay_type, {})
        module.params['existing'][overlay_type].setdefault(phase, {})

        if priority in module.params['existing'][overlay_type][phase]:
          if overlay_path not in module.params['existing'][overlay_type][phase][priority]:
            module.params['existing'][overlay_type][phase][priority].append(overlay_path)
        else:
          module.params['existing'][overlay_type][phase].update({priority: [overlay_path]})

      results['ansible_facts'] = {"vdm_overlays": module.params['existing']}
      module.exit_json(**results)
    else:
      for resource_type, phases in module.params['existing'].items():
        results['result'][resource_type] = {}
        for phase in phases:
          results['result'][resource_type][phase] = []
          for priority in sorted(module.params['existing'][resource_type][phase]):
            results['result'][resource_type][phase] += module.params['existing'][resource_type][phase][priority]
      module.exit_json(**results)
  except Exception as e:
    module.fail_json(error=e, msg="Error occurred")
    raise


if __name__ == '__main__':
  main()
