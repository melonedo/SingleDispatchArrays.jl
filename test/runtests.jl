using SingleDispatchArrays
using SingleDispatchArrays: index_value_pair, add_subtype
using Test

@testset "Basic functionality" begin
    struct Point{T}
        x::T
        y::T
    end

    points = SingleDispatchVector{Point}()
    point_types = [Point{Int}, Point{Float32}, Point{Float64}]
    add_subtype.(Point, point_types)
    
    @test_throws ErrorException index_value_pair(points, Point{Bool}(false, false))

    push!(points, Point{Int}(3,4), Point{Float64}(12,5), Point{Float32}(1,0))

    @test_throws ErrorException push!(points, Point{Bool}(false, false))

    sum1 = 0.
    foreach(points) do p
        sum1 += hypot(p.x, p.y)
    end

    sum2 = 0.
    for p in points
        sum2 += hypot(p.x, p.y)
    end

    @test sum1 == sum2

end
