package main

import (
  "log"
  "os"
  //"github.com/go-resty/resty/v2"
  "github.com/pelletier/go-toml/v2"
)

type MainBub struct {
  BaseUrl string
}

type Bubs struct {
  Bub MainBub
  Ubs []string
}

func read_bubs(bubs Bubs) {
  bub := "bubs.toml"
  bytes, err := os.ReadFile(bub)
  if err != nil {
    log.Fatal(err)
  }
  e := toml.Unmarshal(bytes, &bubs)
  if e != nil {
    log.Fatal(err)
  }
}

func check_haha(bubs Bubs) {
  for _, bub := range bubs.Ubs {
    log.Println(bub)
  }
}

func main() {
  var bubs Bubs
  read_bubs(bubs)
  log.Println(bubs)
  check_haha(bubs)
}
