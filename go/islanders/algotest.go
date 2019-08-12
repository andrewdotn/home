package islanders

import (
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
	return mathrand.Intn(lessThan)
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

		toPick := int(1 + randInt(IslanderCount/2))

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

type TestResult struct {
	solveCorrect, correct, trials, maxWeighings int
}

func TestAlgo(a Algo) TestResult {
	weights := []Weight{Heavier, Lighter}

	var res TestResult

	for i := 0; i < IslanderCount; i++ {
		for _, w := range weights {
			island := NewIsland(i, w)

			r := a(island)
			if r == i {
				res.correct++
			}
			res.trials++
			res.maxWeighings = max(res.maxWeighings, island.weighingCount)

			if i == solveWeighings(island) {
				res.solveCorrect++
			}
		}
	}

	return res
}
