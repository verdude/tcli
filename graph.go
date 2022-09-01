package main

import (
  "log"
  "encoding/json"
  "github.com/go-resty/resty/v2"
  "crypto/tls"
)

type Extensions struct {
  PersistedQuery PersistedQuery `json:"persistedQuery"`
}

type PersistedQuery struct {
  Version int `json:"version"`
  Sha256hash string `json:"sha256hash"`
}

type BubsMeta struct {
  OperationName string `json:"operationName"`
  Extensions Extensions `json:"extensions"`
  Variables map[string]interface{} `json:variables`
}

type Graphene struct {
  client *resty.Client
  baseUrl string
}

func NewGraph(url string, headers map[string]string) Graphene {
  client := resty.New()
  client.SetHeaders(headers)
  client.SetTLSClientConfig(&tls.Config{ InsecureSkipVerify: true })
  return Graphene {
    client: client,
    baseUrl: url,
  }
}

func (client *Graphene) BubHostCheck(channel string) {
  req := BubsMeta{
    OperationName: "UseHosting",
    Extensions: Extensions{
      PersistedQuery: PersistedQuery{
        Version: 1,
        Sha256hash: "427f55a3daca510f726c02695a898ef3a0de4355b39af328848876052ea6b337",
      },
    },
    Variables: map[string]interface{}{
      "channelLogin": channel,
    },
  }
  bytes, err := json.Marshal(req)
  if err != nil {
    log.Fatal("bubhostcheck", err)
  }
  client.call(string(bytes))
}

func (client *Graphene) call(req string) {
  log.Println(req)
  resp, err := client.client.R().SetBody(req).Post(client.baseUrl)
  if err != nil {
    log.Fatal(err)
  }
  log.Println(resp)
}
