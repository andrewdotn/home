package islanders

import (
	"log"
)

func (island *island) WeighByList(left, right []int) WeighingResult {
	assignment := make([]WeighingAssignment, IslanderCount)
	for _, l := range left {
		assignment[l] = Left
	}
	for _, r := range right {
		assignment[r] = Right
	}
	return island.Weigh(assignment);
}

func (island *island) Weigh(what []WeighingAssignment) WeighingResult {
	island.weighingCount += 1
	assignmentCopy := make([]WeighingAssignment, len(what))
	copy(assignmentCopy, what)
	island.weighings = append(island.weighings, assignmentCopy)

	if len(what) != IslanderCount {
		panic("does not match")
	}

	leftCount := 0
	rightCount := 0

	for i := 0; i < IslanderCount; i++ {
		switch what[i] {
		case Left:
			leftCount++
		case Right:
			rightCount++
		}
	}

	if leftCount != rightCount {
		log.Fatal("counts do not match")
	}
	if leftCount < 1 {
		log.Fatal("counts do not match")
	}

	var r WeighingResult
	if what[island.different] == DontWeigh {
		r = Equal
	} else if (what[island.different] == Left && island.weight == Heavier) || (what[island.different] == Right && island.weight == Lighter) {
		r = LeftHeavier
	} else {
		r = LeftLighter
	}
	island.weighingResults = append(island.weighingResults, r)
	return r
}
