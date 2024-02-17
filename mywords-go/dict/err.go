package dict

type Err string

const DataNotFound = Err("data not found")

func (e Err) Error() string {
	return string(e)
}
