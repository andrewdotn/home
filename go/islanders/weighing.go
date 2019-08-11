package islanders

import (
	"log"
)

type Weight int

const (
	HEAVIER Weight = iota
	LIGHTER
)

type island struct {
	different     uint8
	weight        Weight
	weighingCount int
}

func NewIsland(different int, weight Weight) *island {
	return &island{uint8(different), weight, 0};
}

const ISLANDER_COUNT = 12

type WeighingResult int

const (
	LEFT_HEAVIER WeighingResult = iota
	LEFT_LIGHTER
	EQUAL
)

func (w WeighingResult) String() string {
	switch(w) {
	case LEFT_LIGHTER:
		return "<"
	case LEFT_HEAVIER:
		return ">"
	case EQUAL:
		return "="
	}
	panic("unknown Weigh result")
}

func weighResultToWeightOnLeft(w WeighingResult) Weight {
	switch w {
	case LEFT_LIGHTER:
		return LIGHTER
	case LEFT_HEAVIER:
		return HEAVIER
	default:
		panic("bad weight result in conversion")
	}
}

func Invert(w Weight) Weight {
	switch w {
	case LIGHTER:
		return HEAVIER
	case HEAVIER:
		return LIGHTER
	default:
		panic("bad weight result in conversion")
	}
}

type WeighingAssignment int

const (
	DONT_WEIGH WeighingAssignment = iota
	LEFT
	RIGHT
)

func (island *island) WeighByList(left, right []int) WeighingResult {
	assignment := make([]WeighingAssignment, ISLANDER_COUNT)
	for _, l := range left {
		assignment[l] = LEFT
	}
	for _, r := range right {
		assignment[r] = RIGHT
	}
	return island.Weigh(assignment);
}

func (island *island) Weigh(what []WeighingAssignment) WeighingResult {
	island.weighingCount += 1

	if len(what) != ISLANDER_COUNT {
		panic("does not match")
	}

	leftCount := 0
	rightCount := 0

	for i := 0; i < ISLANDER_COUNT; i++ {
		switch what[i] {
		case LEFT:
			leftCount++
		case RIGHT:
			rightCount++
		}
	}

	if leftCount != rightCount {
		log.Fatal("counts do not match")
	}
	if leftCount < 1 {
		log.Fatal("counts do not match")
	}

	if what[island.different] == DONT_WEIGH {
		return EQUAL
	}
	if (what[island.different] == LEFT && island.weight == HEAVIER) || (what[island.different] == RIGHT && island.weight == LIGHTER) {
		return LEFT_HEAVIER
	}
	return LEFT_LIGHTER
}
