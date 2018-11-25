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

# Edge
proc newEdge*(source,target:Node,label:string="",weight:float=0.0):Edge
proc `$`*(self:Edge):string

# NodeCmp
proc `<`*(self,other:NodeCmp):bool

# Node
proc init*(self:Node,id:string,label:string="")
proc newNode*(id:string,label:string=""):Node
proc inDegree*(self:Node):int
proc outDegree*(self:Node):int
proc degree*(self:Node):int
proc getOutEdge*(self:Node,target:Node):Edge
proc getInEdge*(self:Node,target:Node):Edge
proc delOutEdge*(self:Node,target:Node)
proc delInEdge*(self:Node,target:Node)
proc connect*(self:Node,target:Node,weight=0.0):Node{.discardable.}
proc `->`*(self:Node,target:Node):Node {.discardable.}
proc `<-`*(self:Node,target:Node):Node {.discardable.}
proc `<->`*(self:Node,target:Node):Node {.discardable.}
proc `--`*(self:Node,target:Node):Edge {.discardable.}
proc `$`*(self:Node):string
#iterator depthFirstSearch*(self:Node):Node
#iterator breadthFirstSearch*(self:Node):Node

# Network
proc newNetwork*(name:string="NoName"):Network
proc getNode*(self:Network,id:string):Node
proc getNodeIds*(self:Network):seq[string]
proc addNode*(self:Network,node:Node)
proc addNode*(self:Network,nodes:openarray[Node])
proc addNode*(self:Network,node_ids:openarray[string])
proc addNodeAndConnect*(self:Network,source:string,target:string,
  directed=false,weight=0.0,selfconnect:bool=false)
proc addNodeAndConnect*(self:Network,tags:openarray[string],
  directed=false,weight=0.0,selfconnect:bool=false)
proc delNode*(self:Network,id:string)
#iterator each_edge*(self:Network):Edge
proc edges*(self:Network):seq[Edge]
#iterator each_node*(self:Network):Node
proc createAdjMatrix*(self:Network):AdjMatrix
proc createAdjMatrix_weighted*(self:Network):AdjMatrix_W
proc degrees*(self:Network):seq[int]
proc centralityDegree*(self:Network):seq[float]
proc `[]`*(self:Network,id:string):Node
proc `[]=`*(self:Network,id:string,node:Node):Node{.discardable.}
proc `[]=`*(self:Network,id:string,label:string):Node{.discardable.}
proc `$`*(self:Network):string
proc toDOT*(self:Network):string

# AdjMatrix,AdjMatrix_W
proc newNetwork*(matrix:AdjMatrix,
                 nodeNames:openarray[string],
                 name="noname"):Network
proc newNetwork*(matrix:AdjMatrix_W,
                 nodeNames:openarray[string],
                 name="noname"):Network
