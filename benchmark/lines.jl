# https://discourse.julialang.org/t/union-splitting-vs-c/61772/20
module Lines

using BenchmarkTools
using Test
using SingleDispatchArrays

abstract type AbstractLine end

for T in [:Line1, :Line2, :Line3, :Line4, :Line5]
    @eval begin
        struct $T <:AbstractLine
            length::Float64
        end
        paint(l::$T) = l.length
    end
end

struct Picture{T<:AbstractLine}
       lines::Vector{T}
end

# Dynamical dispatch at runtime

function paint1(p)
  s = 0.
  for l in p.lines
    s += paint(l)
  end
  s
end

# Union splitting

function paint2(p)
  s = 0.
  for l in p.lines
    if l isa Line1
      s += paint(l)
    elseif l isa Line2
      s += paint(l)
    elseif l isa Line3
      s += paint(l)
    elseif l isa Line4
      s += paint(l)
    elseif l isa Line5
      s += paint(l)
    end
  end
  s
end

function paint3(a::SingleDispatchVector)
    # Will be lowered to `Core.Box` if s is not constant
    s = Ref(0.)
    foreach(a) do l
        s[] += paint(l)
    end
    s[]
end


function run(n)

  line_types = [ Line1, Line2, Line3, Line4, Line5 ]
  p = Picture([line_types[rand(1:5)](rand()) for i in 1:n])
  
  SingleDispatchArrays.add_subtype.(AbstractLine, line_types)
  a = SingleDispatchVector{AbstractLine}(p.lines)
  
  @test paint1(p) ≈ paint3(a)
  println("result = ", paint1(p))

  print(" with runtime dispatch: "); @btime paint1($p)
  print(" with splitting: "); @btime paint2($p)
  print(" with SingleDispatchArrays.jl: "); @btime paint3($a)
end

end

# running
Lines.run(1_000_000)