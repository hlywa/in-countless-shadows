extends RefCounted
class_name CompositionState
## Logical word order is authoritative; screen coordinates are projections.
const LINE_COUNT := 14
var lines: Array[Array] = []
var word_count := 0

func _init(count: int = 0) -> void:
	word_count = count
	for i in range(LINE_COUNT):
		lines.append([])

func find_line(id: int) -> int:
	for n in range(LINE_COUNT):
		if id in lines[n]:
			return n
	return -1

func remove_word(id: int) -> void:
	for line in lines:
		line.erase(id)

func insert_word(id: int, line_number: int, index: int) -> bool:
	if id < 0 or id >= word_count or line_number < 0 or line_number >= LINE_COUNT:
		return false
	remove_word(id)
	lines[line_number].insert(clampi(index,0,lines[line_number].size()),id)
	return true

func capture() -> Array:
	var result: Array = []
	for line in lines:
		result.append(line.duplicate())
	return result

func restore(data: Array) -> bool:
	if data.size() != LINE_COUNT:
		return false
	var seen := {}
	var replacement: Array[Array] = []
	for line in data:
		if not (line is Array):
			return false
		var copy: Array = []
		for raw_id in line:
			if not (raw_id is int):
				return false
			var id: int = raw_id
			if id < 0 or id >= word_count or seen.has(id):
				return false
			seen[id] = true
			copy.append(id)
		replacement.append(copy)
	lines = replacement
	return true

func placed_count() -> int:
	var count := 0
	for line in lines:
		count += line.size()
	return count

func as_words(inventory: Array) -> Array[Array]:
	var result: Array[Array] = []
	for line in lines:
		var words: Array = []
		for id in line:
			words.append(str(inventory[int(id)]["word"]))
		result.append(words)
	return result
