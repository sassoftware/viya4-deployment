from ansible.module_utils.basic import *
import glob
import yaml
import os

class siteConfig(object):
  def __init__(self, basedir):
    self._resources = []
    self._generators = []
    self._transformers = []
    self._configurations = []
    self._basedir = os.path.join(basedir, '')

  def set_transformers(self, transformer):
    self._transformers.append(self.remove_basedir(transformer))

  def get_transformers(self):
    return self._transformers

  def set_generators(self, generator):
    self._generators.append(self.remove_basedir(generator))

  def get_generators(self):
    return self._generators

  def set_resources(self, resource):
    self._resources.append(self.remove_basedir(resource))

  def get_resources(self):
    return self._resources

  def set_configurations(self, configuration):
    self._configurations.append(self.remove_basedir(configuration))

  def get_configurations(self):
    return self._configurations

  def remove_basedir(self, configpath):
      if configpath.startswith(self._basedir):
        return configpath[len(self._basedir):]
      return configpath

  def addResource(self, yamlfile):
    with open(yamlfile) as file:
      yamlblocks = list(yaml.load_all(file, Loader=yaml.SafeLoader))

      if "apiVersion" in yamlblocks[0]:
        if yamlblocks[0]['apiVersion'] == "builtin":
          if "kind" in yamlblocks[0]:
            # handle transformers
            if yamlblocks[0]['kind'].endswith("Transformer"):
              self.set_transformers(yamlfile)

            # handle generators
            elif yamlblocks[0]['kind'].endswith("Generator"):
              self.set_generators(yamlfile)
        else:
          # treat all non builtins as resources
          self.set_resources(yamlfile)
      # handle configurations
      elif "nameReference" in yamlblocks[0]:
        self.set_configurations(yamlfile)


  def traverse(self, folder):
    # handle kustomization
    if os.path.exists(os.path.join(folder, "kustomization.yaml")) or os.path.exists(os.path.join(folder, "kustomization.yml")):
      kustomizefile = "kustomization.yaml" if os.path.exists(os.path.join(folder, "kustomization.yaml")) else "kustomization.yml"
      self.set_resources(folder)

      # handle files not listed in kustomization
      yamlfiles = glob.glob(os.path.join(folder, "*.yaml"))
      yamlfiles.extend(glob.glob(os.path.join(folder, "*.yml")))

      with open(os.path.join(folder,kustomizefile), 'r') as f:
        try:
          for k, v in yaml.safe_load(f).items():
            if isinstance(v, list):
              for yamlfile in yamlfiles:
                if os.path.relpath(yamlfile, folder) not in v:
                  self.addResource(yamlfile)
        except yaml.YAMLError as exc:
          raise RuntimeError("Error parsing kustomization {} as yaml".format(os.path.join(folder,kustomizefile))) from exc
      return

    # check for subfolders
    for f in next(os.walk(folder))[1]:
      self.traverse(os.path.join(folder, f))

    # get list of yaml files
    yamlfiles = glob.glob(os.path.join(folder, "*.yaml"))
    yamlfiles.extend(glob.glob(os.path.join(folder, "*.yml")))

    for yamlfile in yamlfiles:
      self.addResource(yamlfile)

def main():
  fields = {
    "path": {"required": True, "type": "str"},
    "exclude": {"default": [], "type": list},
  }
  module = AnsibleModule(argument_spec=fields)
  try:
    sc = siteConfig(module.params['path'])
    scFolder = os.path.join(module.params['path'], 'site-config')
    _, folders, _ = next(os.walk(scFolder))
    for folder in folders:
      skip = False
      for exclude in module.params['exclude']:
        if folder == exclude:
          skip = True
      if not skip:
        sc.traverse(os.path.join(scFolder, folder))
    module.exit_json(changed=True, resources=sc.get_resources(), generators=sc.get_generators(), transformers=sc.get_transformers(), configurations=sc.get_configurations())
  except StopIteration:
    pass
  except Exception as e:
    module.fail_json(error=e,msg="Error parsing site-config path")
    raise

if __name__ == '__main__':
  main()
