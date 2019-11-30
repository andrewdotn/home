package islanders

import (
	"flag"
	"fmt"
	"gonum.org/v1/gonum/mat"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"reflect"
	"runtime"
	"runtime/pprof"
	"syscall"
	"time"
)

// https://stackoverflow.com/a/7053871/14558
func getFunctionName(i interface{}) string {
	return runtime.FuncForPC(reflect.ValueOf(i).Pointer()).Name()
}

var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")

var numitersVar int

func Main() {
	flag.IntVar(&numitersVar, "numiters", 1000000, "how many random algorithms to try")

	flag.Parse()
	if *cpuprofile != "" {
		f, err := os.Create(*cpuprofile)
		if err != nil {
			log.Fatal(err)
		}
		pprof.StartCPUProfile(f)
		defer pprof.StopCPUProfile()
	}

	fmt.Println("hello, world")

	mat1 := []float64{
		1, 2, 3, 7,
	}

	m := mat.NewDense(2, 2, mat1)
	r := mat.NewDense(2, 1, []float64{4, 1})

	formatted := mat.Formatted(m)

	fmt.Println(formatted)

	fmt.Println("Solution:")

	var result mat.Dense
	err := result.Solve(m, r)
	if err != nil {
		log.Fatal(err)
	} else {
		fmt.Println(mat.Formatted(&result))
	}

	island1 := NewIsland(0, Heavier)
	assignment1 := make([]WeighingAssignment, IslanderCount)

	assignment1[0] = Left
	assignment1[1] = Right
	x := island1.Weigh(assignment1)
	fmt.Printf("weigh result: %v\n", x)

	algorithms := []Algo{
		dummyAlgo,
		randomAlgo,
		fourRoundAlgo,
		subsetAlgo,
		betterRandomAlgo,
	}

	for i, a := range algorithms {
		fmt.Println()
		fmt.Printf("Algo %d: %s\n", i, getFunctionName(a))
		fmt.Printf("%+v\n", TestAlgo(a))
	}

	fmt.Println()
	fmt.Println("Now trying randomly-generated algorithms")

	rand.Seed(time.Now().UTC().UnixNano())

	var bestRes TestResult
	var bestParam fullParam

	// https://stackoverflow.com/a/18158859/14558
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		fmt.Printf("Best was %+v with %+v\n", bestRes, bestParam)
		os.Exit(1)
	}()

	start := time.Now()
	for i := 0; i < numitersVar; i++ {
		if i % 10000 == 0 {
			fmt.Printf(".")
		}
		if i % 100000 == 0 {
			duration := time.Since(start)
			fmt.Printf("%v, %f/s\n", duration.String(), float64(i) / duration.Seconds())
		}
		algo, param := generateOne()
		res := TestAlgo(algo)
		if res.solveCorrect > bestRes.solveCorrect {
			bestRes = res
			bestParam = param
			msg := fmt.Sprintf("New best result on step %d: %+v with %+v\n",
				i, bestRes, bestParam)
			fmt.Println(msg)
			err := ioutil.WriteFile("best.txt", []byte(msg), 0666)
			if err != nil {
				panic("couldn’t write")
			}
		}
	}
	fmt.Println(errorStats)
}
