package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"github.com/go-resty/resty/v2"
	"log"
	"sync"
)

type StreamMetaBase struct {
	Data MetaDataRoot `json:"data"`
}

type MetaDataRoot struct {
	User UserMeta `json:"user"`
}

type UserMeta struct {
	Stream *StreamMeta `json:"stream"`
}

type StreamMeta struct {
	Type string `json:"type"`
}

type Extensions struct {
	PersistedQuery PersistedQuery `json:"persistedQuery"`
}

type PersistedQuery struct {
	Version    int    `json:"version"`
	Sha256hash string `json:"sha256hash"`
}

type GraphQuery struct {
	OperationName string                 `json:"operationName"`
	Extensions    Extensions             `json:"extensions"`
	Variables     map[string]interface{} `json:variables`
}

type Graphene struct {
	client  *resty.Client
	baseUrl string
}

func NewGraph(url string, headers map[string]string) Graphene {
	client := resty.New()
	client.SetHeaders(headers)
	client.SetHeader("Content-Type", "application/json")
	client.SetTLSClientConfig(&tls.Config{InsecureSkipVerify: true})
	return Graphene{
		client:  client,
		baseUrl: url,
	}
}

func (graph *Graphene) BubMeta(channel string) GraphQuery {
	meta := GraphQuery{
		OperationName: "StreamMetadata",
		Extensions: Extensions{
			PersistedQuery{
				Version:    1,
				Sha256hash: "059c4653b788f5bdb2f5a2d2a24b0ddc3831a15079001a3d927556a96fb0517f",
			},
		},
		Variables: map[string]interface{}{
			"channelLogin": channel,
		},
	}
	return meta
}

func (graph *Graphene) Resolve(bubs Bubs) {
	var group sync.WaitGroup
	for _, bub := range bubs.Bub.Bubs {
		q := graph.BubMeta(bub)
		bytes, err := json.Marshal(q)
		if err != nil {
			log.Fatal("Something about you is haunting my mind", err)
		}

		group.Add(1)
		go graph.call(string(bytes), bub, &group)
	}
	group.Wait()
}

func (graph *Graphene) call(req string, bub string, group *sync.WaitGroup) {
	defer group.Done()
	respFormat := StreamMetaBase{}
	_, err := graph.client.R().SetBody(req).SetResult(&respFormat).Post(graph.baseUrl)
	if err != nil {
		log.Fatal(err)
	}

	if respFormat.Data.User.Stream != nil {
		fmt.Println(bub, ":", respFormat.Data.User.Stream.Type)
		log.Println(bub, ":", respFormat.Data.User.Stream.Type)
	}
}
