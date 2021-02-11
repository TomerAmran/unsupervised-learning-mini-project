
#Load some packages and add workers
using Images
using StatsBase
using CSV
using Distributed
using LinearAlgebra
using Statistics
using JLD
# using DelimitedFiles

#Load the package on all workers
# addprocs(4)
# @everywhere using DPMMSubClusters


# niw mixturemodels
using DPMMSubClusters
function img_resize(img, width=300)
    x,y = size(img)
    height = trunc(Int,(x*(width/y)))
    resized_img = imresize(img,height,width)
    return resized_img
end
 
    
function segment_rgb(img_path,out_path,rgb_prior_multiplier,xy_prior_multiplier,nu)
    img = load(img_path)
    img = img_resize(img)
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
    img = img_resize(load(img_path))
    depth = img_resize(load(depth_path))
    #depth normalization
    # depth = Float32.(depth)
    # dt = StatsBase.fit(UnitRangeTransform, depth)
    # depth = StatsBase.transform(dt, depth)
    # depth = Kinect_DepthNormalization(depth)
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
    save("background_removal/rgbd_labels.jld", "labels",labels)

end

function segment_rgbd_with_seperate_depth_weight(img_path,depth_path,out_path,rgb_prior_multiplier,xy_prior_multiplier,depth_multiplier,niw)
    img = img_resize(load(img_path))
    depth = img_resize(load(depth_path))
    #depth normalization to [0.0,1.0]
    # depth = Float32.(depth)
    # dt = StatsBase.fit(UnitRangeTransform, depth)
    # depth = StatsBase.transform(dt, depth)
    # depth = Kinect_DepthNormalization(depth)
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
    #מטריצת השוניות שאני מגדיר, האם זה בעצם השונות של הגאוסין הראשוני שממנו אנחנו מתחילים?
    data_cov = cov(input_arr')
    data_cov[4:6,1:3] .= 0
    data_cov[1:3,4:6] .= 0
    # data_cov[1:5,6] .= 0 
    # data_cov[6,1:5] .= 0
    data_cov[1:3,1:3] .*= rgb_prior_multiplier
    data_cov[4:5,4:5] .*= xy_prior_multiplier
    data_cov[6,6] *= depth_multiplier
    # זה התוחלת של הנקודות, זה יהיה שייך לגאוסיין ההתחלתי
    data_mean = mean(input_arr,dims = 2)[:]
    hyper_params = DPMMSubClusters.niw_hyperparams(0.5,
            data_mean,
            niw, #nu
            data_cov)
    #Run the model
    labels,clusters,weights = DPMMSubClusters.fit(input_arr,hyper_params,50000.0,iters = 200, verbose = true)
    # print(clusters, weights)
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
    save("background_removal/rgbd_labels.jld", "labels",labels)
    
end
source = "15. Restaurant"
img_name = "in_01_160317_131212"
img_path = "data/" * source *  "/color/" * img_name * "_c" * ".png" 
depth_path = "data/" * source *  "/depth_filled/" * img_name * "_depth_filled" * ".png"
depth_path_vi = "data/" * source *  "/depth_vi/" * img_name * "_depth_vi" * ".png"
output_path = "results/" * img_name * "/" 
rgb_prior_multiplier = 30
xy_prior_multiplier = 1 
depth_prior_multiplier = 1
niw = 16
println("running..")
save("results/" * img_name * "/scaled.png",img_resize(load(img_path)))
save("background_removal/scaled.png", img_resize(load(img_path)))
save("results/" * img_name * "/depth_map.png", img_resize(load(depth_path_vi)))
segment_rgb(img_path, output_path * "rgb.png",rgb_prior_multiplier,xy_prior_multiplier, niw)
segment_rgbd(img_path,depth_path,output_path * "rgbd.png",rgb_prior_multiplier,xy_prior_multiplier,niw)
# segment_rgbd_with_seperate_depth_weight(img_path,depth_path,output_path * "rgbd_v2.png",rgb_prior_multiplier,xy_prior_multiplier,depth_prior_multiplier,niw)
#alpha set how many clusters I want
#הוא שיחק שם עם היחסים כי זה לא באותן יחידות
# השונות אומרת לי כמה השפעה יש כי אם הגואסיין מאוד רחב זה כמעט פילוג אחיד
# והפרטמר קאפה שהוא 0.5 זה כמה אני בטוח בניחוש ההתחלתי שנתתי
#  מה עוד?
# למשוך את התיקון של אור כדי למנוע את השגיאות הנומריות