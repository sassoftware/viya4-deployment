from ansible.module_utils.basic import AnsibleModule


def main():
  module_args = {
    "add": {"default": [], "type": list},
    "existing": {"required": True, "type": dict},
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
        priority = str(overlay.setdefault("priority", 1))
        phase = "pre" if int(priority) < 50 else "post"
        overlay.pop("priority", None)

        overlay_type = list(overlay.keys())[0]
        overlay_path = overlay[overlay_type]
        
        module.params['existing'].setdefault(overlay_type, {})
        module.params['existing'][overlay_type].setdefault(phase, {})

        if priority in module.params['existing'][overlay_type][phase]:
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
    module.fail_json(error=e)
    raise


if __name__ == '__main__':
  main()