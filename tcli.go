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

func main() {
  f, err := os.OpenFile("test.log", os.O_APPEND | os.O_CREATE | os.O_RDWR, 0600)
  if err != nil {
    log.Fatal("so sad")
  }
  log.SetOutput(f)
  defer f.Close()
  log.Println("Booting...")
  bubs := read_bubs()
  log.Println("Got bubs:", bubs.Bub.Bubs)
  graph := NewGraph(bubs.Bub.BaseUrl, bubs.Bub.Headers)
  log.Println("Baseurl:", bubs.Bub.BaseUrl)
  graph.Resolve(bubs)
}
