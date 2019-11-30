package islanders

type fullParam [][]WeighingAssignment

func paramEval(param fullParam) Algo {
	f := func(island *island) int {
		r1 := island.Weigh(param[0])

		next2 := 1 + int(r1)
		r2 := island.Weigh(param[next2])

		next3 := 4 + 3 * int(r1) + int(r2)

		island.Weigh(param[next3])

		return 0
	}

	return f
}

func generateOne() (Algo, fullParam) {
	param := make(fullParam, 13)
	for i, _ := range param {
		param[i] = make([]WeighingAssignment, IslanderCount)

		toPick := 1 + randInt(IslanderCount/2)

		pick(&param[i], toPick, Left)
		pick(&param[i], toPick, Right)
	}

	return paramEval(param), param
}
