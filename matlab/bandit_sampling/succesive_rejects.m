function [ best_grasp ] = succesive_rejects(grasp_samples,num_grasps,shapeParams,experimentConfig, surface_image  )
%UGABEB Summary of this function goes here
%   Detailed explanation goes here

    Total_Iters = 2000; 
    i = 1; 
    regret = zeros(Total_Iters+num_grasps,1); 
    not_sat = true; 
    a = 1; 
    b = 1; 
    K = num_grasps;
    
    for interval = 1:1
        Storage = {};
        Value = zeros(num_grasps,5); 
        t = 1;
        for i=1:num_grasps
            grasp_samples{i}.current_iter = 1; 
            [Q] = evaluate_grasp(i,grasp_samples,shapeParams,experimentConfig);
      
            
            Value(i,1) = Q;
            Value(i,2) = 1; 
            Value(i,3) = (Value(i,1)+1)/(2+Value(i,2)); 
            Value(i,4) = Value(i,3) - 1.96*(1/Value(i,2)*Value(i,3)*(1-Value(i,3)))^(1/2); 
            Value(i,5) = Value(i,3) + 1.96*(1/Value(i,2)*Value(i,3)*(1-Value(i,3)))^(1/2); 
            
            [v best_grasp] = max(Value(:,3));
            if ts
                regret(t) = (interval-1)/interval*regret(t) + (1/interval)*compute_regret_pfc(best_grasp);
            else
               regret(t) = 0; 
            end
            t=t+1; 
        end


    i = 1
    good_grasps = [1:size(Value,1)]; 
    not_sat = true;
    for idx=2:size(phases)
        for grasp=good_grasps
            for i=1:phases(idx)-phases(idx-1)

                    [Q, grasp_samples] = evaluate_grasp(grasp,grasp_samples,shapeParams,experimentConfig);

                    if(Q == 1)
                        Storage{grasp}.p1 = Storage{grasp}.p1+1;  
                    elseif( Q == -1)
                        not_sat = false; 
                        break;
                    else
                        Storage{grasp}.m1 = Storage{grasp}.m1+1; 
                    end


                    Value(grasp,1) =  Value(grasp,1)+Q; 
                    Value(grasp,2) = Value(grasp,2)+1; 
                    Value(grasp,3) = (Value(grasp,1)+1)/(Value(grasp,2)+2); 
                    Value(grasp,4) = Value(grasp,3) - 1.96*(1/Value(grasp,2)*Value(grasp,3)*(1-Value(grasp,3)))^(1/2); 
                    Value(grasp,5) = Value(grasp,3) + 1.96*(1/Value(grasp,2)*Value(grasp,3)*(1-Value(grasp,3)))^(1/2);

                    [v best_grasp] = max(Value(:,3));

                    regret(t) = (interval-1)/interval*regret(t) + (1/interval)*compute_regret_pfc(best_grasp);
                    
                    i = i+1; 
                    t=t+1; 

            end
        end
        good_grasps = not_pruned(Value); 
        
    end
   
    np_grasp = not_pruned(Value);
    size(np_grasp);
    figure;
    plot(regret)
    title('Simple Regret over Samples'); 
    xlabel('Samples'); 
    ylabel('Simple Regret'); 
    
    visualize_value( Value,grasp_samples, surface_image )
    
    if(~ts && ~prune)
        save('marker_bandit_values_pfc','Value');
        %save('regret_marker_pfc_mc','regret','Value');
    elseif(prune)
        save('regret_marker_pfc_sf','regret','Value');
    else
        save('regret_marker_pfc','regret','Value');
    end
    end
end

function [phases] = compute_phases(K,n)
    phases = zeros(K-1,1); 

    log_K = 1/2; 
    
    for i=2:K
        log_K = log_K + 1/i; 
    end
    phases(1) = 0; 
    for i=2:K-1
        phases(i) = 1/log_K*(n-K)/(K+1-(i-1)); 
    end
   
end

function [not_pruned] = not_pruned(Value,good_grasps)
 
 min_quality = min(Value(good_grasps,3)); 
 not_pruned = find(min_quality > Value(good_grasps,3));


end
   

