package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"k8s.io/kubernetes/staging/src/k8s.io/apimachinery/pkg/util/json"
	"math/rand"
	"os"
	"os/user"
	"sort"
	"strconv"
	"strings"
	"time"
)

func printAndExit(err error) {
	fmt.Fprint(os.Stderr, err.Error())
	os.Exit(1)
}

type NetatmoData struct {
	DataTypes []string `json:"data_types"`
	Body map[string]([]float64) `json:"body"`
}

func mean(l []float64) float64 {
	sum := 0.
	for _, x := range l { sum += x }
	return sum / float64(len(l))
}

func choices(l []float64) []float64 {
	ret := make([]float64, len(l))

	for i := 0; i < len(l); i++ {
		c := rand.Intn(len(l))
		ret[i] = l[c]
	}
	return ret
}

func main() {
	fmt.Printf("Hello, world.\n")
	fmt.Println()

	usr, err := user.Current()
	if err != nil {
		printAndExit(err)
	}

	jsonDir := usr.HomeDir + "/data/netatmo/70ee501250ea-0200001277cc"

	files, err := ioutil.ReadDir(jsonDir)
	if err != nil {
		printAndExit(err)
	}

	//testData := NetatmoData {
	//	Body: map[string][]float32{"foo": {1, 2, 3}},
	//	DataTypes: []string{"bar", "baz"},
	//}
	//out, err := json.Marshal(testData)
	//if err != nil {
	//printAndExit(err)
	//}
	//fmt.Println(string(out))

	temps := make(map[time.Weekday][]float64)

	for _, f := range files {
		if !strings.HasSuffix(f.Name(), ".json") {
			continue
		}

		path := jsonDir + "/" + f.Name()

		jsonBytes, err := ioutil.ReadFile(path)
		if err != nil {
			printAndExit(err)
		}

		var data NetatmoData
		err = json.Unmarshal(jsonBytes, &data)
		if err != nil {
			printAndExit(err)
		}

		if data.DataTypes[0] != "Temperature" {
			printAndExit(errors.New("Item 0 is not temperature"))
		}

		for k, e := range data.Body {
			i, err := strconv.ParseInt(k, 10, 64)
			if err != nil {
				printAndExit(err)
			}
			t := time.Unix(i, 0) //.In(time.UTC)

			temps[t.Weekday()] = append(temps[t.Weekday()], e[0])
		}
	}

	for day, tempList := range temps {
		fmt.Printf("%s %d\n", day, len(tempList))
	}

	fmt.Println()

	for day, tempList := range temps {
		fmt.Printf("%s %f\n", day, mean(tempList))
	}

	iterations := 100

	max := 0.0

	for a := 0; a < 7; a++ {
		for b := 0; b < 7; b++ {
			weekday_a := time.Weekday(a)
			weekday_b := time.Weekday(b)

			summaries := []float64{}
			for i := 0; i < iterations; i++ {
				mean_a := mean(choices(temps[weekday_a]))
				mean_b := mean(choices(temps[weekday_b]))

				summaries = append(summaries, mean_b - mean_a)
			}

			sort.Float64s(summaries)

			confidence := 0.99

			orig_size := len(summaries)
			half_confidence := int(float64(orig_size) * (1 - confidence) / 2)
			summaries = summaries[half_confidence:orig_size - half_confidence - 1]

			low := summaries[0]
			high := summaries[len(summaries) - 1]


			if low < 0 && high < 0 && -high > max {
				max = -high
				fmt.Printf("new max %f\n", max)
			}
			if low > 0 && high > 0 && low > max {
				max = low
				fmt.Printf("new max %f\n", max)
			}

			fmt.Printf("%s - %s, At %.1f%%, [%f to %f]\n",
				weekday_a,
				weekday_b,
				100.0 * float64(len(summaries)) / float64(orig_size),
				low,
				high)
		}
	}

	fmt.Printf("Max is %f\n", max)
}

