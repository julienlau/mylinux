# -*- coding: utf-8 -*-

"""
Azure Functions HTTP Trigger Python Sample
- Get and dump HTTPS request info that the trigger receives

Special Thanks to anthonyeden for great Python HTTP example:
https://github.com/anthonyeden/Azure-Functions-Python-HTTP-Example
"""

import datetime
import json
import logging
import os
import random
import unittest

logger = logging.getLogger('azf_fakecsv')
logger.setLevel(logging.getLevelName('DEBUG'))
# logger.setLevel(logging.getLevelName('INFO'))

_AZURE_FUNCTION_DEFAULT_METHOD = "GET"
_AZURE_FUNCTION_HTTP_INPUT_ENV_NAME = "req"
_AZURE_FUNCTION_HTTP_OUTPUT_ENV_NAME = "res"
_REQ_PREFIX = "REQ_"
_local = False
_timenow = datetime.datetime.utcnow().strftime("%Y-%m-%d T %H:%M:%S")

def getParams(url):
    params = url.split("?")
    if len(params) < 2:
        return {}
    params = params[1]
    params = params.split('=')
    pairs = zip(params[0::2], params[1::2])
    answer = dict((k,v) for k,v in pairs)
    return answer


def write_http_response(status, body_pysty):
    myjson = json.dumps(body_pysty)
    logger.debug(myjson)
    return_dict = {
        "status": status,
        "body": myjson,
        "headers": {
            "Content-Type": "application/json"
        }
    }
    output = open(os.environ[_AZURE_FUNCTION_HTTP_OUTPUT_ENV_NAME], 'w')
    output.write(json.dumps(return_dict))


def get_fake_data(nrow, usr_client=None, usr_type_produit=None):
    pk_check = set()
    arr_fake_data = []
    for _ in range(nrow):
        row, pk_check = get_one_fake_data(pk_check)
        if row is not None:
            arr_fake_data.append(row)
    logger.debug("list of PK {}".format(pk_check))
    return arr_fake_data


def get_one_fake_data(pk_check, usr_client=None, usr_type_produit=None):
    nRetry = 10
    # init
    datadico = dict(time=None, client=None, type_produit=None, groupe=None, referent=None, lat=None, long=None,
                    quantite_produit=None, tarif_unitaire=None, uo_reel_engrais=None, uo_potentiel_engrais=None,
                    saturation_engrais=None, uo_reel_phyto=None, uo_potentiel_phyto=None, saturation_phyto=None,
                    uo_reel_semence=None, uo_potentiel_semence=None)
    # Primary key check
    trial = 0
    pk, client, type_produit = None, None, None
    while trial < nRetry and client is None:
        if usr_client is None:
            client = random.randint(1, 10000)
        else:
            client = usr_client
        if usr_type_produit is None:
            type_produit = random.randint(1, 3)
        else:
            type_produit = usr_type_produit
        pk = int(str(type_produit).zfill(3) + str(client).zfill(9))
        if pk is not None and pk not in pk_check:
            pass
        else:
            client, type_produit = None, None
        trial += 1
    if pk is not None and pk not in pk_check:
        datadico["client"] = client
        datadico["type_produit"] = type_produit
        datadico["time"] = _timenow
        datadico["groupe"] = random.randint(1, 100)
        datadico["referent"] = random.randint(1, 10)
        datadico["lat"] = 46.269 + (random.random() - 0.5) * 6.0
        datadico["long"] = 2.5765 + (random.random() - 0.5) * 6.0
        datadico["quantite_produit"] = random.random() * 10.0 + abs(datadico["lat"] - 49.269) * 100.0
        datadico["tarif_unitaire"] = random.random() + abs(datadico["long"] - 5.5765) * 100.0
        datadico["uo_potentiel_engrais"] = datadico["tarif_unitaire"] * datadico["quantite_produit"]
        datadico["uo_reel_engrais"] = min(datadico["uo_potentiel_engrais"],
                                          datadico["uo_potentiel_engrais"] * (1.0 - abs(datadico["groupe"] - 50)/50 - random.uniform(0.0, 0.05)))
        datadico["saturation_engrais"] = datadico["uo_reel_engrais"] / datadico["uo_potentiel_engrais"]
        datadico["uo_potentiel_phyto"] = datadico["tarif_unitaire"] * 10 + datadico["quantite_produit"]
        datadico["uo_reel_phyto"] = min(datadico["uo_potentiel_phyto"],
                                        datadico["uo_potentiel_phyto"] * (1.0 - abs(datadico["referent"] - 5)/5 - random.uniform(0.0, 0.05)))
        datadico["saturation_phyto"] = datadico["uo_reel_phyto"] / datadico["uo_potentiel_phyto"]
        datadico["uo_potentiel_semence"] = datadico["quantite_produit"] * \
                                           (1.0 + abs(datadico["referent"] - 5)/5 * random.uniform(0.8, 1.0))
        datadico["uo_reel_semence"] = min(datadico["uo_potentiel_semence"],
                                          datadico["uo_potentiel_semence"] * (1.0 - abs(datadico["type_produit"] - 3)/3 - random.uniform(0.0, 0.05)))
        datadico["saturation_semence"] = datadico["uo_reel_semence"] / datadico["uo_potentiel_semence"]
    else:
        logger.debug("PK duplicate : skip one")
        datadico = None
    pk_check.add(pk)
    #print("lat:{:2.3f}; long:{:2.3f}".format(datadico["lat"], datadico["long"]))
    return datadico, pk_check


############################ MAIN #############################
def azf_fakedata():
    """
    main of the azure function app
    at each GET request
    :return:
    as body of HTTP response an array of element to be inserted in DB
    """
    env = os.environ
    request_body = None
    nbrow = 1000

    # Get HTTP METHOD
    http_method = env['REQ_METHOD'] if 'REQ_METHOD' in env else _AZURE_FUNCTION_DEFAULT_METHOD
    print("HTTP METHOD => {}".format(http_method))

    # Get QUERY STRING
    req_url = env['REQ_HEADERS_X-ORIGINAL-URL'] if 'REQ_HEADERS_X-ORIGINAL-URL' in env else ''
    urlparts = req_url.split('?')
    query_string = urlparts[1] if len(urlparts) == 2 else ''
    params = getParams(req_url)
    if "nbrow" in params.keys():
        usr_nbrow = int(params["nbrow"])
        if usr_nbrow > 0:
            nbrow = usr_nbrow
    print("QUERY STRING => {}".format(query_string))
    logger.debug("QUERY STRING => {}".format(query_string))

    if nbrow > 100000:
        nbrow = 100000

    if _local:
        nbrow = 1000
    elif http_method.lower() == 'post':
        request_body = open(env[_AZURE_FUNCTION_HTTP_INPUT_ENV_NAME], "r").read()
    print("REQUEST BODY => {}".format(request_body))

    res_body = get_fake_data(nbrow)

    print("nb rows : asked {:d} ; given {:d}".format(nbrow, len(res_body)))
    if _local:
        import csv
        with open("D:\\travail\\data\\aosis\\2018_euralis\\data.csv", 'w', newline="") as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=res_body[0].keys())
            writer.writeheader()
            for data in res_body:
                writer.writerow(data)
        del writer
        csvfile.close()
        print("RESPONSE BODY => {}".format(res_body))
    else:
        print("RESPONSE BODY => {}".format(res_body[0]))
        write_http_response(200, res_body)


class MyTest(unittest.TestCase):
    def test(self):
        # when generating a new row without constraint it should not be None
        datadico, pk_check = get_one_fake_data(set())
        self.assertIsNotNone(datadico["client"])
        # when generating a new row with constraint that is passing it should not be None
        datadico, pk_check = get_one_fake_data(set(), usr_client=12345, usr_type_produit=3)
        self.assertIsNotNone(datadico["client"])
        # when generating a new row with constraint failing it should be None
        pk = int(str(3).zfill(3) + str(12345).zfill(9))
        datadico, pk_check = get_one_fake_data({pk}, usr_client=12345, usr_type_produit=3)
        self.assertIsNone(datadico)
        # when asking for 9 rows without constraint we should get 9 rows
        arr = get_fake_data(9)
        self.assertEqual(9, len(arr))


if __name__ == "__main__":
    azf_fakedata()
