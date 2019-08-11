package main

import (
	"fmt"
	"log"
)
import "gonum.org/v1/gonum/mat"

func main() {
	fmt.Println("hello, world")

	mat1 := []float64{
		1, 2, 3, 7,
	};

	m := mat.NewDense(2, 2, mat1);
	r := mat.NewDense(2, 1, []float64{4, 1})

	formatted := mat.Formatted(m);

	fmt.Println(formatted);

	fmt.Println("Solution:")

	var result mat.Dense
	err := result.Solve(m, r);
	if  err != nil {
		log.Fatal(err);
	} else {
		fmt.Println(mat.Formatted(&result));
	}

}