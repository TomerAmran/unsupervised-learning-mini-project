
function  Kinect_DepthNormalization (depthImage)
    row,col = size(depthImage)
    widthBound = row-1
    heightBound = col-1

    # initializing working image  leave original matrix aside
    filledDepth = depthImage

    #initializing the filter matrix
    filterBlock5x5 = zeros(5,5) 
    # to keep count of zero pixels found
    zeroPixels = 0 
    
    #The main loop
    for x=1 : row
        for y=1 : col        
            #Only for pixels with 0 depth value  else skip
            if filledDepth[x,y] .== 0
                zeroPixels = zeroPixels+1
                # values set to identify a positive filter result.
                 p = 1
                # Taking a cube of 5x5 around the 0 depth pixel
                # q = index
                # select two pixels behind and two ahead in a row
                # select two pixels behind and two ahead in a column
                # leave the center pixel (as its the one to be filled)
                for xi = -2 : 1 : 2
                    q = 1
                    for yi = -2 : 1 : 2
                        # updating index for next pass
                        xSearch = x + xi 
                        ySearch = y + yi
                        # xSearch and ySearch to avoid edges
                        if  [xSearch > 0 && xSearch < widthBound && ySearch > 0 && ySearch < heightBound)
                            # save values from depth image into filter
                            filterBlock5x5[p,q] = filledDepth[xSearch,ySearch]
                        end
                        q = q+1 
                    end
                    p = p+1 
                end
                # Now that we have the 5x5 filter, with values surrounding
                # the zero valued fixel, in 'filterBlock5x5'   we can now
                # Calculate statistical mode of the 5x5 matrix
                X = sort(filterBlock5x5[:]) 
                # find all non-zero entries in the sorted filter block 
                ~,~,v = find(X) 
                # indices where repeated values change
                if (isempty(v)) 
                    filledDepth[x,y] = 0 
                else
                    indices   =  find(diff([v  realmax]) > 0) 
                    # finding longest persistent length of repeated values
                    [~,i] =  max (diff([0  indices]))      
                    # The value that is repeated is the mode
                    mode      =  v(indices(i)) 

                    # fill in the x,y value with the statistical mode of the values
                    filledDepth[x,y] = mode 
                end
            end
        end
    # end for
    end
return filledDepth 
end


