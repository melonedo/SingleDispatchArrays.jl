module SingleDispatchArrays
export SingleDispatchVector

"Stores all subtypes for a given base type as Basetype => Type{Tuple{Subtypes...}}."
const subtype_dict = Dict()

get_subtypes(basetype) = get(subtype_dict, basetype, Tuple{})
function add_subtype(basetype, new_type)
    old_types = fieldtypes(get_subtypes(basetype))
    if !(new_type in old_types)
        subtype_dict[basetype] = Tuple{old_types..., new_type}
    end
end

"""
    SingleDispatchVector{BaseType} <: AbstractVector
Vector of non-homogenous elements with fast static dispatch table.
!!! note
A full array interface has not been implemented, please use [`index_value_pair`](@ref) to manually manipulate the underlying vector.
"""
mutable struct SingleDispatchVector{T} <: AbstractVector{T}
    vec::Vector{Pair{UInt, T}}
    # Cache of `get_subtypes(basetype)`, only updated when inserting elements of uncached type.
    subtypes::Type
end

SingleDispatchVector{T}() where T = SingleDispatchVector{T}([], get_subtypes(T))

function SingleDispatchVector{T}(vec::AbstractVector{T}) where T
    subtypes = get_subtypes(T)
    pairs = map(vec) do v
        Pair(type_index(subtypes, v), v)
    end
    SingleDispatchVector{T}(pairs, subtypes)
end

basetype(::SingleDispatchVector{T}) where T = T

function generate_dispatch_table(types)
    root_expr = :(if false nothing end)
    cur = root_expr
    for (i, t) in enumerate(types)
        branch = Expr(:elseif, :(ind == $i), :(f(value::$t)))
        push!(cur.args, branch)
        cur = branch
    end
    fallback = :(error("Element $value has invalid type index $ind for basetype $(basetype(a))"))
    push!(cur.args, fallback)
    return root_expr
end


@generated function Base.foreach(f, a::SingleDispatchVector, subtypes::Type{T}) where T
    types = fieldtypes(T)
    dispatch_table = generate_dispatch_table(types)
    return quote
        for (ind, value) in a.vec
            $dispatch_table
        end
    end
end

# Helper function to pass the signature
Base.foreach(f, a::SingleDispatchVector) = foreach(f, a, a.subtypes)


# Too complicated for compiler to fully constant propagation, so the index is directly generated.
@generated function type_index(::Type{Ts}, ::T) where {Ts,T}
    ind = 0
    for (i, t) in enumerate(fieldtypes(Ts))
        if t == T
            ind = i
        end
    end

    return ind
end

function index_value_pair(a::SingleDispatchVector, value)
    # Fast path
    ind = type_index(a.subtypes, value)
    iszero(ind) || return Pair(ind, value)
    # Update subtype set and try again
    a.subtypes = get_subtypes(basetype(a))
    ind = type_index(a.subtypes, value)
    if iszero(ind)
        error("Type $(typeof(value)) is not a recorded subtype of $(basetype(a))")
    else
        Pair(ind, value)
    end
end

# Array interface (very incomplete)
Base.setindex!(a::SingleDispatchVector, val, key) = Base.setindex!(a.vec, index_value_pair(a, val), key)
Base.push!(a::SingleDispatchVector, val) = Base.push!(a.vec, index_value_pair(a, val))
Base.getindex(a::SingleDispatchVector, i) = Base.getindex(a.vec, i)|>last
Base.size(a::SingleDispatchVector) = Base.size(a.vec)
Base.resize!(a::SingleDispatchVector, n) = Base.resize!(a.vec, n)

end # module
