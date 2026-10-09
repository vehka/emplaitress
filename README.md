# emplaitress
leeloo dallas multiplaits

This is a Norns mod that gives you access with `nb` to four copies of the Mutable Instruments Plaits code. 

`;install https://github.com/sixolet/emplaitress`

Turn on the mod

Then restart. The mod gets the Mutable Instruments UGens the first time it
loads and shows an installer screen; press K3 on the "restart needed" screen
to restart once more.

- On norns and shields (32-bit) it downloads prebuilt UGens.
- Everywhere else (64-bit shields, desktop norns, norns on Termux) it builds
  `MiPlaits` from [mi-UGens](https://github.com/v7b1/mi-UGens) on the machine,
  after installing git, cmake, make, a C++ compiler and the SuperCollider
  headers if they are missing. This takes a few minutes.

If neither works the screen says what is missing; build mi-UGens by hand into
`~/.local/share/SuperCollider/Extensions`. Until the UGens are there the mod
loads quietly and the voices stay silent.
