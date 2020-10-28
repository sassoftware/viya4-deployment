from ansible.module_utils.basic import *
import glob
import yaml


def main():
  fields = {
    "add": {"default": [], "type": list},
    "existing": {"required": True, "type": dict},
  }
  module = AnsibleModule(argument_spec=fields)

  try:
    if len(module.params['add']) > 0:
      for overlay in module.params['add']:
        priority = str(overlay.setdefault("priority", 1))
        phase = "pre" if int(priority) < 50 else "post"
        overlay.pop("priority", None)

        overlay_type = list(overlay.keys())[0]
        overlay_path = overlay[overlay_type]
        
        if priority in module.params['existing'][overlay_type][phase]:
          module.params['existing'][overlay_type][phase][priority].append(overlay_path)
        else:
          module.params['existing'][overlay_type][phase].update({priority: [overlay_path]})

      module.exit_json(changed=True, result=module.params['existing'])
    else:
      res = {}
      for resource_type, phases in module.params['existing'].items():
        res[resource_type] = {}
        for phase in phases:
            res[resource_type][phase] = []
            for overlays in phases[phase].values():
              res[resource_type][phase] += overlays

      module.exit_json(changed=True, result=res)
  except Exception as e:
    module.fail_json(error=e,msg="Error HERE")
    raise


if __name__ == '__main__':
  main()
