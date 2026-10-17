"""Original layout guide only; generated illustration is produced with image_gen."""
from pathlib import Path
from PIL import Image, ImageDraw

out = Path(__file__).resolve().parent
im = Image.new('RGB', (1920,960), '#626566')
d = ImageDraw.Draw(im)
areas = [(0,0,1,1,'#b6a382'),(1,0,1,2,'#81775f'),(0,1,1,1,'#88846d'),(4,1,1,1,'#878369'),(5,1,1,1,'#b2b7a9'),(4,2,1,1,'#c1ab87'),(5,2,1,1,'#7d806a')]
for x,y,w,h,c in areas:
    d.rectangle((x*320,y*320,(x+w)*320,(y+h)*320),fill=c,outline='#171b1b',width=9)
# Internal and exterior openings, exactly matching MAP-001.
for x,y,vertical in [(1,.5,True),(.5,1,False),(1,1.5,True),(5,1.5,True),(4.5,2,False),(5.5,2,False),(5,2.5,True),(1.5,2,False),(4.5,1,False),(4,2.5,True)]:
    px,py=int(x*320),int(y*320)
    d.rectangle((px-(7 if vertical else 48),py-(48 if vertical else 7),px+(7 if vertical else 48),py+(48 if vertical else 7)),fill='#b3a68b')
# Street zone boundaries must remain line markings, not walls or tile seams.
for a,b in [((2,1),(4,1)),((2,2),(4,2)),((2,2),(2,3)),((4,0),(4,1))]:
    d.line((a[0]*320,a[1]*320,b[0]*320,b[1]*320),fill='#cac4ad',width=4)
im.save(out/'map-guide.png')
