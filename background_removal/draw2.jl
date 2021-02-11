using Gtk
c = @GtkCanvas(300,200)
b = GtkBox(:h)
push!(b,c)
set_gtk_property!(b,:expand,c,true)
win = GtkWindow(b, "Canvas")
print("hello")
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
    # Paint red rectangle
    rectangle(ctx, 0, 0, w, h/2)
    set_source_rgb(ctx, 1, 0, 0)
    fill(ctx)
    # Paint blue rectangle
    rectangle(ctx, 0, 3h/4, w, h/4)
    set_source_rgb(ctx, 0, 0, 1)
    fill(ctx)
end
showall(win)