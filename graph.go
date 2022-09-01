package main

import (
  "log"
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

func (client *Graphene) BubHostCheck(channel string) GraphQuery {
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

func (client *Graphene) BubMeta(channel string) []GraphQuery {
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
  return []GraphQuery{query1, query2}
}

func (client *Graphene) call(req string) {
  log.Println(req)
  resp, err := client.client.R().SetBody(req).Post(client.baseUrl)
  if err != nil {
    log.Fatal(err)
  }
  log.Println(resp)
}
