using Images
using ImageView
using StatsBase
using CSV
using Distributed
using LinearAlgebra
using Statistics
using JLD
using Gtk, Graphics, Images ,GtkUtilities
function get(i,j,width)
    return ((i-1)*width + j)
end

function remove(targetX::Int, targetY::Int64)
    labels=load("rgbd_labels.jld", "labels")
    img = load("scaled.png")
    img_channels = channelview(img)
    height, width = size(img)
    croped_img  = fill(RGBA(1,1,1,0), (height,width))
    target_label = labels[get(targetX,targetY,width)]
    for i=1:height
        for j=1:width
            if (labels[get(i,j,width)] .== target_label)
                croped_img[i,j] = RGBA(img_channels[1,i,j],img_channels[2,i,j],img_channels[3,i,j],1)
            end
        end
    end
    Images.save("cropd.png",croped_img)
    # ImageView.imshow(croped_img)     
end




img = load("scaled.png")
h,w = size(img)
print(h," ",w)
c = @GtkCanvas(w,h-50)
win = GtkWindow(c, "Canvas")
@guarded draw(c) do widget
    ctx = getgc(c)
    copy!(ctx,img)
end
c.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, event.x, event.y, 2, 0, 2pi)
    stroke(ctx)
    reveal(widget)
    y = trunc(Int,event.x)
    x = trunc(Int,event.y)
    println(x," ",y)
    remove(x,y)
    # destroy(win)
end
show(c)
