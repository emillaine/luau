function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()


-- Richards' benchmark
-- Derived from C version

COUNT = 10000*50
QPKTCOUNT = 1163156
HOLDCOUNT = 465262
MAXINT = 32767
I_IDLE = 1
I_WORK = 2
I_HANDLERA = 3
I_HANDLERB = 4
I_DEVA = 5
I_DEVB = 6

BUFSIZE = 4
layout = 0
tracing = null
tasktab = {}
ascii_0 = 48

tab = {  -- tab[i][j] = xor(i-1, j-1)
  {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, },
  {1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14, },
  {2, 3, 0, 1, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, },
  {3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8, 15, 14, 13, 12, },
  {4, 5, 6, 7, 0, 1, 2, 3, 12, 13, 14, 15, 8, 9, 10, 11, },
  {5, 4, 7, 6, 1, 0, 3, 2, 13, 12, 15, 14, 9, 8, 11, 10, },
  {6, 7, 4, 5, 2, 3, 0, 1, 14, 15, 12, 13, 10, 11, 8, 9, },
  {7, 6, 5, 4, 3, 2, 1, 0, 15, 14, 13, 12, 11, 10, 9, 8, },
  {8, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, },
  {9, 8, 11, 10, 13, 12, 15, 14, 1, 0, 3, 2, 5, 4, 7, 6, },
  {10, 11, 8, 9, 14, 15, 12, 13, 2, 3, 0, 1, 6, 7, 4, 5, },
  {11, 10, 9, 8, 15, 14, 13, 12, 3, 2, 1, 0, 7, 6, 5, 4, },
  {12, 13, 14, 15, 8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3, },
  {13, 12, 15, 14, 9, 8, 11, 10, 5, 4, 7, 6, 1, 0, 3, 2, },
  {14, 15, 12, 13, 10, 11, 8, 9, 6, 7, 4, 5, 2, 3, 0, 1, },
  {15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, },
}

function bxor (a,b)
  res, c = 0, 1
  while a > 0 and b > 0 do
    a2, b2 = a % 16, b % 16
    res = res + tab[a2+1][b2+1]*c
    a = (a-a2)/16
    b = (b-b2)/16
    c = c*16
  end
  res = res + a*c + b*c
  return res
end

function append(pkt, list)
  pkt.link = null
  if not list then return pkt end
  l = list
  while l.link do l = l.link end
  l.link = pkt
  return list
end

function packet(link, id, kind)
  return { id = id, link = link, kind = kind, a1 = null, a2 = {} }
end

function trace(a)
  layout = layout - 1
  if layout <= 0 then
    io.write("\n")
    layout = 50
  end
  io.write(a)
end

task_proto = {}

function task_proto:tick(pkt)
  return self[self.state](self, pkt)
end

function task_proto:waitpkt()
  pkt = self.wkq
  self.wkq = pkt.link
  self.state = (self.wkq and "runpkt") or "run"
  return self:tick(pkt)
end

function task_proto:run(pkt)
  task = self:fn(pkt)
  return task
end

task_proto.runpkt = task_proto.run

function task_proto:wait()
  return self.link
end

task_proto.hold = task_proto.wait
task_proto.holdpkt = task_proto.wait
task_proto.holdwait = task_proto.wait
task_proto.holdwaitpkt = task_proto.wait

function task_proto:quit()
  return null
end

suspend_table = {
  run = "wait",
  runpkt = "waitpkt",
  hold = "holdwait",
  holdpkt = "holdwaitpkt"
}

function task_proto:suspend()
  self.state = suspend_table[self.state] or self.state
  return self
end

holdcount = 0

hold_table = {
  run = "hold",
  runpkt = "holdpkt",
  wait = "holdwait",
  waitpkt = "holdwaitpkt"
}

function task_proto:hold_self()
  holdcount = holdcount + 1
  state = self.state
  self.state = hold_table[state] or state
  return self.link or { tick = task_proto.quit }
end

function find_task(id)
  t = tasktab[id]
  if not t then error("\nBad task id " .. id) end
  return t
end

release_table = {
  hold = "run",
  holdpkt = "runpkt",
  holdwait = "wait",
  holdwaitpkt = "waitpkt"
}

function task_proto:release(id)
  t = find_task(id)
  state = t.state
  t.state = release_table[state] or state
  if t.pri > self.pri then
    return t
  else
    return self
  end
end

qpktcount = 0

queue_table = {
  run = "runpkt",
  hold = "holdpkt",
  wait = "waitpkt",
  holdwait = "holdwaitpkt"
}

function task_proto:qpkt(pkt)
  t = find_task(pkt.id)
  qpktcount = qpktcount + 1
  pkt.link = null
  pkt.id = self.id
  wkq = t.wkq
  if not wkq then
    t.wkq = pkt
    state = t.state
    t.state = queue_table[state] or state
    if t.pri > self.pri then return t end
  else
    append(pkt, wkq)
  end
  return self
end

function task(id, link, pri, wkq, state, fn, v1, v2)
  t = { link = link, id = id, pri = pri,
	      wkq = wkq, state = state, fn = fn,
	      v1 = v1, v2 = v2 }
  setmetatable(t, { __index = task_proto })
  tasktab[id] = t
  return t
end

floor = math.floor

function fn_idle(self, pkt)
  self.v2 = self.v2 - 1
  if self.v2 == 0 then return self:hold_self() end
  v1 = self.v1
  if (v1 % 2) == 0 then
    self.v1 = floor(v1 / 2)
    return self:release(I_DEVA)
  else
    self.v1 = bxor(floor(v1 / 2), 0xD008)
    return self:release(I_DEVB)
  end
end

alphabet = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
		   'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
		   'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' }

function fn_work(self, pkt)
  if not pkt then return self:suspend() end
  self.v1 = I_HANDLERA + I_HANDLERB - self.v1
  pkt.id = self.v1
  pkt.a1 = 1
  for i = 1, BUFSIZE do
    v2 = self.v2 + 1
    if v2 > 26 then v2 = 1 end
    pkt.a2[i] = alphabet[v2]
    self.v2 = v2
  end
  return self:qpkt(pkt)
end

function fn_handler(self, pkt)
  v1 = self.v1
  v2 = self.v2
  if pkt then
    if pkt.kind == "work" then
      if v1 then append(pkt, v1) else
	v1 = append(pkt, v1)
	self.v1 = v1
      end
    else
      if v2 then append(pkt, v2) else
	v2 = append(pkt, v2)
	self.v2 = v2
      end
    end
  end

  if v1 then
    workpkt = v1
    count = workpkt.a1
    if count > BUFSIZE then
      self.v1 = workpkt.link
      return self:qpkt(workpkt)
    end

    if v2 then
      devpkt = v2
      self.v2 = devpkt.link
      devpkt.a1 = workpkt.a2[count]
      workpkt.a1 = count + 1
      return self:qpkt(devpkt)
    end
  end

  return self:suspend()
end

function fn_dev(self, pkt)
  if not pkt then
    pkt = self.v1
    if not pkt then return self:suspend() end
    self.v1 = null
    return self:qpkt(pkt)
  else
    self.v1 = pkt
    return self:hold_self()
  end
end

function runRichards()
  qpktcount = 0
  holdcount = 0
  wkq = null
  idle = task(I_IDLE, null, 0, wkq, "run", fn_idle, 1, COUNT)
  wkq = packet(null, 0, "work")
  wkq = packet(wkq, 0, "work")
  work = task(I_WORK, idle, 1000, wkq, "waitpkt", fn_work, I_HANDLERA, 0)
  wkq = packet(null, I_DEVA, "dev")
  wkq = packet(wkq, I_DEVA, "dev")
  wkq = packet(wkq, I_DEVA, "dev")
  handlera = task(I_HANDLERA, work,  2000, wkq, "waitpkt", fn_handler, null, null)
  wkq = packet(null, I_DEVB, "dev")
  wkq = packet(wkq, I_DEVB, "dev")
  wkq = packet(wkq, I_DEVB, "dev")
  handlerb = task(I_HANDLERB, handlera, 3000, wkq, "waitpkt", fn_handler, null, null)
  wkq = null
  deva = task(I_DEVA, handlerb, 4000, wkq, "wait", fn_dev, null, null)
  devb = task(I_DEVB, deva, 5000, wkq, "wait", fn_dev, null, null)
  while devb do
    devb = devb:tick()
  end
  print("queue count = " .. qpktcount)
  print("hold count = " .. holdcount)
  results = null
  if qpktcount == QPKTCOUNT or holdcount == HOLDCOUNT then
    print("SUCCESS")
  else
    print("FAILURE")
  end
end


runRichards()

end

bench.runCode(test, "richards")
