#-*-coding:utf-8-*-
# 本文件完全拷贝了GitHub上文件，链接为https://github.com/z521598/order-pyyaml/blob/master/yamlparser.py
import os
from collections import OrderedDict

import yaml


def ordered_yaml_load(yaml_path, Loader = yaml.Loader, object_pairs_hook = OrderedDict):
    class OrderedLoader(yaml.Loader):
        pass
    def construct_mapping(loader, node):
        loader.flatten_mapping(node)
        return object_pairs_hook(loader.construct_pairs(node))
    OrderedLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping)
    with open(yaml_path) as stream:
        return yaml.load(stream, OrderedLoader)

def ordered_yaml_dump(data, output_file_name = None, Dumper = yaml.SafeDumper, **kwds):
    class OrderedDumper(yaml.SafeDumper):
        pass
    def _dict_representer(dumper, data):
        return dumper.represent_mapping(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, data.items())
    OrderedDumper.add_representer(OrderedDict, _dict_representer)
    with open(output_file_name, 'w') as f:
        yaml.dump(data, f, OrderedDumper, **kwds)
    return None
