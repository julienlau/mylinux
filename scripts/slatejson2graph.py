# Python 2 and 3: 
from __future__ import print_function
from __future__ import unicode_literals
#
import argparse
import json
from pprint import pprint
import networkx as nx
from networkx.drawing.nx_agraph import to_agraph
import hashlib
import unittest
import os

try:
    import pygraphviz
    from networkx.drawing.nx_agraph import write_dot
    print("using package pygraphviz")
except ImportError:
    try:
        import pydot
        from networkx.drawing.nx_pydot import write_dot
        print("using package pydot")
    except ImportError:
        print()
        print("Both pygraphviz and pydot were not found ")
        print("see  https://networkx.github.io/documentation/latest/reference/drawing.html")
        print()
        raise


def json2graph_inputs():
    """
    routine that gets user inputs
    """
    parser = argparse.ArgumentParser(description="""Convert a json dictionary like structure to a graph dot file and png image.
    The input file is not exactly the export of a slate to a json.
    First you should extract the events of your slate project using the command below:\n
    jq '.document.model.events | to_entries |map({"eventName" : .key, "actionName" : [.value[].actionName]}) ' ${slatejson} > ${slatejson}.events.json""")
    parser.add_argument("-i","--input", default='file.json', help="name of the json input file to parse and convert")
    parser.add_argument("-o","--output", default='file.png', help="name of the dot output file")
    args = parser.parse_args()
    infile = args.input
    outfile = args.output
    if not os.path.isfile(infile):
        parser.print_help()
        raise Exception("Input file not specified")
    json2graph(infile, outfile)
    return


def json2graph(infile, outfile):
    """
    The input file is not exactly the export of a slate to a json.
    First you should extract the events of your slate project using the command below:
    jq '.document.model.events | to_entries |map({"eventName" : .key, "actionName" : [.value[].actionName]}) ' ${slatejs} > ${slatejs}.events.json
    python slatejson2graph.py -i ${slatejs}.events.json -o ${slatejs}.events.png
    """
    json_data=open(infile).read()
    data = json.loads(json_data)
    # Create empty graph
    thegraph = nx.DiGraph()

    # Add nodes
    for i in range(len(data)):
        nodesrc = data[i]['eventName']
        thegraph.add_node(nodesrc, color=get_node_color(nodesrc), label=nodesrc)
        for nodedst in data[i]['actionName']:
            thegraph.add_node(nodedst, color=get_node_color(nodedst), label=nodedst)
    allnode = thegraph.nodes().keys()

    # Add edges for each events in Slate app
    for i in range(len(data)):
        nodesrc = data[i]['eventName']
        # Add properly listed links in Slate Json
        for nodedst in data[i]['actionName']:
            thegraph.add_edge(nodesrc, nodedst, color=get_edge_color(nodesrc, nodedst))

        # Force Slate implicit events to appear in the graph,
        # These implicit links only appear if the nodes present in the Slate project
        # x.run implies x.ran
        # x.run implies x.success or x.failure
        # x.set implies x.changed
        l_implicit_link = []
        l_implicit_link.append((".set", ".changed"))
        l_implicit_link.append((".run", ".ran")) # for a function
        l_implicit_link.append((".run", ".success")) # for a query
        l_implicit_link.append((".run", ".failure")) # for a query

        # Force implicit for all source nodes properly listed in Slate Json
        for pair in l_implicit_link:
            lensrc = len(pair[0])
            nodedst2 = nodesrc[:-lensrc] + pair[1]
            if nodedst2 in allnode and nodesrc[-4:] == pair[0]:
                thegraph.add_edge(nodesrc, nodedst2, color=get_edge_color(nodesrc, nodedst2))

        # Force implicit for all destination nodes properly listed in Slate Json
        for nodedst in data[i]['actionName']:
            for pair in l_implicit_link:
                lensrc = len(pair[0])
                nodedst2 = nodedst[:-lensrc] + pair[1]
                if nodedst2 in allnode and nodedst[-4:] == pair[0]:
                    thegraph.add_edge(nodedst, nodedst2, color=get_edge_color(nodedst, nodedst2))

    # set defaults
    thegraph.graph['graph'] = {'rankdir':'TD', 'penwidth': 2.0}
    print("There are %d nodes and %d edges"% (len(thegraph.nodes().keys()), len(thegraph.edges().keys())))

    agraph = to_agraph(thegraph)
    agraph.layout('dot')

    # write outputs
    agraph.draw(outfile)
    print("output image file written %s"% outfile)
    write_dot(thegraph, outfile[:-4]+".dot")
    print("output graph file written %s"% outfile[:-4]+".dot")
    print("If you need a manual edit of the dot file you can generate the image afterward with :")
    print("    dot -Grankdir=\"TD\" -Tpng "+outfile[:-4]+".dot >"+outfile[:-4]+".png")

    return


def string2numeric_hash(text):
    return int(hashlib.md5(text).hexdigest()[:8], 16)


def get_edge_color(src, dst):
    """
    define some custom colors for an edge based on its name and a dictionary of predefined colors
    """
    colorlist = ['gold', 'salmon', 'steelblue', 'firebrick', 'orchid', 'sienna', 'brown', \
                 'blueviolet', 'blue', 'indigo', 'yellow', 'pink', 'violet', 'green', 'darkgreen', \
                 'greenyellow', 'palegreen', 'magenta', 'orange', 'cyan', 'seagreen', 'gray', \
                 'mediumturquoise', 'red']
    return colorlist[string2numeric_hash(src[:1] + '+' + dst[:1])%(len(colorlist)-1)]


def get_node_color(name):
    """
    define some custom colors for a node based on its name and a dictionary of predefined colors
    """
    colordict = {'default': 'black', 'w_': 'blue', 'v_': 'red', 'q_': 'green'}
    if name[:2] in ['w_', 'q_', 'v_']:
        color = colordict[name[:2]]
    else:
        color = colordict['default']
    return color

class MyTest(unittest.TestCase):
    def test(self):
        self.assertEqual(string2numeric_hash("v_toto.run+f_titi.ran"), 4076835383)
        self.assertEqual(get_node_color("v_toto.run"), "red")
        self.assertEqual(get_node_color("toto.run"),   "black")
        self.assertEqual(get_node_color("w_toto.run"), "blue")
        self.assertEqual(get_node_color("q_toto.run"), "green")

if __name__ == "__main__":
    json2graph_inputs()
