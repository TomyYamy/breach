function params_u = FindParamsInput(Sys)

InputNames = Sys.InputList;
U = Sys.init_u(InputNames, [], []);
params_u= U.params;