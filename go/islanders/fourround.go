// The intial four-round algorithm I came up with in my head

package islanders

func intEqual(a, b []int) bool {
	if len(a) != len(b) {
		return false
	}
	for i, aValue := range a {
		if aValue != b[i] {
			return false
		}
	}
	return true
}

func resolveTwo(island *island, direction Weight, a, b int) int {
	r := island.WeighByList([]int{a}, []int{b})
	if direction == weighResultToWeightOnLeft(r) {
		return a
	}
	return b
}

func fourRoundAlgo(island *island) int {
	groupA := []int{0, 1, 2, 3}
	groupB := []int{4, 5, 6, 7}
	groupC := []int{8, 9, 10, 11}

	r1 := island.WeighByList(groupA, groupB)
	r2 := island.WeighByList(groupB, groupC)

	var narrowedToFour []int
	var direction Weight
	if r1 == Equal {
		narrowedToFour = groupC
		direction = Invert(weighResultToWeightOnLeft(r2))
	} else if r2 == Equal {
		narrowedToFour = groupA
		direction = weighResultToWeightOnLeft(r1)
	} else {
		narrowedToFour = groupB
		direction = weighResultToWeightOnLeft(r2)
	}

	d := narrowedToFour[0]
	e := narrowedToFour[1]
	f := narrowedToFour[2]
	g := narrowedToFour[3]
	r3 := island.WeighByList([]int{d, e}, []int{f, g})
	if direction == weighResultToWeightOnLeft(r3) {
		return resolveTwo(island, direction, d, e)
	} else {
		return resolveTwo(island, direction, f, g)
	}

	return 0
}
