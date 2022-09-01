package main

import (
  "log"
  "os"
  //"github.com/go-resty/resty/v2"
  "github.com/pelletier/go-toml/v2"
)

type MainBub struct {
  BaseUrl string
  Bubs []string
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

func check_haha(bubs Bubs) {
  for _, bub := range bubs.Bub.Bubs {
    log.Println(bub)
  }
}

func main() {
  bubs := read_bubs()
  check_haha(bubs)
}
