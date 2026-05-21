function runTrackMPDParallel(conf_name, NbNodes, NodeID)
% RUNTRACKMPDPARALLEL Distributes particle tracking computations across multiple nodes.
% 
% Usage (Local test on 1 PC) : runTrackMPDParallel('input_conf', 3)
% Usage (Cluster, e.g., Node 2) : runTrackMPDParallel('input_conf', 3, 2)

    % Load configuration (handles both string and struct)
    if ischar(conf_name) || isstring(conf_name)
        conf = feval(conf_name);
    elseif isstruct(conf_name)
        conf = conf_name;
    else
        error('First argument must be a config file name or struct.');
    end

    % Get total number of particles
    M_total = dlmread(conf.Data.ParticlesFile, ',', 0, 0);
    NbTotalParticles = size(M_total, 1);

    % Optimized Load Balancing
    BaseSize = floor(NbTotalParticles / NbNodes); 
    Remainder = mod(NbTotalParticles, NbNodes);       


    if nargin < 3
        fprintf('LOCAL: Running %d successive nodes...\n', NbNodes); %TEST EN LOCAL
        node_list = 1:NbNodes;
    else
        fprintf('CLUSTER MODE: Running Node %d out of %d...\n', NodeID, NbNodes);
        node_list = NodeID;
    end

    % 5. Main loop for particle distribution
    for n = node_list
        
        % Calculate exact start index for the current node
        if n <= Remainder
            NodeSize = BaseSize + 1;
            idx_start = (n - 1) * NodeSize + 1;
        else
            NodeSize = BaseSize;
            idx_start = Remainder * (BaseSize + 1) + (n - 1 - Remainder) * BaseSize + 1;
        end

        if NodeSize == 0
            fprintf('Node %d has no particles to process. Skipping.\n', n);
            continue;
        end
        
        idx_end = idx_start + NodeSize - 1;
        indices_to_compute = idx_start:idx_end;
        
        fprintf('\nStarting Node %d (%d particles, indices %d to %d)\n', ...
                n, length(indices_to_compute), idx_start, idx_end);
                
        % Call the modified TrackMPD function
        runTrackMPD(conf, indices_to_compute, n);
        
    end

    disp('All done.');
end