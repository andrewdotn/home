package islanders

import (
	"crypto/rand"
	"fmt"
	"math/big"
	mathrand "math/rand"
)

type Algo = func(i *island) int

func max(a, b int) int {
	if a < b {
		return b
	}
	return a
}

func dummyAlgo(island *island) int {
	return 0
}

func randInt(lessThan int) int {
	b := new(big.Int)
	b.SetInt64(int64(lessThan))
	r, err := rand.Int(rand.Reader, b)
	if err != nil {
		panic("couldn't get random number")
	}
	i := int(r.Int64())
	return i
}

func randomAlgo(island *island) int {
	return randInt(IslanderCount)
}

func pick(assignment *[]WeighingAssignment, count int, side WeighingAssignment) {
	picked := 0
	for picked < count {
		i := randInt(len(*assignment))
		if ((*assignment)[i] == DontWeigh) {
			(*assignment)[i] = side
			picked++
		}
	}
}

func betterRandomAlgo(island *island) int {
	for weighing := 0; weighing < 3; weighing++ {
		assignment := make([]WeighingAssignment, IslanderCount)

		toPick := int(1 + mathrand.Int31n(5))

		pick(&assignment, toPick, Left)
		pick(&assignment, toPick, Right)

		island.Weigh(assignment)
	}
	return 0
}

func subsetAlgo(island *island) int {
	island.WeighByList([]int{0, 1, 2, 3, 4, 5}, []int{6, 7, 8, 9, 10, 11})
	island.WeighByList([]int{0, 2, 4, 6, 8, 10}, []int{1, 3, 5, 7, 9, 11})
	island.WeighByList([]int{0, 1, 4, 5, 8, 9}, []int{2, 3, 6, 7, 10, 11})
	return 0
}

func TestAlgo(a Algo) {
	weights := []Weight{Heavier, Lighter}

	correct := 0
	trials := 0
	maxWeighings := 0

	solveCorrect := 0

	for i := 0; i < IslanderCount; i++ {
		for _, w := range weights {
			island := NewIsland(i, w)

			r := a(island)
			if r == i {
				correct++
			}
			trials++
			maxWeighings = max(maxWeighings, island.weighingCount)

			if i == solveWeighings(island) {
				solveCorrect++
			}
		}
	}

	fmt.Printf("%d/%d correct, %d with solver, in max %d weighings\n",
		correct, trials, solveCorrect, maxWeighings)
}