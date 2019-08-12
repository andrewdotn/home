package islanders

type algoParam [IslanderCount*13]rune;

func extractParam(param algoParam, index int) []WeighingAssignment {
	ret := make([]WeighingAssignment, IslanderCount)
	for i, _ := range ret {
		char := param[index * IslanderCount + i]
		switch char {
		case 'l':
			ret[i] = Left
		case 'r':
			ret[i] = Right
		case 'n'
			ret[i] = DontWeigh
		}
	}
	return ret
}

func paramEval(param algoParam) Algo {
	f := func(island *island) int {
		r1 := island.Weigh(extractParam(param, 0));

		next2 := 1 + int(r1)
		r2 := island.Weigh(extractParam(param, next2))

		next3 := 4 + 3 * next2 + int(r2)
		island.Weigh(extractParam(param, next3))

		return 0
	}

	return f
}

func generateAndTest() {


}