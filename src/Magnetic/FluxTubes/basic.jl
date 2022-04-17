"""
Zero magnetic potential.
"""
function Ground(;name)
    @named port = PositiveMagneticPort()
    eqs = [port.V_m ~ 0]
    ODESystem(eqs, t, [], [], systems=[port], name=name)
end

"""
Idle running branch.
"""
function Idle(;name)
    @named two_port = TwoPort()
    @unpack Phi = two_port
    eqs = [
        Phi ~ 0,
    ]
    extend(ODESystem(eqs, t, [], [], systems=[], name=name), two_port)
end

"""
Short cut branch.
"""
function Short(;name)
    @named two_port = TwoPort()
    @unpack V_m = two_port
    eqs = [
        V_m ~ 0,
    ]
    extend(ODESystem(eqs, t, [], [], systems=[], name=name), two_port)
end

"""
Crossing of two branches.
"""
function Crossing(;name)
    @named port_p1 = PositiveMagneticPort()
    @named port_p2 = PositiveMagneticPort()
    @named port_n1 = NegativeMagneticPort()
    @named port_n2 = NegativeMagneticPort()
    eqs = [
        connect(port_p1, port_p2),
        connect(port_n1, port_n2),
    ]
    ODESystem(eqs, t, [], [], systems=[port_p1, port_p2, port_n1, port_n2], name=name)
end

"""
Constant permeance.

# Parameters:
- `G_m`: [H] Magnetic permeance
"""
function ConstantPermeance(;name, G_m=1.0)
    val = G_m
    @named two_port = TwoPort()
    @unpack V_m, Phi = two_port
    @parameters G_m=G_m
    eqs = [
        Phi ~ G_m * V_m,
    ]
    extend(ODESystem(eqs, t, [], [G_m], name=name), two_port)
end

"""
Constant reluctance.

# Parameters:
- `R_m`: [H^-1] Magnetic reluctance
"""
function ConstantReluctance(;name, R_m=1.0)
    val = R_m
    @named two_port = TwoPort()
    @unpack V_m, Phi = two_port
    @parameters R_m=R_m
    eqs = [
        V_m ~ Phi * R_m,
    ]
    extend(ODESystem(eqs, t, [], [R_m], name=name), two_port)
end

"""
Ideal electromagnetic energy conversion.

# Parameters:
- `N`: Number of turns
"""
function ElectroMagneticConverter(;name, N)
    @named port_p = PositiveMagneticPort()
    @named port_n = NegativeMagneticPort()
    @named p = Pin()
    @named n = Pin()

    sts = @variables v(t) i(t) V_m(t) Phi(t)
    pars = @parameters N=N
    eqs = [
        v ~ p.v - n.v
        0 ~ p.i + n.i
        i ~ p.i
        V_m ~ port_p.V_m - port_n.V_m
        0 ~ port_p.Phi + port_n.Phi
        Phi ~ port_p.Phi
        #converter equations:
        V_m ~ i * N # Ampere's law
        D(Phi) ~ -v / N # Faraday's law
    ]
    ODESystem(eqs, t, sts, pars, systems=[port_p, port_n, p, n], name=name)
end

"""
For modelling of eddy current in a conductive magnetic flux tube.

# Parameters:
- `rho`: [Ohm * m] Resistivity of flux tube material (default: Iron at 20degC)
- `l`: [m] Average length of eddy current path
- `A`: [m^2] Cross sectional area of eddy current path
"""
function EddyCurrent(;name, rho=0.098e-6, l=1, A=1)
    @named two_port = TwoPort()
    @unpack V_m, Phi = two_port
    @parameters R = rho * l / A # Electrical resistance of eddy current path
    eqs = [
        D(Phi) ~ V_m * R,
    ]
    extend(ODESystem(eqs, t, [], [R], name=name), two_port)
end