function [scaling_factors, gaussian_means, covariances] = trainGMM(orange_pixels, k)
    %set epsilon/ tau to something else
    tau = 0;

    % initialization step: we randomly choose the coefficients
    % coefficients: [mu, Sigma, pi]
    % initialize pi_i to be 1/k
    scaling_factors = ones(k,1)/k;
    %get the means and covariances of the clusters
    [gaussian_means, covariances] = clusterParameters(orange_pixels, k);
    prev_means = gaussian_means;

    n = size(orange_pixels);
    n = n(1);
    split_amount = floor(n/k);
    alphas = zeros(n,1);
    % set max_iters to something else or change the condition of the while
    % to 1 (true)
    itr = 0;
    max_iters = 10000;
    while(itr < max_iters)
        % Expectation step / E-step
        % find alphas (store as 1xn vector)
        for j = 1:n
            i = ceil(j/k); 
            x = orange_pixels(j);
            S = covariances(i);
            pi_i = scaling_factors(i);
            mu = gaussian_means(i);
            alpha_ij = pi_i*exp(-0.5*transpose(x - mu)*(S\(x-mu)))/sqrt(det(S)*(2*pi)^3);
            alpha_denom = alphaDenominator(scaling_factors,gaussian_means, covariances, k, x);
            alpha_ij = alpha_ij/alpha_denom;
            alphas(i) = alpha_ij;
        end
        % Maximization step / M-step
        % update the values (want to maintain matrix/vector structures)
        updated = 0;
        for i = 1:k
            gaussian_means(i) = sum(transpose(alphas).*orange_pixels)/sum(alphas);
            covariances(i) = covarianceNumerator(alphas, orange_pixels,gaussian_means(i))/sum(alphas);
            if i < k
                scaling_factors(i) = sum(alphas(updated + 1: updated + split_amount))/n;
                updated = updated + split_amount;
            else
                scaling_factors(i) = sum(alphas(updated + 1: n))/n;
            end
        end
        if(abs(sum(sum(prev_means)) - sum(sum(gaussian_means))) <= tau)
            break;
        end
        prev_means = gaussian_means;
        itr = itr + 1;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gets the means and covariances of the clusters
% splits the data into k clusters
% returns the means (kx1x3) and covariances (kx3x3) of the clusters
function [gaussian_means, covariances] = clusterParameters(orange_pixels, k)
    % declaration and initialization of variables to 0
    gaussian_means = zeros(1,3);
    covariances = zeros(3,3);
    for i = 2:k
        gaussian_means(:,:,i) = zeros(1,3);
        covariances(:,:,i) = zeros(3,3);
    end
    split_amount = size(orange_pixels);
    total = split_amount(1);
    gathered = 0;
    split_amount = floor(total/k);
    for i = 1:k
        if(i < k)
            temp_mean = mean(orange_pixels(gathered + 1:gathered + split_amount,:));
            temp_cov = cov(orange_pixels(gathered + 1:gathered + split_amount,:));
        else 
            temp_mean = mean(orange_pixels(gathered + 1:total,:));
            temp_cov = cov(orange_pixels(gathered + 1:total,:));
        end  
        gathered =  gathered + split_amount;
        gaussian_means(:,:,i) = temp_mean;
        covariances(:,:,i) = temp_cov;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function total  = alphaDenominator(scaling_factors,gaussian_means, covariances, k, x)
    total = 0;
    for i = 1:k
        S = covariances(i);
        mu = gaussian_means(i);
        total = total + scaling_factors(i)*exp(-0.5*transpose(x - mu)*(S\(x-mu)))/sqrt(det(S)*(2*pi)^3);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function total = covarianceNumerator(alphas, orange_pixels,mu_i)
    total = zeros(3,3);
    n = size(orange_pixels);
    for i = 1:n
        xj = orange_pixels(i);
        temp = xj - mu_i;
        total = totals + alphas(i)*temp*transpose(temp);
    end
end
