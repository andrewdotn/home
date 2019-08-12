package islanders

func selectionAlgo(island *island) int {
	island.WeighByList([]int{0, 1, 2, 3, 4, 5}, []int{6, 7, 8, 9, 10, 11})
	island.WeighByList([]int{0, 2, 4, 6, 8, 10}, []int{1, 3, 5, 7, 9, 11})
	island.WeighByList([]int{0, 1, 4, 5, 8, 9}, []int{2, 3, 6, 7, 10, 11})
	return 0
}
