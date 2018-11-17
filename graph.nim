import tables
import strformat
from algorithm import binarySearch,sort,sorted

type
  Edge* = ref object
    source:Node
    target:Node
    label:string
    passed:int
    weight:float


  Node* = ref object
    id:string
    label:string
    out_edges:OrderedTable[string,Edge]
    in_edges:OrderedTable[string,Edge]

  Network* = ref object
    name:string
    directed:bool
    nodes:Table[string,Node]


# Edge ------------------------------------------------------------------------
proc newEdge*(target:Node,label:string="",weight:float=0.0):Edge=
  var e = new Edge
  e.target = target
  e.label = label
  e.passed = 0
  e.weight = weight
  return e

#proc isAdjacent*(self:Edge,target:Edge):bool=
#  if self.source.getEdgeIndex(target.source) == -1 and
#    self.source.getEdgeIndex(target.target) == -1 and
#    target.target.getEdgeIndex(self.source) == -1 and
#    target.target.getEdgeIndex(self.target) == -1:
#    return false
#  else:
#    return true

# Node ------------------------------------------------------------------------
proc init*(self:Node,id:string,label:string="")=
  #[
  # Node object Initalizer
  ]#
  self.id = id
  if label=="":
    self.label = id
  else:
    self.label = label
  self.out_edges = initOrderedTable[string,Edge]()
  self.in_edges  = initOrderedTable[string,Edge]()

proc newNode*(id:string,label:string=""):Node=
  #[
  # create a new Node with initilize.
  ]#
  var n = new Node
  n.init(id,label)
  return n

proc getOutEdge*(self:Node,target:Node):Edge=
  #[
  # return a edge.if edge was not found,proc returns nil.
  ]#
  if self.out_edges.hasKey(target.id):
    return self.out_edges[target.id]
  else:
    return nil
proc getInEdge*(self:Node,target:Node):Edge=
  #[
  # return a edge.if edge was not found,proc returns nil.
  ]#
  if self.in_edges.hasKey(target.id):
    return self.in_edges[target.id]
  else:
    return nil

proc `->`*(self:Node,target:Node):Node {.discardable.}=
  #[
  # This operetor is that conect a Node to Node.
  # If the Edge does not exist,create a new Edge.
  # Count of pass through the edge,`passed` is counted up
  ]#

  var oedge = self.getOutEdge(target)
  var iedge = target.getInEdge(self)

  if isNil(oedge):
    oedge = newEdge(target,weight=1.0)
    self.out_edges.add(target.id,oedge)
  
  oedge.passed += 1

  if isNil(iedge):
    iedge = newEdge(self,weight=1.0)
    target.in_edges.add(self.id,iedge)
    
  iedge.passed += 1

  return target

proc `<-`*(self:Node,target:Node):Node {.discardable.}=
  #[
  # connect a Node to Node
  ]#
  return target -> self

proc `<->`*(self:Node,target:Node):Node {.discardable.}=
  #[
  # connect a Node to Node,each other.
  ]#
  return self -> target -> self

proc delOutEdge*(self:Node,target:Node)=
  #[
  # delete a outedge of self and inedge of target
  ]#
  self.out_edges.del(target.id)
  target.in_edges.del(self.id)
proc delInEdge*(self:Node,target:Node)=
  #[
  # delete a inedge of self and outede of target
  ]#
  self.in_edges.del(target.id)
  target.out_edges.del(self.id)

proc degree*(self:Node):int=
  return len(self.out_edges) + len(self.in_edges)
  
# Network ---------------------------------------------------------------------
proc newNetwork*(name:string="NoName",directed=true):Network=
  #[
  # create a new Network.
  ]#

  var net = new Network
  net.nodes = initTable[string,Node]()
  net.name = name
  net.directed = directed
  return net

proc getNode*(self:Network,id:string):Node=
  #[
  # get a node by id. if id does not exist,proc returns nil
  ]#
  if self.nodes.hasKey(id):
    return self.nodes[id]
  else:
    return nil

proc addNode*(self:Network,node:Node)=
  #[
  # add a node into Network.
  ]#
  self.nodes.add(node.id,node)

proc `[]`*(self:Network,id:string):Node=
  #[
  # get a node by id.if id does not exist,operator returns nil.
  ]#
  return self.getNode(id)

proc `[]=`*(self:Network,id:string,node:Node):Node=
  #[
  # add a node into Network.
  ]#
  self.addNode(node)
  return node


proc delNode*(self:Network,id:string)=
  #[
  # delete a node from Network.
  # all edges that connet with node,is deleted.
  ]#
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


proc push*(self:Network,source:string,target:string,weight=1.0,selfconnect:bool=false)=

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
  
  if self.directed:
    discard s_node -> t_node
  else:
    discard s_node <-> t_node

proc print*(self:Network)=
  #[
  # echo the Network
  ]#
  for k,v in self.nodes:
    echo fmt"Node:{v.label}(degree:{v.degree})"
    for i,e in v.out_edges:
      echo "\t",fmt"{v.label} ---> {e.passed} ---> {e.target.label}"

proc toDOT*(self:Network):string=
  #[
  # convert Network to strings of DOT file format
  ]#
  var buff="""
digraph graph_name {
  graph [
    charset = "utf8";
    bgcolor = "#FFFFFF",
    fontcolor = "#000000",
    fontsize = "9",
    layout = "circo",
  ]
"""
  
  for id,node in self.nodes:
    buff.add fmt"{node.label} [shape=circle];"
    buff.add "\n"

  for id,node in self.nodes:
    for t,edge in node.out_edges:
      buff.add fmt"{node.label} -> {edge.target.label} [arrowhead = none,weight={$(edge.weight)}];"
      buff.add "\n"

  buff.add "}"
  return buff


when isMainModule:
  let net = newNetwork(directed=false)

  echo "----------------------------"
  echo "Add A,B,C nodes,connect each other"
  echo "----------------------------"

  let tags = @["A","B","C"]

  for i in 0..high(tags):
    for j in (i+1)..high(tags):
      net.push(tags[i],tags[j])

  #net.push("A","B")

  net.print
  echo "----------------------------"
  echo "Delete A node"
  echo "----------------------------"
  net.delNode("A")
  net.print
