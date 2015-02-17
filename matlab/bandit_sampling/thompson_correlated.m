function [ best_grasp, regret, Value ] = ...
    thompson_correlated(grasp_samples, num_grasps, shapeParams, ...
        experimentConfig, surface_image, vis_bandits)
%THOMPSON_SAMPLING Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 6
        vis_bandits = true;
    end

    Total_Iters = 20000;
    
    i = 1; 
    ts = true; 
    prune = false; 
    regret = zeros(Total_Iters+num_grasps,1); 
    not_sat = true; 
         
    [gram_mat] = calc_correlation(grasp_samples,num_grasps); 
    Storage = {};
    Value = zeros(num_grasps,5); 
    t = 1;
    for i = 1:num_grasps
        grasp_samples{i}.current_iter = 1; 
        [Q] = evaluate_grasp(i,grasp_samples,shapeParams,experimentConfig);
       
        Value(i,1) = 1+Q;
        Value(i,2) = 1+(1-Q); 
        Value(i,3) = (Value(i,1))/(Value(i,1)+Value(i,2)); 
        Value(i,4) = Value(i,3) - 1.96*(1/Value(i,2)*Value(i,3)*(1-Value(i,3)))^(1/2); 
        Value(i,5) = Value(i,3) + 1.96*(1/Value(i,2)*Value(i,3)*(1-Value(i,3)))^(1/2); 

        [v best_grasp] = max(Value(:,3));
        if ts
            regret(t) = compute_regret_pfc(best_grasp);
        else
            regret(t) = 0; 
        end
        t=t+1; 
    end


    i = 1;
    not_sat = true; 
    data = []; 
     while(i<Total_Iters && not_sat)
        %i
        if(ts)
            grasp = get_grasp(Value); 
        elseif(prune)
            np_grasp = not_pruned(Value); 
            grasp_idx = randi(length(np_grasp)); 
            grasp = np_grasp(grasp_idx); 
        else
            grasp = randi(num_grasps);
        end

        [Q, grasp_samples] = evaluate_grasp(grasp,grasp_samples,shapeParams,experimentConfig);

       
        if( Q == -1)
            remaining_time = Total_Iters - i;
            regret(t:end) = regret(t-1);
            Value(grasp,2) = Value(grasp,2) + remaining_time;
            break;
        end

        data = [data; [Q grasp]]; 
        Value = update_correlated_beta(gram_mat,Value,data);
       
        Value(grasp,3) = (Value(grasp,1)+1)/(Value(grasp,1)+Value(grasp,2)); 
        Value(grasp,4) = Value(grasp,3) - 1.96*(1/Value(grasp,2)*Value(grasp,3)*(1-Value(grasp,3)))^(1/2); 
        Value(grasp,5) = Value(grasp,3) + 1.96*(1/Value(grasp,2)*Value(grasp,3)*(1-Value(grasp,3)))^(1/2);

        [v best_grasp] = max(Value(:,3));

        if ts
            regret(t) = compute_regret_pfc(best_grasp);
        else
            regret(t) = 0; 
        end

        i = i+1; 
        t=t+1; 

     end
  
    np_grasp = not_pruned(Value);
    size(np_grasp);

    if vis_bandits
        figure;
        plot(regret)
        title('Simple Regret over Samples'); 
        xlabel('Samples'); 
        ylabel('Simple Regret'); 

        visualize_value( Value,grasp_samples, surface_image )
    end

    if(~ts && ~prune)
        save('marker_bandit_values_pfc','Value');
        %save('regret_marker_pfc_mc','regret','Value');
    elseif(prune)
        save('regret_marker_pfc_sf','regret','Value');
    else
        save('regret_marker_pfc','regret','Value');
    end
end


function [not_pruned_grsp] = not_pruned(Value)
 
 high_low = max(Value(:,4)); 
 not_pruned_grsp = find(high_low < Value(:,5));   

end

function [grasp] = get_grasp(Value)    
   
   A = Value(:,1); 
   B = Value(:,2); 
   
   Sample = betarnd(A,B); 
   
   [v, grasp] = max(Sample); 
   
end


function [Value] = update_correlated_beta(gram_mat,Value,data)
    
    if(data(end,1) == 1)
        Value(:,1) = Value(:,1)+gram_mat(:,data(end,2));
    else
        Value(:,2) = Value(:,2)+gram_mat(:,data(end,2));
    end

end

function [gram_mat] = calc_correlation(grasp_samples,num_grasps) 


gram_mat = eye(num_grasps);
for i=1:num_grasps
    for j=1:num_grasps
        gram_mat(i,j) = rbf_kernel(grasp_samples{i}.cp(:),grasp_samples{j}.cp(:));
    end
end
end




function [val] = rbf_kernel(x_i,x)
sig = 0.0001; 
if(size(x_i,1) ~= size(x,1))
    val = 0; 
else
    val = exp(-norm(x_i-x,2)/sig); 
end

end




