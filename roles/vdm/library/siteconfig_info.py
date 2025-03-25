#
# Copyright © 2020-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#
from ansible.module_utils.basic import *
import glob
import yaml
import os
from enum import Enum, auto

class Overlay(Enum):
  COMPONENT = "components"
  CONFIGURATION = "configurations"
  GENERATOR = "generators"
  RESOURCE = "resources"
  TRANSFORMER = "transformers"

class siteConfig(object):
  def __init__(self, basedir):
    self._overlays = dict()
    self._basedir = os.path.join(basedir, '')

  def add_overlays(self, overlay_type: Overlay, config: str):
    if overlay_type.value in self._overlays:
      self._overlays[overlay_type.value].append(self.remove_basedir(config))
    else:
      self._overlays[overlay_type.value] = [self.remove_basedir(config)]

  def get_overlays(self) -> dict:
    return self._overlays

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
              self.add_overlays(Overlay.TRANSFORMER, yamlfile)

            # handle generators
            elif yamlblocks[0]['kind'].endswith("Generator"):
              self.add_overlays(Overlay.GENERATOR, yamlfile)
        else:
          # treat all non builtins as resources
          self.add_overlays(Overlay.RESOURCE, yamlfile)
      # handle configurations
      elif "nameReference" in yamlblocks[0]:
        self.add_overlays(Overlay.CONFIGURATION, yamlfile)

  def processSasBasesOverlays(self, folder):
    sasBasesOverlaysPath = os.path.join(folder, "inject-sas-bases-overlays.yaml")
    if os.path.exists(sasBasesOverlaysPath):
      with open(sasBasesOverlaysPath) as file:
        try:
          yamlblock = yaml.safe_load(file)
          for blockName, entries in yamlblock.items():
            if isinstance(entries, list):
              try:
                overlay = Overlay(blockName)
              except ValueError:
                continue
              requiredPrefix = "sas-bases/overlays/"
              for entry in entries:
                if entry.startswith(requiredPrefix):
                  self.add_overlays(overlay, entry)
                else:
                  raise ValueError(f"Invalid {blockName} entry in {sasBasesOverlaysPath}: '{entry}'. Valid entries must start with '{requiredPrefix}'")
        except yaml.YAMLError as exc:
          raise RuntimeError(f"Error parsing {sasBasesOverlaysPath} as yaml") from exc

  def traverse(self, folder):
    self.processSasBasesOverlays(folder)

    if os.path.exists(os.path.join(folder, "kustomization.yaml")) or os.path.exists(os.path.join(folder, "kustomization.yml")):
      kustomizefile = "kustomization.yaml" if os.path.exists(os.path.join(folder, "kustomization.yaml")) else "kustomization.yml"
      kustomizefilefullpath = os.path.join(folder, kustomizefile)

      with open(kustomizefilefullpath) as file:
        try:
          yamlblock = yaml.safe_load(file)
          # handle components
          if "kind" in yamlblock and yamlblock['kind'] == "Component":
            self.add_overlays(Overlay.COMPONENT, folder)
          else:
            # handle kustomization
            self.add_overlays(Overlay.RESOURCE, folder)

            ## lookup all files listed in kustomization
            search = []
            for k, v in yamlblock.items():
              if isinstance(v, list):
                search.extend(v)

            # handle files not listed in kustomization
            yamlfiles = glob.glob(os.path.join(folder, "*.yaml"))
            yamlfiles.extend(glob.glob(os.path.join(folder, "*.yml")))

            for yamlfile in yamlfiles:
              if os.path.relpath(yamlfile, folder) not in search:
                self.addResource(yamlfile)
        
        except yaml.YAMLError as exc:
          raise RuntimeError(f"Error parsing {kustomizefilefullpath} as yaml") from exc
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
    module.exit_json(changed=True, overlays=sc.get_overlays())
  except StopIteration:
    pass
  except Exception as e:
    module.fail_json(error=e,msg="Error parsing site-config path")
    raise

if __name__ == '__main__':
  main()
