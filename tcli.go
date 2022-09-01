package main

import (
  "log"
  "os"
  "github.com/pelletier/go-toml/v2"
)

type MainBub struct {
  BaseUrl string
  Bubs []string
  Headers map[string]string
}

type Bubs struct {
  Bub MainBub
}

func read_bubs() (Bubs) {
  bub := "bubs.toml"
  bytes, err := os.ReadFile(bub)
  if err != nil {
    log.Fatal(err)
  }
  var bubs Bubs
  e := toml.Unmarshal(bytes, &bubs)
  if e != nil {
    log.Fatal(e)
  }
  return bubs
}

func check_haha(bubs Bubs) Graphene {
  graph := NewGraph(bubs.Bub.BaseUrl, bubs.Bub.Headers)
  queries := [][]GraphQuery{}
  for _, bub := range bubs.Bub.Bubs {
    queries = append(queries, graph.BubMeta(bub))
  }
  log.Println(len(queries))
  graph.Queries = queries
  return graph
}

func main() {
  bubs := read_bubs()
  graph := check_haha(bubs)
  log.Println("Created", len(graph.Queries), "queries")
  graph.Resolve()
}
