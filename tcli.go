package main

import (
	"fmt"
	"os"
	"strings"
)

func get_env(keys []string) {
	for _, str := range os.Environ() {
		parts := strings.SplitN(str, "=", 2)
		for _, key := range keys {
			if key == parts[0] {
				fmt.Println(key, ":", parts[1])
				return
			}
		}
	}
}

func main() {
	get_env([]string{"TWITCH_ID"})
}
