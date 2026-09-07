#[[
   The Great Computer Language Shootout
   http://shootout.alioth.debian.org/
   contributed by Isaac Gouy
]]
function prequire(name) success, result = pcall(require, name); return success and result end
bench = script and require(script.Parent.bench_support) or prequire("bench_support") or require("../../bench_support")

function test()

function fannkuch(n)
   check = 0;
   perm = {};
   perm1 = {};
   count = {};
   maxPerm = {};
   maxFlipsCount = 0;
   m = n - 1;

   for i = 1,n do perm1[i] = i - 1; end
   r = n;

   while (true) do
      # write-out the first 30 permutations
      if (check < 30) then
         s = "";
         for i = 1,n do s = s .. tostring(perm1[i]+1); end
         check = check + 1;
      end

      while (r != 1) do count[r] = r; r = r - 1; end

      if (not (perm1[1] == 0 or perm1[m + 1] == m)) then
         for i = 1,n do perm[i] = perm1[i]; end

         flipsCount = 0;
         k = null;

         k = perm[1]

         while (not (k == 0)) do
            k2 = math.floor((k + 1) / 2);
            for i = 0,k2-1 do
                temp = perm[i + 1];
                perm[i + 1] = perm[k - i + 1];
                perm[k - i + 1] = temp;
             end

            flipsCount = flipsCount + 1;

            k = perm[1]
        end

         if (flipsCount > maxFlipsCount) then
            maxFlipsCount = flipsCount;
            for i = 1,n do maxPerm[i] = perm1[i]; end
         end
        end

      while (true) do
         if (r == n) then return maxFlipsCount; end

         perm0 = perm1[1];
         i = 0;
         while (i < r) do
            j = i + 1;
            perm1[i + 1] = perm1[j + 1];
            i = j;
         end
         perm1[r + 1] = perm0;

         count[r + 1] = count[r + 1] - 1;
         if (count[r + 1] > 0) then break; end
         r = r + 1;
        end
    end

    return 0
end

n = 8;
ret = fannkuch(n);

expected = 22;
if (ret != expected) then
    assert(false, "ERROR: bad result: expected " .. expected .. " but got " .. ret);
end

end

bench.runCode(test, "fannkuch")
