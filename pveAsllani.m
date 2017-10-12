function [imFil,imMap,errRes] = pveAsllani(pvGM,pvWM,pvCSF,imASL,opt)

% pvGM, pvWM, pvCSF - the partial volumes between 0 and 1
%    you can put [] instead of pvCSF
% imASL - the CBF image in mL/min/100g
% opt - is set automatically, you only need to specify the filter size
% opt.wS = 1 is 3x3
% opt.wS = 2 is 5x5 etc.
% imMap(:,:,:,1) = CBF-WM
% imMap(:,:,:,2) = CBF-GM
% imFil - 'filtered' image - when you multiply the partial volumes with the
%         'density' CBF maps for each tissue type
% errRes - difference between imFil and imASL - it should in theory contain
%          only noise, but there will be a plenty of structure because the 
%          partial volume is not perfect

if (~isfield(opt,'totPthreshold'))
    opt.totPthreshold = 0.1;
end;

% There has to be at least 'opt.rankNum' of pixels with partial volume 
% higher than 'opt.rankTh' to compute the inversion
if (~isfield(opt,'rankNum'))
    opt.rankNum = 2;
end;

if (~isfield(opt,'pvTh'))
    opt.pvTh = 0.01;
end;

if (~isfield(opt,'resMin'))
    opt.resMin = 0;
end;

if (~isfield(opt,'resMax'))
    opt.resMax = 250;
end;

if (isempty(pvCSF))
    pvP = pvWM + pvGM;
    useCSF = 0;
    opt.rankTh = 0.01;
else
    pvP = pvWM + pvGM + pvCSF;
    useCSF = 1;
    opt.rankTh = 0.1;
end;

% Creates a mask of the region covered by tissue
imMask = pvP > opt.pvTh;
pvP(imMask == 0) = 1;

% In case the total partial volume exceedes 1, it is normalized
pvPnorm = pvP;
pvPnorm(pvPnorm < 1) = 1;
pvGM = pvGM./pvPnorm;
pvWM = pvWM./pvPnorm;
useCSF=0;
if (useCSF)
    pvCSF = pvCSF./pvPnorm;
end;
pvP = pvP./pvPnorm;

clear imP;
imASL = imASL.*imMask;
pvGM  = pvGM.*imMask;
pvWM  = pvWM.*imMask;

% Setting of the parameters for the lsqlin function
optLsqlin = optimset('Display','off','TolX',0.01,'TolFun',0.01,'FunValCheck','off','MaxIter',30);

% Creates the empty images for the tissue specific magnetization
imGM = zeros(size(pvGM));
imWM = zeros(size(pvWM));
if (useCSF)
    imCSF = zeros(size(pvCSF));
end;
%tic
% For each pixel on the mask do the calculation
for z=1:size(imASL,3)
    for y = (opt.wS+1):(size(imASL,2)-opt.wS)
        for x = (opt.wS+1):(size(imASL,1)-opt.wS)
            if imMask(x,y,z)
                % Version with CSF
                if (useCSF)
                    % Create the system of equations
                    PMat = [ pvGM((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z),...
                             pvWM((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z),...
                            pvCSF((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z)];
                    PMat = reshape(PMat,[(2*opt.wS+1)^2,3]);
                    
                    % The vector of solutions of the equations is:
                    ASLMat = imASL((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z);
                    ASLMat = ASLMat(:);
                    
                    % Remove the parts with low pvGM+pvWM+pvCSF
                    ind = PMat > opt.pvTh;
                    PMat = PMat(ind,:);
                    ASLMat = ASLMat(ind,:);
                    
                    res = [0 0 0];
                    
                    % Calculate only for patches containing enough tissue
                    if (sum(abs(PMat(:))) > opt.totPthreshold)
                         
                        % The rank of the matrix is high enough -> we can compute the inversion directly
                        if ( ((rank(PMat))>=3) &&...  % The matrix has to have rank 3
                             (sum(PMat(:,1)>opt.rankTh)>=opt.rankNum) && .../ / % At least several pixels with highenough partial volume ratio
                             (sum(PMat(:,2)>opt.rankTh)>=opt.rankNum) && .../
                             (sum(PMat(:,3)>opt.rankTh)>=opt.rankNum) ) 
                         
                             res = pinv(PMat)*ASLMat;
                             % In case there are too high values or negative values in the solution then perform 
                             % a restricted solution...
                             if sum( (res>opt.resMax) + (res<opt.resMin) )
                                 res(res<opt.resMin) = opt.resMin;
                                 res(res>opt.resMax) = opt.resMax;
                                 res = lsqlin(PMat,ASLMat,[],[],[],[],[opt.resMin,opt.resMin,opt.resMin],.../
                                 [opt.resMax,opt.resMax,opt.resMax],res,optLsqlin);
                             end;
                             
                        % Otherwise we have to discard the least involved tissue type
                        else
                            % Get the tissue with the lowest total partial volume in the patch
                            % And discard it putting its magnetization to zero
                            [val,disc1] = min(sum(abs(PMat),1),[],2);
                            disc1 = disc1(1);
                            inGame = [1:(disc1-1),(disc1+1):3];
                            PMat2 = PMat(:,inGame);
                            res(disc1) = 0;
                            
                            if ( ((rank(PMat2)) >= 2) &&...
                                 (sum(PMat2(:,1) > opt.rankTh) >= opt.rankNum) &&...
                                 (sum(PMat2(:,2) > opt.rankTh) >= opt.rankNum) &&...
                                 (sum(ASLMat>opt.aslTh)>=3))
                                res(inGame) = pinv(PMat2)*ASLMat;
                                
                                % In case there are too high values or negative values in the 
                                % solution then perform a restricted solution...
                                if sum( (res>opt.resMax) + (res<opt.resMin) )
                                    res(res<opt.resMin) = opt.resMin;
                                    res(res>opt.resMax) = opt.resMax;
                                    res = lsqlin(PMat,ASLMat,[],[],[],[],[opt.resMin,opt.resMin],.../
                                        [opt.resMax,opt.resMax],res,optLsqlin);
                                end;
                            else
                                % Otherwise assume there is only one tissue model on the patch
                                [val,disc] = min(sum(abs(PMat2),1),[],2);
                                disc = disc(1);
                                disc2 = inGame(disc);
                                res(disc2) = 0;
                                inGame = inGame([1:(disc-1),(disc+1):2]);
                                PMat2 = PMat(:,inGame);
                                PMat2 = sum(PMat2(:));
                                ASLMat2 = sum(ASLMat(:));
                                res(inGame) = ASLMat2./PMat2;
                             end;
                         end;
                         imGM(x,y,z) = res(1);
                         imWM(x,y,z) = res(2);
                         imCSF(x,y,z) = res(3);
                     end;
                
                else % Version without CSF
                    PMat = [pvGM((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z),...
                            pvWM((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z)];
                    PMat = reshape(PMat,[(2*opt.wS+1)^2,2]);
                    
                    ASLMat = imASL((x-opt.wS):(x+opt.wS),(y-opt.wS):(y+opt.wS),z);
                    ASLMat = ASLMat(:);
                    
                    % Remove the parts with low pvGM+pvWM
                    ind = sum(PMat,2) > opt.pvTh;
                    PMat = PMat(ind,:);
                    ASLMat = ASLMat(ind,:);
                    
                    if (sum(abs(PMat(:)))>opt.totPthreshold)
                        res = [0 0];
                        failed = 1;
                        if ( (sum(PMat(:,1) > opt.rankTh) >= opt.rankNum) && (sum(PMat(:,2) > opt.rankTh) >= opt.rankNum) )
                            % Compute the Matrix rank of PMat
                            [PMatu,PMats,PMatv] = svd(PMat,0);
                            PMatds = diag(PMats);
                            PMattol = max(size(PMat)) * eps(max(PMatds));
                            PMatr = sum(PMatds > PMattol);
                                                        
                            if PMatr >= 2
                                failed = 0;
                                
                                PMats = diag(1./PMatds);
                                res = (PMatv*PMats*PMatu')*ASLMat;

                                % In case of negative result we set the
                                % lower value to zero and calculate
                                % ordinary least square for the second
                                if sum (res<opt.resMin)
                                    [val,ind] = sort(res);
                                    ind2 = ind(1);
                                    ind = ind(2);
                                    ASLMatx = ASLMat - PMat(:,ind2)*opt.resMin;
                                    res(ind) = (ASLMatx'*PMat(:,ind))/(PMat(:,ind)'*PMat(:,ind));
                                    res(ind2) = opt.resMin;
                                end;
                                
                                % In case there are too high values or negative values in the solution then perform a restricted solution...
                                if sum(res>opt.resMax)
                                    res = min(opt.resMax,res);
                                    res = lsqlin(double(PMat),double(ASLMat),[],[],[],[],[opt.resMin,opt.resMin],[opt.resMax,opt.resMax],...
                                        double(res),optLsqlin);
                                end;

                            end;
                        end;
                        if failed
                            [val,ind] = max(sum(abs(PMat),1),[],2);
                            ind = ind(1);
                            if (sum(PMat(:,ind),1) > opt.rankTh)
                                res(ind) = sum(ASLMat.*PMat(:,ind))/sum(PMat(:,ind).^2);
                            end;
                        end;
                        imGM(x,y,z) = res(1);
                        imWM(x,y,z) = res(2);
                    end;
                end;

            end;
        end
    end
end;
%toc
% Create the results
if (useCSF)
    imFil = imWM.*pvWM + imGM.*pvGM + imCSF.*pvCSF;
        
    imMap = zeros([size(imGM,1),size(imGM,2),size(imGM,3),3]);
    imMap(:,:,:,1) = imWM;
    imMap(:,:,:,2) = imGM;
    imMap(:,:,:,3) = imCSF;
else
    imFil = imWM.*pvWM + imGM.*pvGM;
        
    imMap = zeros([size(imGM,1),size(imGM,2),size(imGM,3),2]);
    imMap(:,:,:,1) = imWM;
    imMap(:,:,:,2) = imGM;
end;

errRes = imMask.*(abs(imFil-imASL));

return;
