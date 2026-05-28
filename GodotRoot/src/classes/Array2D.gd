class_name Array2D
extends Reference
# author: willnationsdev
# description: A 2D Array class

# A ROW of sub-arrays that are COLUMNS
var data: Array = []
var onebased: bool = false
	# If true, all inbound values are decremented by one before being processed, then incremented by one after, so [1, 3] in usage == [0, 2] in data
	# We'll assume that all PRIVATE functions have exclusively zero-based params
# ---

func _init(p_array: Array = [], p_deep_copy : bool = true):
	if p_deep_copy:
		for col in p_array:
			if col is Array:
				data.append(col.duplicate())
	else:
		data = p_array

# -

func get_data() -> Array: # NOT onebase-able!
	return data

func get_dataset_with_coords(return_null = false) -> Array:
	# Generates an array of arrays, where each inner-array is [value, coord]
	
	var dataset: Array = []
	
	var x: int = 0
	for col in data:
		var y: int = 0
		for value in col:
			var coord: Vector2 = Vector2(x, y)
			if onebased:
				coord.x += 1
				coord.y += 1
			if value == null:
				if return_null:
					dataset.append([value, coord])
			else:
				dataset.append([value, coord])
			
			y += 1
		x += 1
		continue
	
	return dataset
	pass

func get_dataset_values_list() -> Array:
	# Gets all (non-null) values; specifically useful for an array of instances such as actors
	# Unsorted and with duplicates so you have to know what you want to do with it!
	var results: Array = []
	
	for col in data:
		for value in col:
			if value == null: continue
			results.append(value)
	
	return results
	pass

# ---

func has_cell(p_col: int, p_row: int) -> bool:
	if onebased:
		p_col -= 1
		p_row -= 1
	
#	if len(data) > p_col:
#		print("pass_1 when first param is ",len(data))
#		if len(data[p_col]) > p_row:
#			print("pass_2 when first param is ",len(data[p_col]))
#			if p_col >= 0:
#				print("pass_3")
#				if p_row >= 0:
#					print("pass_4")
#					return true
#
#	return false
	
	return len(data) > p_col and len(data[p_col]) > p_row and p_col >= 0 and p_row >= 0

func set_cell(p_col: int, p_row: int, p_value):
	assert(has_cell(p_col, p_row)) # It's already onebased!
	if onebased:
		p_col -= 1
		p_row -= 1
	
	data[p_col][p_row] = p_value

func get_cell(p_col: int, p_row: int):
	assert(has_cell(p_col, p_row))
	if onebased:
		p_col -= 1
		p_row -= 1
	
	return data[p_col][p_row]

#func set_cell_if_exists(p_col: int, p_row: int, p_value) -> bool:
#	if onebased:
#		p_col -= 1
#		p_row -= 1
#
#	if has_cell(p_col, p_row):
#		set_cell(p_col, p_row, p_value)
#		return true
#	return false

func has_cellv(p_pos: Vector2) -> bool:
	if onebased:
		p_pos.x -= 1
		p_pos.y -= 1
	
	return len(data) > p_pos.x and len(data[p_pos.x]) > p_pos.y and p_pos.x >= 0 and p_pos.y >= 0

func set_cellv(p_pos: Vector2, p_value):
	assert(has_cellv(p_pos))
	if onebased:
		p_pos.x -= 1
		p_pos.y -= 1
	data[p_pos.x][p_pos.y] = p_value

func get_cellv(p_pos: Vector2):
	assert(has_cellv(p_pos))
	if onebased:
		p_pos.x -= 1
		p_pos.y -= 1
	return data[p_pos.x][p_pos.y]

#func set_cellv_if_exists(p_pos: Vector2, p_value) -> bool:
#	if onebased:
#		p_pos.x -= 1
#		p_pos.y -= 1
#
#	if has_cellv(p_pos):
#		set_cellv(p_pos, p_value)
#		return true
#	return false


func get_col(p_idx: int):
	if onebased: p_idx -= 1
	
	assert(len(data) > p_idx)
	assert(p_idx >= 0)
	return data[p_idx].duplicate()

func get_row(p_idx: int):
	if onebased: p_idx -= 1
	
	var result = []
	for a_col in data:
		assert(len(a_col) > p_idx)
		assert(p_idx >= 0)
		result.push_back(a_col[p_idx])
	return result

#func _get_col_ref(p_idx: int):
##	if onebased: p_idx -= 1 # Private funcs should not be onebaseable
#
#	assert(len(data) > p_idx)
#	assert(p_idx >= 0)
#	return data[p_idx]
#
#func _get_cols() -> Array:
	return data


# I don't like these - it assumes we KNOW what the column/row should be as a whole, which is a screwier way to interact with the dataset than just setting the cells in sequence.
# If necessary, can replace with a 'flood fill' for a given column or row.
# 'onebased' not applied.

func _set_col(p_idx: int, p_col):
	assert(len(data) > p_idx)
	assert(p_idx >= 0)
	assert(len(data) == len(p_col))
	data[p_idx] = p_col

func _set_row(p_idx: int, p_row):
	assert(len(data) > 0 and len(data[0]) > 0)
	assert(len(data) == len(p_row))
	var idx = 0
	for a_col in data:
		assert(len(a_col) > p_idx)
		assert(p_idx >= 0)
		a_col[p_idx] = p_row[idx]
		idx += 1

#func _insert_col(p_idx: int, p_array: Array):
#	if p_idx < 0:
#		data.append(p_array)
#	else:
#		data.insert(p_idx, p_array)
#
#func _insert_row(p_idx: int, p_array: Array):
#	var idx = 0
#	for a_col in data:
#		if p_idx < 0:
#			a_col.append(p_array[idx])
#		else:
#			a_col.insert(p_idx, p_array[idx])
#		idx += 1

#func _append_col(p_array: Array):
#	_insert_col(-1, p_array)
#
#func _append_row(p_array: Array):
#	_insert_row(-1, p_array)
#
#func _sort_col(p_idx: int):
#	_sort_axis(p_idx, true)
#
#func _sort_row(p_idx: int):
#	_sort_axis(p_idx, false)
#
#func _sort_col_custom(p_idx: int, p_obj: Object, p_func: String):
#	_sort_axis_custom(p_idx, true, p_obj, p_func)
#
#func _sort_row_custom(p_idx: int, p_obj: Object, p_func: String):
#	_sort_axis_custom(p_idx, false, p_obj, p_func)

func duplicate() -> Reference:
	return load(get_script().resource_path).new(data)

func hash() -> int:
	return hash(self)

#func shuffle(): # Not a true shuffle; only shuffles WITHIN cols
#	for a_col in data:
#		a_col.shuffle()

#func empty() -> bool:
#	return len(data) == 0


func size() -> int:
	if len(data) <= 0:
		return 0
	return len(data) * len(data[0])

func resize(p_width: int, p_height: int): # One-based no matter what!
	
	data.resize(p_width)
	for i in range(len(data)):
		data[i] = []
		data[i].resize(p_height)

func resizev(p_dimensions: Vector2): # One-based no matter what!
	resize(int(p_dimensions.x), int(p_dimensions.y))

func clear():
	data = []

func fill(p_value):
	for a_col in range(data.size()):
		for a_row in range(data[a_col].size()):
			data[a_col][a_row] = p_value

func _fill_col(p_idx: int, p_value):
	if onebased:
		p_idx -= 1
	
	assert(p_idx >= 0)
	assert(len(data) > p_idx)
	assert(len(data[0]) > 0)
	var arr = []
	for i in len(data[0]):
		arr.push_back(p_value)
	data[p_idx] = arr

func fill_row(p_idx: int, p_value):
	if onebased:
		p_idx -= 1
	
	assert(p_idx >= 0)
	assert(len(data) > 0)
	assert(len(data[0]) > p_idx)
	var arr = []
	for i in len(data):
		arr.push_back(p_value)
	_set_row(p_idx, arr)

#func remove_col(p_idx: int):
#	assert(p_idx >= 0)
#	assert(len(data) > p_idx)
#	data.remove(p_idx)

#func remove_row(p_idx: int):
#	assert(len(data) > 0)
#	assert(p_idx >= 0 and len(data[0]) > p_idx)
#	for a_col in data:
#		a_col.remove(p_idx)

func count_qty_of_param(p_value) -> int:
	var count = 0
	for a_col in data:
		for a_row in a_col:
			if p_value == data[a_col][a_row]:
				count += 1
	return count

func has_any_of_param(p_value) -> bool:
	for a_col in data:
		for a_row in a_col:
			if p_value == data[a_col][a_row]:
				return true
	return false

func invert() -> Reference:
	data.invert()
	return self

func invert_col(p_idx: int) -> Reference:
	if onebased:
		p_idx -= 1
	
	assert(p_idx >= 0 and len(data) > p_idx)
	data[p_idx].invert()
	return self

func invert_row(p_idx: int) -> Reference:
	if onebased:
		p_idx -= 1
	
	assert(len(data) > 0)
	assert(p_idx >= 0 and len(data[0]) > p_idx)
	var row = get_row(p_idx)
	row.invert()
	_set_row(p_idx, row)
	return self

# Haven't applied onebased; not sure I want to

#func bsearch_col(p_idx: int, p_value, p_before: bool) -> int:
#
#	assert(p_idx >= 0 and len(data) > p_idx)
#	return data[p_idx].bsearch(p_value, p_before)
#
#func bsearch_row(p_idx: int, p_value, p_before: bool) -> int:
#
#	assert(len(data) > 0)
#	assert(p_idx >= 0 and len(data[0]) > p_idx)
#	var row = get_row(p_idx)
#	row.sort()
#	return row[p_idx].bsearch(p_value, p_before)

func find(p_value) -> Vector2:
	for a_col in data:
		for a_row in a_col:
			if p_value == data[a_col][a_row]:
				return Vector2(a_col, a_row)
	return Vector2(-1, -1)

func rfind(p_value) -> Vector2:
	var i: int = len(data) - 1
	var j: int = len(data[0]) - 1
	while i:
		while j:
			if p_value == data[i][j]:
				return Vector2(i, j)
			j -= 1
		i -= 1
	return Vector2(-1, -1)

func transpose() -> Reference:
	var height : int = len(data)
	var width : int = len(data[0])
	var transposed_matrix : Array
	for _i in range(width):
		transposed_matrix.append([])
	var h : int = 0
	while h < width:
		for w in range(height):
			transposed_matrix[h].append(data[w][h])
		h += 1
	return load(get_script().resource_path).new(transposed_matrix, false)

# ---

func _to_string() -> String:
	var ret: String = "\n"
	var width: int = len(data)
	var height: int = len(data[0])
	
	var fixedwidth_columns: bool = true # Manually override as relevant
	var fixedwidth_global: bool = true # Ditto; only matters if fixedwidth is true
	var center_columns: bool = true # Ditto; only matters if fixedwidth is true
	var charlengths: Array = []
	var charlenmaster: int = 0
	var maxlen: int = 6
	
	if fixedwidth_columns: # We'll do an EXTRA loop first just to gauge lengths, before our actual write loop
		charlengths.resize(width)
		for h in range(height):
			for w in range(width):
				var t: String = ""
				var value = data[w][h]
#				if value is Node2D:
#					value = value.name
				if (value) != null:
					t = str(value)
					
				var tlen: int = t.length()
				if charlengths[w] == null or charlengths[w] < tlen:
					charlengths[w] = tlen
				if charlenmaster < tlen:
					charlenmaster = tlen
				if charlenmaster > maxlen:
					charlenmaster = maxlen
	
	for h in range(height): # along the row first until each row is clear
		ret += "[ "
		for w in range(width):
			var t: String = ""
			var value = data[w][h]
#			if value is Node2D:
#				value = value.name
			if (value) != null:
				t = str(value)
			if t.length() > maxlen:
				t = t.left(maxlen)
			
			if fixedwidth_columns:
				var tlen: int = t.length()
				# Append as many spaces as necessary to fixedwith!
				var gapmaster: int = charlengths[w]
				if fixedwidth_global:
					gapmaster = charlenmaster
				var tgap: int = gapmaster - tlen
				var flip: bool = false
				for n in tgap:
					if !flip:
						t += " "
					else:
						t = " "+t
					if center_columns: flip = !flip
			
			ret += "[" + t + "]"
			if w == width - 1 and h != height  -1:
				ret += " ]\n"
			else:
				if w == width - 1:
					ret += " ]\n"
				else:
					ret += ", "
#		ret += "]"
	return ret

func _sort_axis(p_idx: int, p_is_col: bool):
	if p_is_col:
		data[p_idx].sort()
		return
	var row = get_row(p_idx)
	row.sort()
	_set_row(p_idx, row)

func _sort_axis_custom(p_idx: int, p_is_col: bool, p_obj: Object, p_func: String):
	if p_is_col:
		data[p_idx].sort_custom(p_obj, p_func)
		return
	var row = get_row(p_idx)
	row.sort_custom(p_obj, p_func)
	_set_row(p_idx, row)
