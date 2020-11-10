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

def traverse(folder, siteconfig):
  ## Check for kustomization.yaml
  if os.path.exists(os.path.join(folder, "kustomization.yaml")):
    siteconfig.set_resources(folder)
    return

  # check for subfolders
  for f in next(os.walk(folder))[1]:
    traverse(os.path.join(folder, f), siteconfig)

  ## get list of yaml files
  for yamlfile in glob.glob(os.path.join(folder, "*.yaml")):

    ## check for kustomizeconfig.yaml
    if yamlfile.endswith("kustomizeconfig.yaml"):
      siteconfig.set_configurations(os.path.join(folder, "kustomizeconfig.yaml"))
      continue
    ## load file as yaml
    with open(yamlfile) as file:
      yamlblocks = list(yaml.load_all(file, Loader=yaml.SafeLoader))

      if "apiVersion" in yamlblocks[0]:
        if yamlblocks[0]['apiVersion'] == "builtin":
          ##handle transformers
          if "kind" in yamlblocks[0]:
            print("found", yamlblocks[0]["kind"])
            ## handle transformers
            if yamlblocks[0]['kind'].endswith("Transformer"):
              siteconfig.set_transformers(yamlfile)

            ##handle generators
            elif yamlblocks[0]['kind'].endswith("Generator"):
              siteconfig.set_generators(yamlfile)
        else:
        ## treat all non builtins as resources
          siteconfig.set_resources(yamlfile)

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
        traverse(os.path.join(scFolder, folder), sc)
    module.exit_json(changed=True, resources=sc.get_resources(), generators=sc.get_generators(), transformers=sc.get_transformers(), configurations=sc.get_configurations())
  except StopIteration:
    pass
  except Exception as e:
    module.fail_json(error=e,msg="Error pasing site-config path")
    raise


if __name__ == '__main__':
  main()
