<!--
The Homeland Security Act of 2002 (Section 305 of PL 107-296, as codified in 6 U.S.C. 185),
 herein referred to as the “Act,” authorizes the Secretary of the U.S. Department of 
 Homeland Security (DHS), acting through the DHS Under Secretary for Science and Technology, 
 to establish one or more federally funded research and development centers (FFRDCs) 
 to provide independent analysis of homeland security issues. MITRE Corporation operates 
 the Homeland Security Systems Engineering and Development Institute (HSSEDI) as an FFRDC 
 for DHS S&T under contract 70RSAT20D00000001. 

The HSSEDI FFRDC provides the government with the necessary systems engineering and 
development expertise to conduct complex acquisition planning and development; concept 
exploration, experimentation and evaluation; information technology, communications 
and cyber security processes, standards, methodologies and protocols; systems 
architecture and integration; quality and performance review, best practices and 
performance measures and metrics; and independent test and evaluation activities. 
The HSSEDI FFRDC also works with and supports other federal, state, local, tribal, 
public and private sector organizations that make up the homeland security enterprise. 
The HSSEDI FFRDC’s research is undertaken by mutual consent with DHS and is 
organized as a set of discrete tasks. This report presents the results of research 
and analysis conducted under:

Task Order 70RSAT20FR0000062
DHS S&T Next Generation Resilient PNT
The results presented in this report do not necessarily reflect official DHS opinion or policy. 

Approved for public release, Case Number 23-4096 / 70RSAT23FR-067-13
-->

# Test Vector Distribution

This is a collection of tools for the generation of baseband RF samples from a GNSS scenario description.

## First Run

This tool includes a Matlab signal generation library called OOsiggen. OOsiggen includes some C++ accelerated Matlab functions which must be compiled before first run. To compile, run the following from a Matlab command window:

```matlab
cd oosiggen
make
```

## Generating Samples

To use the tool, run the `generate_iq` function from within Matlab. Run `help generate_iq` in Matlab for more information on function arguments.

For example:

```matlab
generate_iq('../test_data/tv1/scenario.json', '../iq/tv1', 'data', 5.0e6, 1350)
```
