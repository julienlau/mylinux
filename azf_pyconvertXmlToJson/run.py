# -*- coding: utf-8 -*-

"""
Azure Functions HTTP Trigger Python Sample
- Get and dump HTTPS request info that the trigger receives

Special Thanks to anthonyeden for great Python HTTP example:
https://github.com/anthonyeden/Azure-Functions-Python-HTTP-Example

Suppoert both Python 2 and 3.X
"""

import os
import string
import json
import xml.etree.ElementTree as ET

_AZURE_FUNCTION_DEFAULT_METHOD = "GET"
_AZURE_FUNCTION_HTTP_INPUT_ENV_NAME = "req"
_AZURE_FUNCTION_HTTP_OUTPUT_ENV_NAME = "res"
_REQ_PREFIX = "REQ_"
_local = False
_verbosity = 0

def make_dict_from_elemlist(element_list):
    """Traverse the given XML element tree to convert it into a dictionary.

    :param element_tree: An XML element tree
    :type element_tree: xml.etree.ElementTree
    :rtype: dict
    """
    accum = []
    if element_list is None:
        return accum
    if not isinstance(element_list, list):
        element_list = [element_list]
    for element in element_list:
        if element.getchildren():
            entry = {}
            for each in element.getchildren():
                entry[each.tag] = each.text
            accum.append(entry)
    return accum

def make_dict_from_tree(element_tree):
    """Traverse the given XML element tree to convert it into a dictionary.

    :param element_tree: An XML element tree
    :type element_tree: xml.etree.ElementTree
    :rtype: dict
    """
    def internal_iter(tree, accum):
        """Recursively iterate through the elements of the tree accumulating
        a dictionary result.

        :param tree: The XML element tree
        :type tree: xml.etree.ElementTree
        :param accum: Dictionary into which data is accumulated
        :type accum: dict
        :rtype: dict
        """
        if tree is None:
            return accum

        if tree.getchildren():
            accum[tree.tag] = {}
            for each in tree.getchildren():
                result = internal_iter(each, {})
                if each.tag in accum[tree.tag]:
                    if not isinstance(accum[tree.tag][each.tag], list):
                        accum[tree.tag][each.tag] = [
                            accum[tree.tag][each.tag]
                        ]
                    accum[tree.tag][each.tag].append(result[each.tag])
                else:
                    accum[tree.tag].update(result)
        else:
            accum[tree.tag] = tree.text

        return accum

    return internal_iter(element_tree, {})

def write_http_response(status, body_dict):
    myjson = json.dumps(body_dict)
    if _verbosity > 0:
        print (myjson)
    return_dict = {
        "status": status,
        "body": myjson,
        "headers": {
            "Content-Type": "application/json"
        }
    }
    output = open(os.environ[_AZURE_FUNCTION_HTTP_OUTPUT_ENV_NAME], 'w')
    output.write(json.dumps(return_dict))


env = os.environ

# Get HTTP METHOD
http_method = env['REQ_METHOD'] if 'REQ_METHOD' in env else _AZURE_FUNCTION_DEFAULT_METHOD
if _verbosity > 0:
    print("HTTP METHOD => {}".format(http_method))

# Get QUERY STRING
req_url = env['REQ_HEADERS_X-ORIGINAL-URL'] if 'REQ_HEADERS_X-ORIGINAL-URL' in env else ''
urlparts = req_url.split('?')
query_string = urlparts[1] if len(urlparts) == 2 else ''
if _local:
    print("QUERY STRING => {}".format(query_string))

if _local:
    request_body = open("""D:\\aosis\\2017_stelia\\data\\02a247ff-84b5-4dc6-9a17-502ec9c831e1.xml""", "r").readline()
elif http_method.lower() == 'post':
    request_body = open(env[_AZURE_FUNCTION_HTTP_INPUT_ENV_NAME], "r").read()

if _verbosity > 0:
    print("REQUEST BODY => {}".format(request_body))
# _ add root attribute plus xml header
xmlstr = '''<?xml version="1.0"?><root>''' + request_body + '''</root>'''
xmlstr = xmlstr.replace(''' xmlns="http://Microsoft.LobServices.Sap/2007/03/Types/Rfc/"''', '')
xmlstr = xmlstr.replace(''' xmlns="http://Microsoft.LobServices.Sap/2007/03/Rfc/"''', '')
#mytree = ET.fromstring(xmlstr).iter(tag='BAPISCUDAT')
mytree = ET.fromstring(xmlstr).getchildren()[0].getchildren()[0].getchildren()
if _verbosity > 0:
    print("mytree => {}".format(mytree))
res_body = make_dict_from_elemlist(mytree)
if _verbosity > 0:
    print res_body

write_http_response(200, res_body)
