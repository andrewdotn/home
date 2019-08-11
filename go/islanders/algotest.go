package islanders

import (
	"crypto/rand"
	"fmt"
	"math/big"
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

func randomAlgo(island *island) int {
	b := new(big.Int)
	b.SetInt64(ISLANDER_COUNT)
	r, err := rand.Int(rand.Reader, b)
	if err != nil {
		panic("couldn't get random number")
	}
	i := int(r.Int64())

	fmt.Println(i)
	return i;
}

func TestAlgo(a Algo) {
	weights := []Weight{HEAVIER, LIGHTER}

	correct := 0
	trials := 0
	maxWeighings := 0

	for i := 0; i < ISLANDER_COUNT; i++ {
		for _, w := range weights {
			island := NewIsland(i, w)

			r := a(island)
			trials++

			if r == i {
				correct++
			}
			maxWeighings = max(maxWeighings, island.weighingCount)
		}
	}

	fmt.Printf("%d/%d correct in max %d weighings\n", correct, trials,
	maxWeighings)
}