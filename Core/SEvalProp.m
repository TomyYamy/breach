function [S,val] =  SEvalProp(Sys,S,props, tau, ipts, bool_plot, break_level)
%
%   SEVALPROP Eval property for previously computed trajectories
%
%   Usage: [Pf val] = SEvalProp(Sys, Ptraj ,prop,tau, [ ipts, bool_plot, break_level ])
%
%   Inputs:
%
%    - Sys        system
%    - Ptraj      param set with trajectories
%    - prop       property(ies)
%    - tau        time instant(s) when to estimate properties
%    - ipts       trajectories for which to eval properties
%    - bool_plot  side effects plots the values if 1
%    - break_level computes satisfaction of subformulas up to break_level
%
%
%   Outputs:
%
%    - Pf       param set with prop_values field
%    - val      quantitative satisfaction of properties
%

% check arguments


if (~exist('ipts','var')||isempty(ipts))
    ipts = 1:size(S.pts,2);
end

if (~exist('break_level','var'))
    break_level = 0;
end

if (break_level>0)
    nprops = [];
    for i = 1:numel(props)
        nprops =   [nprops QMITL_Break(props(i), break_level) ];
    end
    props = nprops;
end

if ~isfield(S,'props')
    S.props = [];
    npb =0;
else
    npb = numel(S.props);
end

if ~isfield(S,'props_names')
    S.props_names = {} ;
end

if ~isfield(S,'traj_ref')
    S.traj_ref =1:numel(S.traj);
end

if (~exist('tau')||isempty(tau))
    tau0=[];
else
    tau0 = tau;
end

if (~exist('bool_plot'))
    bool_plot = 0;
end

% do things

% setup plots if needed

if (bool_plot)
    figure;
    nb_prop = numel(props);
    if (isfield(Sys,'time_mult'))
        time_mult = Sys.time_mult;
    else
        time_mult=1;
    end
end


for np = npb+1:numel(props)+npb
    
    prop = props(np-npb);
    prop_name =  get_id(prop);
    iprop = find_prop(S,prop_name);
    
    if (bool_plot)
        subplot(nb_prop, 1, np-npb);
        hold on;
        xlabel('tau');
        title(disp(prop), 'Interpreter','none');
    end
    
    if ~iprop
        S.props_names= {S.props_names{:} get_id(prop)};
        S.props= [S.props prop];
        iprop = numel(S.props_names);
    end
    
    prop = QMITL_OptimizePredicates(Sys,prop);
    fprintf(['Checking ' prop_name  '\n[             25%%           50%%            75%%               ]\n ']);
    iprog =0;
    
    Ptmp = Sselect(S,1);
    
    for i = ipts
        while (floor(60*i/numel(ipts))>iprog)
            fprintf('^');
            iprog = iprog+1;
        end
        
        traj = S.traj(S.traj_ref(i));
        Ptmp.pts = S.pts(:,i);
        if (~isempty(tau0))
            S.props_values(iprop,i).tau = tau0;
            S.props_values(iprop,i).val = QMITL_Eval(Sys,prop,Ptmp,traj, tau0);
            val(np-npb,i) =  S.props_values(iprop,i).val(1);
        else
            tau = traj.time;
            S.props_values(iprop,i).tau = traj.time;
            S.props_values(iprop,i).val = QMITL_Eval(Sys,prop,Ptmp, traj, tau);
            val(np-npb,i) =  S.props_values(iprop,i).val(1);
        end
        
        % plot property values
        if (bool_plot)
            phi_tspan = S.props_values(iprop,i).tau;
            phi_val = S.props_values(iprop,i).val;
            plot(phi_tspan*time_mult, phi_val);
            plot([phi_tspan(1) phi_tspan(end)]*time_mult, [0 0],'-k');
            stairs(phi_tspan*time_mult, (phi_val>0)*max(abs(phi_val))/2,'-r');
            grid on;
        end
        
    end
    
    fprintf('\n');
end


function i = find_prop(S,st)

i=0;
for k = 1:numel(S.props_names)
    if strcmp(st,S.props_names{k})
        i = k;
        return;
    end
end