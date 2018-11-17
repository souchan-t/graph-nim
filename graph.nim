import tables
import strformat
from algorithm import binarySearch,sort,sorted

type
  Edge* = ref object
    source:Node ## 元ノード
    target:Node ## 先ノード
    label:string ## ラベル
    weight:float ## 重み


  Node* = ref object
    id:string ## ID
    label:string ## ラベル
    edges:seq[Edge] ## エッジリスト

  Network* = ref object
    nodes:Table[string,Node] ##ノードテーブル


proc getEdgeIndex*(self:Node,target:Node):int

# Edge ------------------------------------------------------------------------
proc newEdge*(source,target:Node,label:string="",weight:float=0.0):Edge=
  var e = new Edge
  e.target = target
  e.source = source
  e.label = label
  e.weight = weight
  return e

proc isAdjacent*(self:Edge,target:Edge):bool=
  if self.source.getEdgeIndex(target.source) == -1 and
    self.source.getEdgeIndex(target.target) == -1 and
    target.target.getEdgeIndex(self.source) == -1 and
    target.target.getEdgeIndex(self.target) == -1:
    return false
  else:
    return true
# Node ------------------------------------------------------------------------
proc newNode*(id:string,label:string):Node=
  var n = new Node
  n.id = id
  n.label = label
  n.edges = newSeq[Edge]()
  return n


proc getEdgeIndex*(self:Node,target:Node):int=
  let idx = binarySearch[Edge,string](self.edges,target.id,
    proc (x:Edge,y:string):int=
      if x.target.id > y:
        return -1
      elif x.target.id < y:
        return 1
      else:
        return 0
  )
  return idx

proc addEdge*(self:Node,edge:Edge)=
  self.edges.add(edge)
  #sort[Edge](self.edges,proc(x,y:Edge):int=int(y.weight-x.weight))

proc `=>`*(self:Node,target:Node):Node {.discardable.}=
  let idx = self.getEdgeIndex(target)
  if idx == -1:
    self.addEdge(newEdge(self,target,weight=1.0))
    return target
  else:
    self.edges[idx].weight += 1.0
    return target

proc `<=`*(self:Node,target:Node):Node {.discardable.}=
  return target => self

proc `<=>`*(self:Node,target:Node):Node {.discardable.}=
  return self => target => self


proc getEdge*(self:Node,target:Node):Edge=
  let idx = self.getEdgeIndex(target)
  if idx != -1:
    return self.edges[idx]
  else:
    return nil

proc delEdge*(self:Node,target:Node)=
  let idx = self.getEdgeIndex(target)
  if idx != -1:
    self.edges.del(idx)

# Network ---------------------------------------------------------------------
proc newNetwork*():Network=
  var p = new Network
  p.nodes = initTable[string,Node]()
  return p

proc addNode*(self:Network,node:Node)=
  self.nodes.add(node.id,node)

proc delNode*(self:Network,id:string)=
  # 削除対象のノード取得
  let n = self.nodes[id]

  # 隣接ノードのエッジを削除
  for e in n.edges:
    e.target.delEdge(n)

  # 対象ノードを削除
  self.nodes.del(id)

proc getNode*(self:Network,id:string):Node=
  if self.nodes.hasKey(id):
    return self.nodes[id]
  else:
    return nil

proc `[]`*(self:Network,id:string):Node=
  return self.getNode(id)

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

  discard s_node <=> t_node


proc print*(self:Network)=
  for k,v in self.nodes:
    for i,e in v.edges:
      echo fmt"{v.label} ---> {e.weight} ---> {v.edges[i].target.label}"

proc toDOT*(self:Network):string=
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
    for i,edge in node.edges:
      buff.add fmt"{edge.source.label} -> {edge.target.label} [arrowhead = none,weight={$(edge.weight)}];"
      buff.add "\n"

  buff.add "}"
  return buff


when isMainModule:
  let net = newNetwork()

  let tags = @["A","B","C"]

  for i in 0..high(tags):
    for j in (i+1)..high(tags):
      net.push(tags[i],tags[j])

  net["A"] => net["B"]

  net.print


