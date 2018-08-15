# Masters-Project-Characterization-of-Reflectors-in-a-Wireless-Channel #

Source code and Master's Portfolio titled: "Characterization of Reflectors in a Wireless Channel to Aid Low-Power Indoor Localization"

## Portfolio ##
* IEEE Conference Style 6-Page Paper
* Full Portfolio (literature review, project plan, testing & results, appendice)

## Source Code ##
### PyVISA ###
  * **SA_CTRL_function.py** : Python class using PyVISA package to communicate with a signal analyzer/FSV
  * **SG_CTRL_function.py** : Python class using PyVISA package to communicate with a signal generator
  * **main_sweep_script.py** : Main script for performing a parallel frequency sweep.

### PDP Hilbert Measurement ###
  * **pdp_gen.m** : Post processes frequency magnitudes obtained during sweep, converting to power delay profiles using the Hilbert filter.
  * includes frequency sweep input data.
  
### Ray Tracing PDP Simulation ###
  * **auditorium_test.m** :  creates simple 2D ray distribution for any specified room geometry and reflector location.
  * also contains classes for modeling AoA reflection etc. for ray tracer
  
### Ray Tracing Reflcetor Prediction ###
  * **pdp_locus.m** : Novel 2D ray tracing using power delay profile delay times to predict the location of a reflector in a wireless channel.
