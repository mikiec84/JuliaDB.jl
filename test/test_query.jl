@testset "getindex" begin
    t = IndexedTable(Columns([1,1,1,2,2], [1,2,3,1,2]), [1,2,3,4,5])
    for n=1:5
        d = distribute(t, n)

        @test d[1,1] == t[1,1]
        @test d[1,3] == t[1,3]
        @test d[2,2] == t[2,2]

        @test gather(d[1:1, 1:1]) == t[1:1, 1:1]
        @test gather(d[1:2, 2:3]) == t[1:2, 2:3]
        # FIXME
        @test_throws ErrorException gather(d[1:2, 4:3])
        @test gather(d[:, 3]) == t[:, 3]
    end
end

@testset "select" begin

    t = IndexedTable(Columns(a=[1,1,1,2,2], b=[1,2,3,1,2]), [1,2,3,4,5])
    for i=[1, 3, 5]
        d = distribute(t, i)

        res = select(t, 1=>x->true, 2=>x->x%2 == 0)
        @test gather(select(d, 1=>x->true, 2=>x->x%2 == 0)) == res
        @test gather(select(d, :a=>x->true, :b => x->x%2 == 0)) == res
    end
end

function Base.isapprox(x::IndexedTable, y::IndexedTable)
    flush!(x); flush!(y)
    all(map(isapprox, x.data.columns, y.data.columns))
end

@testset "convertdim" begin

    t = IndexedTable(Columns(a=[1,1,1,2,2], b=[1,2,3,1,2]),
                     Columns(c=[1,2,3,4,5], d=[5,4,3,2,1]))

    _plus(x,y) = map(+,x, y)

    for i=[2, 3, 5]
        d = distribute(t, i)
        @test gather(convertdim(d, 2, x->x>=2)) == convertdim(t, 2, x->x>=2)
        @test gather(convertdim(d, 2, x->x>=2, agg=_plus)) == convertdim(t, 2, x->x>=2, agg=_plus)
        @test gather(convertdim(d, 2, x->x>=2, vecagg=length)) ==
                convertdim(t, 2, x->x>=2, vecagg=length)
    end
end

@testset "reducedim" begin
    t1 = IndexedTable(Columns([1,1,2,2], [1,2,1,2]), [1,2,3,4])
    rd1 = reducedim(+, t1, 1)
    rd2 = reducedim(+, t1, 2)
    rdv1 = reducedim_vec(length, t1, 1)
    rdv2 = reducedim_vec(length, t1, 2)

    for n=1:5
        d1 = distribute(t1, n)
        @test gather(reducedim(+, d1, 1)) == rd1
        @test gather(reducedim(+, d1, 2)) == rd2

        @test gather(reducedim_vec(length, d1, 1)) == rdv1
        @test gather(reducedim_vec(length, d1, 2)) == rdv2
    end
end

@testset "permutedims" begin
    t = IndexedTable(Columns([1,1,2,2], ["a","b","a","b"]), [1,2,3,4])
    for n=1:5
        d = distribute(t, n)
        @test gather(permutedims(d, [2,1])) == permutedims(t, [2,1])
    end
end
