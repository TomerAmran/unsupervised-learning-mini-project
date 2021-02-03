using Gtk, Graphics, Images ,GtkUtilities
img = load("scaled.png")
h,w = size(img)
c = @GtkCanvas(w,h)
win = GtkWindow(c, "Canvas")
marked_pixels = Any[]
@guarded draw(c) do widget
    ctx = getgc(c)
    copy!(ctx,img)
end
c.mouse.button1press = @guarded (widget, event) -> begin
    push!(marked_pixels,[event.x event.y])
    ctx = getgc(widget)
    set_source_rgb(ctx, 0, 1, 0)
    arc(ctx, event.x, event.y, 2, 0, 2pi)
    stroke(ctx)
    reveal(widget)
end
show(c)
