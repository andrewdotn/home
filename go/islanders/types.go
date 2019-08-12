package islanders

type Weight int

const (
	Heavier Weight = iota
	Lighter
)

type island struct {
	different     uint8
	weight        Weight
	weighingCount int
	weighings     [][]WeighingAssignment
	weighingResults []WeighingResult
}

func NewIsland(different int, weight Weight) *island {
	return &island{
		uint8(different),
		weight,
		0,
		[][]WeighingAssignment{},
		[]WeighingResult{},
	}
}

const IslanderCount = 12

type WeighingResult int

const (
	LeftHeavier WeighingResult = iota
	LeftLighter
	Equal
)

func (w WeighingResult) String() string {
	switch w {
	case LeftLighter:
		return "<"
	case LeftHeavier:
		return ">"
	case Equal:
		return "="
	}
	panic("unknown Weigh result")
}

func weighResultToWeightOnLeft(w WeighingResult) Weight {
	switch w {
	case LeftLighter:
		return Lighter
	case LeftHeavier:
		return Heavier
	default:
		panic("bad weight result in conversion")
	}
}

func Invert(w Weight) Weight {
	switch w {
	case Lighter:
		return Heavier
	case Heavier:
		return Lighter
	default:
		panic("bad weight result in conversion")
	}
}

type WeighingAssignment int

const (
	DontWeigh WeighingAssignment = iota
	Left
	Right
)
