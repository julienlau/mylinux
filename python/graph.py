import networkx as nx
import scipy.spatial

class Toto:
    @staticmethod
    def nodes_to_1d_sorted_graph(graph, calculate_distance=True):
        edges = list(graph.edges)
        if len(edges) > 0:
            graph.remove_edges_from(list(graph.edges))
        d = {}
        for node in graph.nodes.data():
            key = node[0]
            d[key] = node[1]['pos'][0]
        d = dict(sorted(d.items(), key=lambda item: item[1]))

        sorted_nodes = list(d.keys())
        for n in range(len(sorted_nodes)-1):
            graph.add_edge(sorted_nodes[n], sorted_nodes[n+1])
        # At least 2 edges per node
        graph.add_edge(sorted_nodes[0], sorted_nodes[2])
        graph.add_edge(sorted_nodes[len(sorted_nodes)-3], sorted_nodes[len(sorted_nodes)-1])

        # calculate Euclidian length of edges and write it as edges attribute
        if calculate_distance:
            edges = graph.edges()
            for edge in edges:
                node_1 = graph.nodes[edge[0]]
                node_2 = graph.nodes[edge[1]]
                dist = sqrt((node_1['pos'][0] - node_2['pos'][0]) ** 2)
                graph.edges[edge[0], edge[1]]['length'] = dist
        return graph

    @staticmethod
    def nodes_to_delaunay_graph(point_graph, calculate_distance=True):
        '''
        Creates a graph based on Delaney triangulation

        @param point_graph: either a graph made by read_shp() from another NetworkX's point graph
        @param calculate_distance: whether length of edges should be calculated
        @return - a graph made from a Delauney triangulation

        @Copyright notice: this code is an improved (by Yury V. Ryabov, 2014, riabovvv@gmail.com) version of
                        Tom's code taken from this discussion
                        https://groups.google.com/forum/#!topic/networkx-discuss/D7fMmuzVBAw
        '''
        delaunay = scipy.spatial.Delaunay(np.array(list(dict(point_graph.nodes.data('pos')).values())))
        edges = set()
        # for each Delaunay triangle
        for n in range(delaunay.nsimplex):
            # for each edge of the triangle
            # sort the vertices
            # (sorting avoids duplicated edges being added to the set)
            # and add to the edges set
            edge = sorted([delaunay.vertices[n, 0], delaunay.vertices[n, 1]])
            edges.add((edge[0], edge[1]))
            edge = sorted([delaunay.vertices[n, 0], delaunay.vertices[n, 2]])
            edges.add((edge[0], edge[1]))
            edge = sorted([delaunay.vertices[n, 1], delaunay.vertices[n, 2]])
            edges.add((edge[0], edge[1]))

        # make a graph based on the Delaunay triangulation edges
        graph = nx.Graph(list(edges))

        # add nodes attributes to the TIN graph from the original points
        original_attr = list(point_graph.nodes(data=True))[0][1].keys()
        for attribute in original_attr:
            a = nx.get_node_attributes(point_graph, attribute)
            b = {i:v for i,(k,v) in enumerate(a.items(), 0)}
            nx.set_node_attributes(graph, b, attribute)

        # calculate Euclidian length of edges and write it as edges attribute
        if calculate_distance:
            edges = graph.edges()
            for edge in edges:
                node_1 = graph.nodes[edge[0]]
                node_2 = graph.nodes[edge[1]]
                dist = sqrt(sum([(a - b) ** 2 for a, b in zip(node_1['pos'], node_2['pos'])]))
                graph.edges[edge[0], edge[1]]['length'] = dist

        # retrieve key name from the original points
        raw = list(graph.nodes.keys())
        labeled = list(point_graph.nodes.keys())
        mapping = dict(zip(raw, labeled))
        logger.debug(mapping)
        graph = nx.relabel_nodes(graph, mapping, copy=False)
        return graph
