package islanders

import (
	"fmt"
	"gonum.org/v1/gonum/mat"
	"math"
	"strings"
)

const solveDebug = false

const singularError = "matrix singular or near-singular with condition number"
var errorStats map[string]int

func init() {
	resetStats()
}

func resetStats() {
	errorStats = make(map[string]int)
}

func solveWeighings(island *island) int {
	const islanderAverageWeight = 10.0
	const islanderWeightAbsDifference = 1.0

	weighCount := len(island.weighings)
	if weighCount == 0 {
		return -1
	}

	mIn := make([]float64, (weighCount + 1) * IslanderCount)
	aIn := make([]float64, weighCount + 1)

	for i := 0; i < weighCount; i++ {
		direction := island.weighingResults[i]
		switch direction {
		case Equal:
			aIn[i] = 0
		case LeftLighter:
			aIn[i] = 1
		case LeftHeavier:
			aIn[i] = -1
		}

		for j := 0; j < IslanderCount; j++ {
			var f float64
			switch island.weighings[i][j] {
			case Left:
				f = 1
			case Right:
				f = -1
			case DontWeigh:
				f = 0
			}
			mIn[IslanderCount* i + j] = f
		}
	}

	// Sum of all is approx equal
	for i := 0; i < IslanderCount; i++ {
		mIn[IslanderCount* weighCount + i] = islanderWeightAbsDifference
	}
	aIn[weighCount] = 10 * IslanderCount

	m := mat.NewDense(weighCount + 1, IslanderCount, mIn)
	a := mat.NewDense(weighCount + 1, 1, aIn);

	if solveDebug {
		fmt.Printf("%v\n", mat.Formatted(m));
		fmt.Printf("%v\n", mat.Formatted(a));
	}

	var b mat.Dense
	err := b.Solve(m, a)
	if err != nil {
		handleError(err)
		return -1
	}

	if solveDebug {
		fmt.Printf("%v\n", mat.Formatted(&b))
	}

	found := false
	var best int
	for i := 0; i < IslanderCount; i++ {
		if math.Abs(b.At(i, 0) - islanderAverageWeight) > 0.5 {
			if (found) {
				handleError(fmt.Errorf("multiple solutions"))
				return -1
			}
			best = i
			found = true
		}
	}

	if solveDebug {
		fmt.Printf("Best is %d\n", best)
	}
	return best
}

func handleError(err error) {
	errString := err.Error()
	if strings.HasPrefix(errString, singularError) {
		errString = singularError
	}
	errorStats[errString]++
}
