using StatsBase
using Images
function consecutive(f, A::AbstractVector)
    [ f(A[i+1], A[i]) for i = 1:length(A)-1 ]
end
function Kinect_DepthNormalization(depthImage , invalid_val)
    row,col = size(depthImage)
    widthBound = row-1
    heightBound = col-1

    # initializing working image; leave original matrix aside
    filledDepth = depthImage

    #initializing the filter matrix
    filterBlock= zeros(5,5)
    
    # to keep count of zero pixels found
    zeroPixels = 0
    
    #The main loop
    for x=1 : row
        for y=1 : col        
            #Only for pixels with 0 depth value; else skip
            if filledDepth[x,y] .== invalid_val
                zeroPixels = zeroPixels+1
                # values set to identify a positive filter result.
                 p = 1
                # Taking a cube of 5x5 around the 0 depth pixel
                # q = index
                # select two pixels behind & two ahead in a row
                # select two pixels behind & two ahead in a column
                # leave the center pixel [as its the one to be filled]
                for xi = -2 : 1 : 2
                    q = 1
                    for yi = -2 : 1 : 2
                        # updating index for next pass
                        xSearch = x + xi; 
                        ySearch = y + yi
                        # xSearch & ySearch to avoid edges
                        if (xSearch > 0 && xSearch < widthBound && ySearch .> 0 && ySearch .< heightBound)
                            # save values from depth image into filter()
                            filterBlock[p,q] = filledDepth[xSearch,ySearch]
                        end
                        q = q+1
                    end
                    p = p+1
                end
                # Now that we have the 5x5 filter; with values surrounding
                # the zero valued fixel; in "filterBlock5x5" ; we can now()
                # Calculate statistical mode of the 5x5 matrix
                histogram = countmap([filterBlock...])
                max_val = invalid_val
                max_freq = 0
                for (val,freq) in histogram
                    if val != invalid_val && freq>max_freq
                        max_val = val
                        max_freq = freq
                    end
                end
                # println(max_val)
                filledDepth[x,y] = max_val
                # X = sort(filterBlock5x5[:])
                # print(X)
                # # find all non-zero entries in the sorted filter block 
                # v = findall(x->x .!= 0, X)
                # # indices where repeated values change
                # if (isempty(v))
                #     filledDepth[x,y] = 0
                # else
                #     indices  = findall(x->x != 0,consecutive([v typemax(Int64)]', -))
                #     # finding longest persistent length of repeated values
                #     ~,i =  max(consecutive([0 indices]', -))     
                #     # The value that is repeated is the mode
                #     mode= v[indices[i]]

                #     # fill in the x;y value with the statistical mode of the values
                #     filledDepth[x,y] = mode
                # end

            end
        end
    # end for
    end
return filledDepth
end
function find_invalid(path, invalid_val)
    img = load()
     freq = count(x->x==invalid_val, img)
end
img = load("images/frame-000010.depth.png")
img = Float32.(img)
dt = fit(UnitRangeTransform, img)
new = StatsBase.transform(dt, img)
save("gray.png", colorview(Gray, new))