package islanders

import (
	"fmt"
	"gonum.org/v1/gonum/mat"
	"log"
	"reflect"
	"runtime"
)

// https://stackoverflow.com/a/7053871/14558
func getFunctionName(i interface{}) string {
	return runtime.FuncForPC(reflect.ValueOf(i).Pointer()).Name()
}

func Main() {
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

	island1 := NewIsland(0, HEAVIER)
	assignment1 := make([]WeighingAssignment, ISLANDER_COUNT)

	assignment1[0] = LEFT
	assignment1[1] = RIGHT
	x := island1.Weigh(assignment1)
	fmt.Printf("weigh result: %v\n", x)

	algorithms := []Algo{
		dummyAlgo,
		randomAlgo,
		fourRoundAlgo,
	}

	for i, a := range algorithms {
		fmt.Println()
		fmt.Printf("Algo %d: %s\n", i, getFunctionName(a))
		TestAlgo(a)
	}

}