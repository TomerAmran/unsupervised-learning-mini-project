
#Load some packages and add workers
# using Pkg 
# Pkg.add("Images")
# Pkg.add("ImageIO")
# Pkg.add("QuartzImageIO")
# Pkg.add("ImageMagick")

using Images
using Distributed

using LinearAlgebra
using Statistics

#Load the package on all workers
# addprocs(4)
# @everywhere 


# niw mixturemodels
using DPMMSubClusters

 
    
function segment_rgb(img_path,out_path,rgb_prior_multiplier,xy_prior_multiplier,nu)
    img = load(img_path)
    #Change to channel view
    img_channels = channelview(img)
    z,x,y = size(img_channels)
    #Create input
    input_arr = zeros(5,x*y)
    for i=1:x
        for j=1:y
            input_arr[:,(i-1)*y+j]=[img_channels[1,i,j],img_channels[2,i,j],img_channels[3,i,j],i,j]
        end
    end

    #Create HyperParams
    #The rgb,xy multiplier allows us to both play with the weight of the xy/rgb
    data_cov = cov(input_arr')
    data_cov[4:5,1:3] .= 0
    data_cov[1:3,4:5] .= 0

    data_cov[1:3,1:3] .*= rgb_prior_multiplier
    data_cov[4:5,4:5] .*= xy_prior_multiplier

    data_mean = mean(input_arr,dims = 2)[:]

    hyper_params = DPMMSubClusters.niw_hyperparams(0.5,
            data_mean,
            nu, #nu
            data_cov)
    #Run the model
    labels,clusters,weights = DPMMSubClusters.fit(input_arr,hyper_params,50000.0,iters = 200, verbose = true)

    #Get the cluster color means
    color_means = [x.μ[1:3] for x in clusters]


    segemnated_image = zeros(3,x,y)
    for i=1:x
        for j=1:y
            segemnated_image[:,i,j] = color_means[labels[(i-1)*y+j]]
        end
    end
    segemnated_image = colorview(RGB,segemnated_image)
    save(out_path, segemnated_image)
end

function segment_rgbd(img_path,depth_path,out_path,rgb_prior_multiplier,xyz_prior_multiplier,nu)
    img = load(img_path)
    depth = load(depth_path)
    #Change to channel view
    img_channels = channelview(img)
    rgb,x,y = size(img_channels)
    #Create input
    input_arr = zeros(6,x*y)
    for i=1:x
        for j=1:y
            input_arr[:,(i-1)*y+j]=[img_channels[1,i,j],img_channels[2,i,j],img_channels[3,i,j],i,j,depth[i,j]]
        end
    end
    #Create HyperParams
    #The rgb,xy multiplier allows us to both play with the weight of the xy/rgb
    # rgb_prior_multiplier = 30 
    # xyz_prior_multiplier = 1
    data_cov = cov(input_arr')
    data_cov[4:6,1:3] .= 0
    data_cov[1:3,4:6] .= 0
    data_cov[1:3,1:3] .*= rgb_prior_multiplier
    data_cov[4:6,4:6] .*= xyz_prior_multiplier
    data_mean = mean(input_arr,dims = 2)[:]
    hyper_params = DPMMSubClusters.niw_hyperparams(0.5,
            data_mean,
            nu, #nu
            data_cov)
    #Run the model
    labels,clusters,weights = DPMMSubClusters.fit(input_arr,hyper_params,50000.0,iters = 200, verbose = true)
    #Get the cluster color means
    color_means = [x.μ[1:3] for x in clusters]
    segemnated_image = zeros(3,x,y)
    for i=1:x
        for j=1:y
            segemnated_image[:,i,j] = color_means[labels[(i-1)*y+j]]
        end
    end
    segemnated_image = colorview(RGB,segemnated_image)
    save(out_path, segemnated_image)
end

img_path = "apple_1_1_1_crop.png"
depth_path = "apple_1_1_1_depthcrop.png"
rgb_prior_multiplier = 30
xy_prior_multiplier =1 
nu =8
segment_rgb(img_path,"rgb_result.png",rgb_prior_multiplier,xy_prior_multiplier, nu)
segment_rgbd(img_path,depth_path,"rgbd_result.png",rgb_prior_multiplier,xy_prior_multiplier, nu)
