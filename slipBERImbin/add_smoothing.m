function [revised_kernel, revised_obs] =...
    add_smoothing (kernel, obs, model1, model2, model3, model4, smoothing_factor, n_datasets)

% function [revised_kernel, revised_obs] =
%   add_smoothing (kernel, obs, model, smoothing_factor, n_datasets)
%
% This function takes an already existing kernel and observation
% set, and adds a Laplacian-minimising smoothing operation to it.
% A spatial model, generated by 'process_faultdata' gives the
% relation between neighbouring fault patches, including their
% dimensions, necessary for the calculations. The Laplacian
% operator is scaled by a 'smoothing factor' which regulates how
% oscillatory the solution is allowed to be.
%
%
% find dimensions of the fault model...
%
% Thanks to G. Funning
% Funning, G. J., B. Parsons, T. J. Wright, J. A. Jackson, and E. J. 
% Fielding (2005), Surface displacements and source parameters of the 2003 
% Bam (Iran) earthquake from Envisat advanced synthetic aperture radar 
% imagery, J. Geophys. Res., 110, B09406, doi: 10.1029/2004JB003338.


[z,r]=size(model1) ;

% ...and its number of elements

m=sum(sum(model4~=-1)) ;

% find the number of observations and kernel columns

n_obs=length(obs) ;
[n_kerrows,n_kercols]=size(kernel) ;

% set up the new, revised kernel matrix

revised_kernel=zeros(n_obs+m,n_kercols) ;
revised_kernel(1:n_obs,1:n_kercols)=kernel ;

% and a revised observation vector

revised_obs=zeros(n_obs+m,1) ;
revised_obs(1:n_obs)=obs ;

% and finally, set a counting variable to zero

j=0 ;

% cycle through each fault segment with a nested loop
% - first set up a down-dip loop

for k=1:z
    
% and then an along-strike loop
    
    for i=1:r
        
% check to see if there is a fault here...

%	disp(['row ' num2str(k) ' column ' num2str(i) ' spatial_model4 ' num2str(model4(k,i))]) 


       if(model4(k,i)~=-1)

% increment counter

           j=j+1;
        
%           disp(['k ' num2str(k) ' i ' num2str(i) ' j ' num2str(j)]);
        
% generate second derivative calculation in down-dip 
% direction

% check not at edge of the fault - only smooth the middle
% (for now, at least)

           if ((k>1) & (k<z))
           
% divide calculation into 3 chunks to simplify matters 

% the contribution of the centre patch

               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   (-2)*smoothing_factor/(model3(k,i)^2) ;

% if there is a patch above...
 
	       if (model4(k-1,i)~=-1)

% ...you need the contribution of the patch above            
            
               revised_kernel(n_obs+model1(k,i),model1(k-1,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k-1,i))+...
                   smoothing_factor/(model3(k,i)^2) ;


               end


% and if there is a patch below...
 
	       if (model4(k+1,i)~=-1)                       
            
% you need its contribution too

               revised_kernel(n_obs+model1(k,i),model1(k+1,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k+1,i))+...
                   smoothing_factor/(model3(k,i)^2) ;


                end

% and if you're at the top row, you need to do the same thing

           elseif (k==1)
            
% as before, calculations will be divided into chunks            

%  the patch above has no contribution
            
% but the centre patch does

               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   (-2)*smoothing_factor/(model3(k,i)^2) ;
            
% and the patch below, too

               revised_kernel(n_obs+model1(k,i),model1(k+1,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k+1,i))+...
                   smoothing_factor/(model3(k,i)^2) ;

% and if you're at the bottom row, you need to do the same thing

           elseif ( ((k>1) & (k==z)) )
            
% as before, calculations will be divided into chunks            

% first, the contribution of the patch above            
            
               revised_kernel(n_obs+model1(k,i),model1(k-1,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k-1,i))+...
                   smoothing_factor/(model3(k,i)^2) ;
            
% next, the contribution of the centre patch

               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   (-2)*smoothing_factor/(model3(k,i)^2) ;
            
% and the patch below, of course, has no contribution

            end    
    
        
% generate second derivative calculation in along-strike
% direction

% check not at edge of the spatial model - only smooth the middle
% (for now at least)


            if (i>1) & (i<r)
            
% check that we are not on a boundary between affiliated fault segments

% the segment before?

               if ((model4(k,i-1))~=(model4(k,i)))


 % calculate spacings between patches
            
                  deltax1(j)=model2(k,i) ;
                  deltax2(j)=0.5*(model2(k,i)+model2(k,i+1)) ;
                  deltaxsum(j)=deltax1(j)+deltax2(j) ;
            
% divide calculation into chunks as before
            
% the patch before, of course, has no contribution
            
% the contributions of the centre patch...

                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;

% and finally, the contribution of the patch after

                  revised_kernel(n_obs+model1(k,i),model1(k,i+1))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i+1))+...
                      (2*smoothing_factor)/(deltax2(j)*deltaxsum(j));


% the segment after?

               elseif ( (model4(k,i)) ~= (model4(k,i+1)) )

% calculate spacings between patches
            
                  deltax1(j)=0.5*(model2(k,i-1)+model2(k,i)) ;
                  deltax2(j)=model2(k,i) ;
                  deltaxsum(j)=deltax1(j)+deltax2(j) ;

            
% first, the contribution of the patch before

                  revised_kernel(n_obs+model1(k,i),model1(k,i-1))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i-1))+...
                      (2*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
% next, the contributions of the centre patch

                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;

% and the patch after has no contribution...



% not at a boundary? well proceed as normal, then

               else

% calculate spacings between patches
            
                  deltax1(j)=0.5*(model2(k,i-1)+model2(k,i)) ;
                  deltax2(j)=0.5*(model2(k,i)+model2(k,i+1)) ;
                  deltaxsum(j)=deltax1(j)+deltax2(j) ;
            
% divide calculation into 4 chunks to simplify matters
            
% first, the contribution of the patch before

                  revised_kernel(n_obs+model1(k,i),model1(k,i-1))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i-1))+...
                      (2*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
% next, the contributions of the centre patch

                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
                  revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                      ((-2)*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;

% and finally, the contribution of the patch after

                  revised_kernel(n_obs+model1(k,i),model1(k,i+1))=...
                      revised_kernel(n_obs+model1(k,i),model1(k,i+1))+...
                      (2*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;


               end

% if at the end of the fault, generate the Laplacian where
% slip at the ends is constrained to be zero
% first, the 'near' end:
            
            elseif (i==1)
            
 % calculate spacings between patches
            
               deltax1(j)=model2(k,i) ;
               deltax2(j)=0.5*(model2(k,i)+model2(k,i+1)) ;
               deltaxsum(j)=deltax1(j)+deltax2(j) ;
            
% divide calculation into chunks as before
            
% the patch before, of course, has no contribution
            
% the contributions of the centre patch...

               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   ((-2)*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   ((-2)*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;

% and finally, the contribution of the patch after

               revised_kernel(n_obs+model1(k,i),model1(k,i+1))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i+1))+...
                   (2*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;           
 
% now, at the 'far' end:

           elseif (i==r)
            
% calculate spacings between patches
            
               deltax1(j)=0.5*(model2(k,i-1)+model2(k,i)) ;
               deltax2(j)=model2(k,i) ;
               deltaxsum(j)=deltax1(j)+deltax2(j) ;
 
% calculation in chunks...
            
% first, the contribution of the patch before

               revised_kernel(n_obs+model1(k,i),model1(k,i-1))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i-1))+...
                   (2*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
% next, the contributions of the centre patch

               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   ((-2)*smoothing_factor)/(deltax1(j)*deltaxsum(j)) ;
            
               revised_kernel(n_obs+model1(k,i),model1(k,i))=...
                   revised_kernel(n_obs+model1(k,i),model1(k,i))+...
                   ((-2)*smoothing_factor)/(deltax2(j)*deltaxsum(j)) ;

% and the patch after has no contribution...
            
           end
        
       end
    
   end
            
end
