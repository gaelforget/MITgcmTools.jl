using MITgcmTools, MeshArrays, OceanStateEstimation
using Test

@testset "MITgcmTools.jl" begin

    #format conversions
    (γ,Γ)=GridOfOnes("CubeSphere",30,30)
    @test isa(convert2gcmfaces(Γ["XC"]),Array)
    @test isa(convert2array(Γ["XC"]),Array)

    #physical oceanography
    (ρP,ρI,ρR) = SeaWaterDensity(3.,35.5,3000.)
    @test isapprox(ρI,1041.83267, rtol=1e-6)

    D=collect(0.0:1.0:500.0); tmp=(1.0.-tanh.(5*(-1 .+ 2/D[end]*D)));
    T=2.0 .+ 8.0*tmp; S=34.0 .+ 0.5*tmp;
    (ρP,ρI,ρR) = SeaWaterDensity(T,S,D);
    mld=MixedLayerDepth(T,S,D,"BM");
    @test isapprox(mld,134.0)

    tmp=testreport("front_relax");
    @test isa(tmp,Base.Process)

    pth=MITgcm_path*"verification/front_relax/run/"
    tmp=read_mdsio(pth,"XC.001.001")
    @test isa(tmp,Array)
    tmp=read_mdsio(pth,"XC")
    @test isa(tmp,Array)

    #read / write functions
    tmp=testreport("advect_cs")
    pth=MITgcm_path*"verification/advect_cs/run/"
    fil=joinpath(pth,"available_diagnostics.log")
    read_available_diagnostics("ETAN";filename=fil)

    readcube(xx::Array,x::MeshArray) = read(cube2compact(xx),x)
    function readcube(fil::String,x::MeshArray) 
        p=dirname(fil)*"/"
        b=basename(fil)[1:end-5]    
        xx=read_mdsio(p,b)
        read(cube2compact(xx),x)
    end
    writecube(x::MeshArray) = compact2cube(write(x))
    writecube(fil::String,x::MeshArray) = write(fil::String,x::MeshArray)
    
    γ=gcmgrid(pth,"CubeSphere",6,fill((32, 32),6), [192 32], Float64, readcube, writecube)
    Γ = GridLoad(γ)
    tmp1=writecube(Γ["XC"])
    tmp2=readcube(tmp1,Γ["XC"])

    @test isa(tmp2,MeshArray)

    ##

    γ=GridSpec("LatLonCap",MeshArrays.GRID_LLC90)
    findtiles(30,30,γ)
    findtiles(30,30,"LatLonCap",MeshArrays.GRID_LLC90)
    read_meta(MeshArrays.GRID_LLC90,"XC.meta")

    fil=joinpath(MeshArrays.GRID_LLC90,"XC.data")
    tmp1=read_bin(fil,γ)
    tmp2=convert2gcmfaces(tmp1)
    tmp3=convert2array(tmp1)
    tmp4=convert2array(tmp3,γ)
    read_bin(fil,γ.ioPrec,γ)
    read_bin(tmp2,tmp1)
    read_bin(tmp2,γ)

    function get_ecco_variable_if_needed(v::String)
        p=dirname(pathof(OceanStateEstimation))
        lst=joinpath(p,"../examples/nctiles_climatology.csv")
        pth=ECCOclim_path
        !isdir(pth*v) ? get_from_dataverse(lst,v,pth) : nothing
    end
    
    get_ecco_variable_if_needed("ETAN")
    tmp=read_nctiles(joinpath(ECCOclim_path,"ETAN/ETAN"),"ETAN",γ,I=(:,:,1))

    @test isa(tmp,MeshArray)

    ##

    tmp=testreport("flt_example")
    pth=MITgcm_path*"verification/flt_example/run/"
    tmp=read_flt(pth,Float32)
    
    @test isa(tmp[1,1],Number)

end