##
## Graph Structure for Nim
## :author: souchan_t@hotmail.com
## 
##
import tables
import strformat
import heapqueue

type
  Edge* = ref object of RootObj ## Edge between Nodes
    source:Node
    target:Node
    label:string
    passed:int
    weight:float

  Node* = ref object of RootObj ## Node of Graph
    id:string
    label:string
    count:int
    out_edges:OrderedTable[string,Edge] #TODO Should change to be faster
    in_edges:OrderedTable[string,Edge]  #TODO Should change to be faster

  NodeCmp = tuple[node:Node,priority:float] ## for Comparing

  Network* = ref object of RootObj ## Graph
    name:string
    nodes:OrderedTable[string,Node]

  GraphException = ref object of Exception

  AdjMatrix = seq[seq[int]]
  AdjMatrix_W= seq[seq[float]]

#---------------------------------------------------------------------------
# Edge Procedures
#---------------------------------------------------------------------------
proc newEdge*(source,target:Node,label:string="",weight:float=0.0):Edge=
  ##
  ## create a new Edge
  ##
  result = new Edge
  result.source = source
  result.target = target
  result.label = label
  result.passed = 0
  result.weight = weight

proc `$`*(self:Edge):string=
  result = fmt"Edge {self.source.label} -> {self.target.label} "
  result.add fmt"weight:{self.weight},passed:{self.passed})"

#proc isAdjacent*(self:Edge,target:Edge):bool=
#  if self.source.getEdgeIndex(target.source) == -1 and
#    self.source.getEdgeIndex(target.target) == -1 and
#    target.target.getEdgeIndex(self.source) == -1 and
#    target.target.getEdgeIndex(self.target) == -1:
#    return false
#  else:
#    return true
#---------------------------------------------------------------------------
# NodeCmp Procedures
#---------------------------------------------------------------------------
proc `<`*(self,other:NodeCmp):bool=
  ##
  ## compare Node by weight,for push to HeapQueue.
  ##
  self.priority < other.priority
  
#------------------------------------------------------------------------------
# Node Procedures
#------------------------------------------------------------------------------
proc init*(self:Node,id:string,label:string="")=
  ##
  ## Node object Initalizer
  ##
  self.id = id
  if label=="":
    self.label = id
  else:
    self.label = label
  self.count = 0
  self.out_edges = initOrderedTable[string,Edge]()
  self.in_edges  = initOrderedTable[string,Edge]()

proc newNode*(id:string,label:string=""):Node=
  ##
  ## create a new Node with initilize.
  ##
  result = new Node
  result.init(id,label)

proc inDegree*(self:Node):int=
  ##
  ## in degree of Node.
  ##
  len(self.in_edges)

proc outDegree*(self:Node):int=
  ##
  ## out degree of Node
  ##
  len(self.out_edges)

proc degree*(self:Node):int=
  ##
  ## degree of Node.sum of out degree and in degree
  ##
  self.inDegree + self.outDegree

proc `$`*(self:Node):string=
  ##
  ## Node object to strings
  ##
  fmt"Node id:{self.id},label:{self.label},degree:{self.out_degree}"

proc getOutEdge*(self:Node,target:Node):Edge=
  ##
  ## return a edge.if edge was not found,proc returns nil.
  ##
  if self.out_edges.hasKey(target.id):
    return self.out_edges[target.id]
  else:
    return nil

proc getInEdge*(self:Node,target:Node):Edge=
  ##
  ## return a edge.if edge was not found,proc returns nil.
  ##
  if self.in_edges.hasKey(target.id):
    return self.in_edges[target.id]
  else:
    return nil

proc connect*(self:Node,target:Node,weight=0.0):Node{.discardable.}=
  ##
  ## This proc is that conect a Node to Node.
  ## If the Edge does not exist,create a new Edge.
  ## Count of pass through the edge,`passed` is counted up
  ##
  
  var oedge = self.getOutEdge(target)
  var iedge = target.getInEdge(self)
  if isNil(oedge):
    oedge = newEdge(self,target,weight=weight)
    self.out_edges[target.id] = oedge

  oedge.passed += 1
  self.count += 1

  if isNil(iedge):
    iedge = newEdge(target,self,weight=weight)
    target.in_edges[self.id] = iedge
    
  iedge.passed += 1

  return target

proc `->`*(self:Node,target:Node):Node {.discardable.}=
  ##
  ## This operetor is that conect a Node to Node.
  ## If the Edge does not exist,create a new Edge.
  ## Count of pass through the edge,`passed` is counted up
  ##
  self.connect(target)

proc `<-`*(self:Node,target:Node):Node {.discardable.}=
  ##
  ## connect a Node to Node
  ##
  target -> self
  target

proc `<->`*(self:Node,target:Node):Node {.discardable.}=
  ##
  ## connect a Node to Node,each other.
  ##
  self -> target -> self

proc `--`*(self:Node,target:Node):Edge {.discardable.}=
  ##
  ## return outedge.
  ##
  self.getOutEdge(target)

proc delOutEdge*(self:Node,target:Node)=
  ##
  ## delete a outedge of self and inedge of target
  ##
  self.out_edges.del(target.id)
  target.in_edges.del(self.id)

proc delInEdge*(self:Node,target:Node)=
  ##
  ## delete a inedge of self and outede of target
  ##
  self.in_edges.del(target.id)
  target.out_edges.del(self.id)

iterator depthFirstSearch*(self:Node):Node=
  ##
  ## Depth First Search Iterator(no recursive)
  ##
  var stack:seq[Node] = @[]
  var visited:Table[string,bool] = initTable[string,bool]()
  visited[self.id] = true
  stack.add(self)

  while stack.len() != 0:
    var node = stack.pop()
    yield node
    for i,e in node.out_edges:
      if visited.hasKey(e.target.id) == false:
        visited[e.target.id] = true
        stack.add(e.target)

iterator breadthFirstSearch*(self:Node):Node=
  ##
  ## Breadth First Search Iterator
  ##
   
  var visited:Table[string,bool] = initTable[string,bool]()
  visited[self.id] = true
  var queue:HeapQueue[NodeCmp] = newHeapQueue[NodeCmp]()
  queue.push((self,0.0))
  while queue.len() != 0:
    var node = queue.pop()[0]

    yield node
    for i,e in node.out_edges:
      if visited.hasKey(e.target.id) == false:
        visited[e.target.id] = true
        queue.push((e.target,e.weight))
        

#---------------------------------------------------------------------------
# Network(Graph) Procedures
#---------------------------------------------------------------------------
proc newNetwork*(name:string="NoName"):Network=
  ##
  ## create a new Network.
  ##

  result= new Network
  result.nodes = initOrderedTable[string,Node]()
  result.name = name


proc getNode*(self:Network,id:string):Node=
  ##
  ## get a node by id. if id does not exist,proc returns nil
  ##
  if self.nodes.hasKey(id):
    return self.nodes[id]
  else:
    return nil

proc addNode*(self:Network,node:Node)=
  ##
  ## add a node to the Network.
  ##
  self.nodes[node.id] = node

proc addNode*(self:Network,nodes:openarray[Node])=
  ##
  ## add nodes to the Network
  ##
  for n in nodes:
    self.addNode(n)

proc addNode*(self:Network,node_ids:openarray[string])=
  ##
  ## add nodes to the Network,by string of id
  ##
  for id in node_ids:
    self.addNode(newNode(id))

proc `[]`*(self:Network,id:string):Node=
  ##
  ## get a node by id.if id does not exist,operator returns nil.
  ##
  self.getNode(id)

proc `[]=`*(self:Network,id:string,node:Node):Node{.discardable.}=
  ##
  ## add a node to Network.
  ##
  self.addNode(node)
  return node

proc `[]=`*(self:Network,id:string,label:string):Node{.discardable.}=
  ##
  ## add a node to Network by string
  ##
  var node = newNode(id=id,label=label)
  self.addNode(node)
  return node

proc delNode*(self:Network,id:string)=
  ##
  ## delete a node from Network.
  ## all edges that connet with node,is deleted.
  ##
  let n = self[id]
  if isNil(n):
    return

  # delete all edges that connect with node
  for id,oedge in n.out_edges:
    n.delOutEdge(oedge.target)
  for id,iedge in n.in_edges:
    n.delInEdge(iedge.target)

  # deletea the node
  self.nodes.del(id)

proc addNodeAndConnect*(self:Network,source:string,target:string,
  directed=false,weight=0.0,selfconnect:bool=false)=
  ##
  ## The proc adds pair nodes to the Network.
  ## And source node connect to target node.
  ## if Network is undirected,connet to nodes each other
  ## [directed]   A -> B
  ## [undirected] A -> B , B -> A
  ##
  if not(selfconnect) and source == target:
    return

  var s_node:Node = self[source]
  var t_node:Node = self[target]

  if isNil(s_node):
    s_node = newNode(source,source)
    self.addNode(s_node)

  if isNil(t_node):
    t_node = newNode(target,target)
    self.addNode(t_node)
  
  if directed:
    discard s_node -> t_node
  else:
    discard s_node <-> t_node

proc addNodeAndConnect*(self:Network,tags:openarray[string],
  directed=false,weight=0.0,selfconnect:bool=false)=
  #[
  # The proc adds nodes to the Network.
  # `push(network,["A","B","C"])` means
  #   [directed]   A -> B, A -> C, B -> C
  #   [undirected] A <-> B, A <-> C ,B <-> C
  ]#
  for i in 0..high(tags):
    for j in i..high(tags):
      self.addNodeAndConnect(tags[i],tags[j],directed,weight,selfconnect)

iterator each_edge*(self:Network):Edge=
  ## Iterator of out edges.
  for nid,node in self.nodes:
    for eid,edge in node.out_edges:
      yield edge

proc edges*(self:Network):seq[Edge]=
  result=newSeq[Edge]()
  for e in self.each_edge:
    result.add(e)

iterator each_node*(self:Network):Node=
  for id,n in self.nodes:
    yield n

proc getNodeIds*(self:Network):seq[string]=
  result = newSeq[string](self.nodes.len)

  var i = 0
  for k in self.nodes.keys:
    result[i] = k
    i += 1
proc getAdjMatrix*(self:Network):AdjMatrix=
  ## create a adjacency matrix from network.
  ## a value that node does not connect others is `0`.
  ##
  # init matrix
  let n = len(self.nodes)
  var matrix = newSeq[seq[int]](n)

  var ids = newTable[string,int]()
  var i=0
  for id,node in self.nodes:
    matrix[i] = newSeq[int](n)
    ids[node.id] = i
    i += 1
  
  #plot to matrix
  for e in self.edges:
    matrix[ids[e.source.id]][ids[e.target.id]] = 1

  return matrix

proc getAdjMatrix_weighted*(self:Network):AdjMatrix_W=
  ## create a weigthted adjacency matrix from Network.
  ## a value that node does not connect others is `Inf`.
  
  # init matrix
  let n = len(self.nodes)
  var matrix = newSeq[seq[float]](n)

  # id - index table
  var ids = newTable[string,int]()
  var i=0
  for id,node in self.nodes:
    matrix[i] = newSeq[float](n)
    for col in 0..<n:
      matrix[i][col] = Inf #init a weight to infinity

    ids[node.id] = i # id-index
    i += 1
  
  #edge weight into the matrix
  for e in self.edges:
    matrix[ids[e.source.id]][ids[e.target.id]] = e.weight

  return matrix

proc newNetwork*(matrix:AdjMatrix,
                 nodeNames:openarray[string],
                 name="noname"):Network=
  ## create a new Network from adjacency matrix.
  ## `matrix` param expect a `seq[seq[int]]` type.
  ## `nodeName` param expect a `seq[string]` type.

  result = newNetwork(name=name)
  result.addNode(nodeNames)

  let N = nodeNames.len
  for i in 0..<N:
    for j in 0..<N:
      if matrix[i][j] == 1:
        result[nodeNames[i]] -> result[nodeNames[j]]

proc newNetwork*(matrix:AdjMatrix_W,
                 nodeNames:openarray[string],
                 name="noname"):Network=
  ## create a new Netowork from weigthted adjacency matrix.
  ## `matrix` param expect a `seq[seq[float]]` type
  ## `nodeName` param expect a seq[string]` type

  result = newNetwork(name=name)
  result.addNode(nodeNames)

  let N = nodeNames.len
  for i in 0..<N:
    for j in 0..<N:
      if matrix[i][j] != Inf:
        result[nodeNames[i]] -> result[nodeNames[j]]
        (result[nodeNames[i]] -- result[nodeNames[j]]).weight = matrix[i][j]


proc degrees*(self:Network):seq[int]=
  ## returns seq of degree of Noeds
  result = newSeq[int](self.nodes.len)
  var i = 0
  for _,n in self.nodes:
    result[i] = n.degree
    i += 1

proc centralityDegree*(self:Network):seq[float]=
  ## returns seq of degree centrality.
  ## this proc calculate a normalized centrality degrees
  ## `(out_degree + indegree) / (2 * N)` #TODO out_degree / N ..?
  let N = self.nodes.len
  result = newSeq[float](N)
  var i = 0
  for _,n in self.nodes:
    result[i] = float(n.degree) / float(2 * N)
    i += 1

proc copy*(self:Network):Network=
  result = newNetwork(name=self.name)
  
  # copy nodes
  for id,n in self.nodes:
    var node = newNode(id=n.id,label=n.label)

    # copy out edges
    for t_id,e in n.out_edges:
      var edge = new Edge
      edge.source = node
      edge.target = e.target
      edge.label = e.label
      edge.weight = e.weight
      edge.passed = e.passed
      node.out_edges[t_id] = edge
    # copy in edges
    for s_id,e in n.in_edges:
      var edge = new Edge
      edge.source = e.target
      edge.target = node
      edge.label = e.label
      edge.weight = e.weight
      edge.passed = e.passed
      node.in_edges[s_id] = edge

    result.addNode(node)

proc print*(self:Network)=
  #[
  # echo the Network
  ]#
  for k,v in self.nodes:
    echo fmt"Node:{v.label}(degree:{v.out_degree})"
    for i,e in v.out_edges:
      echo "\t",fmt"{v.label} ---> {e.passed} ---> {e.target.label}"

proc toDOT*(self:Network):string=
  #[
  # convert Network to strings of DOT file format
  ]#
  result="""
digraph graph_name {
  graph [
    charset = "utf8";
    bgcolor = "#FFFFFF",
    fontcolor = "#000000",
    fontsize = "9",
    layout = "fdp",
  ]
"""
  
  for id,node in self.nodes:
    result.add fmt"{node.label} [shape=circle];"
    result.add "\n"

  for id,node in self.nodes:
    for t,edge in node.out_edges:
      result.add fmt"{node.label} -> {edge.target.label} [arrowhead = vee,weight={$edge.passed}];"
      result.add "\n"

  result.add "}"


when isMainModule:
  let net = newNetwork()
  let nodenames = ["A","B","C","D","E","F"]
  net.addNode(nodenames)
 
  net["A"] <-> net["B"]
  net["B"] <-> net["C"]
  net["A"] <-> net["D"]
  net["B"] <-> net["E"]
  (net["B"] -- net["E"]).weight = 0.2
  (net["B"] -- net["C"]).weight = 0.1

  for n in net["A"].breadthFirstSearch:
    echo n

  var m = net.getAdjMatrix()
  let net2 = newNetwork(m,nodenames)
  var net3 = net2.copy

  net.print

  echo net.getNodeIds

