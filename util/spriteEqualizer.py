from PIL import Image
import math, glob, os

#maxsize = [0, 0]
#
#for imgname in glob.glob("slice*"):
#    im = Image.open(imgname)
#    print(im.mode)
#    
#    if maxsize[0] < im.size[0] :
#        maxsize[0] = im.size[0]
#    if maxsize[1] < im.size[1] :
#        maxsize[1] = im.size[1]

maxsize = (23, 23) #tuple(maxsize)

for imgname in glob.glob("49192*"):
    newImage = Image.new("RGBA", maxsize, "rgb(255, 0, 255)")
    oldImage = Image.open(imgname)
    x1 = (maxsize[0] - oldImage.size[0])/2
    y1 = (maxsize[1] - oldImage.size[1])

    newImage.paste(oldImage, (x1, y1, x1 + oldImage.size[0], y1 + oldImage.size[1]), mask=oldImage)

    newImage.save("alt" + imgname)
    
  
