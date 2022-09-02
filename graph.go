package main

import (
  "log"
  "fmt"
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

type GraphQuery struct {
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

func (graph *Graphene) BubHostCheck(channel string) GraphQuery {
  query := GraphQuery{
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
  return query
}

func (graph *Graphene) BubMeta(channel string) []GraphQuery {
  query1 := GraphQuery{
    OperationName: "ChannelShell",
    Extensions: Extensions{
      PersistedQuery{
        Version: 1,
        Sha256hash: "c3ea5a669ec074a58df5c11ce3c27093fa38534c94286dc14b68a25d5adcbf55",
      },
    },
    Variables: map[string]interface{}{
      "login": channel,
      "lcpVideosEnabled": false,
    },
  }
  query2 := GraphQuery{
    OperationName: "StreamMetadata",
    Extensions: Extensions{
      PersistedQuery{
        Version: 1,
        Sha256hash: "059c4653b788f5bdb2f5a2d2a24b0ddc3831a15079001a3d927556a96fb0517f",
      },
    },
    Variables: map[string]interface{}{
      "channelLogin": channel,
    },
  }
  queries := make([]GraphQuery, 3)
  queries[0] = graph.BubHostCheck(channel)
  queries[1] = query2
  queries[2] = query1
  return queries
}

func (graph *Graphene) Resolve(bubs Bubs) {
  queries := [][]GraphQuery{}
  for _, bub := range bubs.Bub.Bubs {
    queries = append(queries, graph.BubMeta(bub))
  }
  log.Println("Created", len(queries), "* 3 queries")
  for _, q := range queries {
    bytes, err := json.Marshal(q)
    if err != nil {
      log.Fatal("Something about you is haunting my mind", err)
    }
    log.Println(string(bytes))
  }
}

func (graph *Graphene) call(req string) {
  resp, err := graph.client.R().SetBody(req).Post(graph.baseUrl)
  if err != nil {
    log.Fatal(err)
  }
  fmt.Println(resp)
}
