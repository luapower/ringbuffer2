local rb = require'ringbuffer2'
local ffi = require'ffi'
local rand = math.random
io.stdout:setvbuf'no'

local b = rb.cdatabuffer{ctype = 'char', size = 5, read = function() end}

local function randstr(n)
	return string.char(rand(('A'):byte(), ('Z'):byte())):rep(n)
end

math.randomseed(os.time())

for i= 1,b.size do b.data[i-1] = string.byte('.') end
for i = 1, 15 do
	local cmd, s, n
	repeat
		if rand() > .5 then
			cmd = 'push'
			local free = b.size - b.length
			n = math.floor(rand(-free, free))
			s = randstr(math.abs(n))
			b:push(ffi.cast('const char*', s), n)
		else
			cmd = 'pull'
			local len = b.length
		 	n = math.floor(rand(-len, len))
		 	s = nil
			b:pull(nil, n)
		end
	until n ~= 0
	local i1, n1, i2, n2 = rb.free_segments(b.start+1, b.length, b.size)
	if n1 < 0 then
		i1, n1 = i1 + n1 + 1, -n1
		i2, n2 = i2 + n2 + 1, -n2
	end
	for i= 1,n1 do b.data[i1-1+i-1] = string.byte('.') end
	for i= 1,n2 do b.data[i2-1+i-1] = string.byte('.') end
	local ds = ffi.string(b.data, b.size)
	local i1, n1, i2, n2 = rb.segments(b.start+1, b.length, b.size)
	print(string.format('%s %s %3d: %2d+%2d, %2d+%2d  %s', ds, cmd, n, i1, n1, i2, n2, s or ''))
end
