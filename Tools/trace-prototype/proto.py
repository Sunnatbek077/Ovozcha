import numpy as np, random
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage as ndi
from skimage.morphology import skeletonize

import os
FONT=os.path.join(os.path.dirname(os.path.abspath(__file__)),"..","..","Sources","Ovozcha","Resources","Fonts","Andika-Bold.ttf")
W,H = 340,380                 # nominal canvas (pt)
GW = 96; GH = round(GW*H/W)   # grid
CELL = W/GW
LETTERS = [("A","a"),("B","b"),("D","d"),("E","e"),("F","f"),("G","g"),("H","h"),("I","i"),("J","j"),("K","k"),("L","l"),("M","m"),("N","n"),("O","o"),("P","p"),("Q","q"),("R","r"),("S","s"),("T","t"),("U","u"),("V","v"),("X","x"),("Y","y"),("Z","z"),("O\u02BB","o\u02BB"),("G\u02BB","g\u02BB"),("Sh","sh"),("Ch","ch"),("Ng","ng")]

EM      = 0.58*H     # font size (pt)
BASE    = 0.70*H     # baseline y (pt)
FIT     = 0.84       # max ink width fraction of canvas

def render_target(text, ss=3):
    font = ImageFont.truetype(FONT, int(EM*ss))
    tmp = Image.new("L",(W*ss,H*ss),0); d=ImageDraw.Draw(tmp)
    x0,y0,x1,y1 = d.textbbox((0,0),text,font=font,anchor="ls")
    inkw=(x1-x0)/ss
    scale = min(1.0, FIT*W/inkw)
    if scale<1.0: font = ImageFont.truetype(FONT, int(EM*scale*ss)); x0,y0,x1,y1 = d.textbbox((0,0),text,font=font,anchor="ls")
    cx = (x0+x1)/2
    d.text((W*ss/2 - cx, BASE*ss - (0 if scale==1 else 0)), text, font=font, anchor="ls", fill=255)
    im = tmp.resize((GW,GH), Image.BOX)
    return (np.asarray(im,dtype=np.float32)/255.0) > 0.5

def disc_from_points(pts_cells, r_cells):
    m = np.zeros((GH,GW),bool)
    for (x,y) in pts_cells:
        xi,yi=int(round(x)),int(round(y))
        if 0<=xi<GW and 0<=yi<GH: m[yi,xi]=True
    if not m.any(): return m
    dt = ndi.distance_transform_edt(~m)
    return dt <= r_cells

def polyline_points(poly, step=0.7):
    out=[]
    for (a,b) in zip(poly[:-1],poly[1:]):
        n=max(1,int(np.hypot(b[0]-a[0],b[1]-a[1])/step))
        for t in np.linspace(0,1,n,endpoint=False): out.append((a[0]+(b[0]-a[0])*t, a[1]+(b[1]-a[1])*t))
    out.append(poly[-1]); return out

def stroke_mask(strokes_pt, brush_pt):
    pts=[]
    for s in strokes_pt:
        cells=[(x/CELL,y/CELL) for x,y in s]
        pts += polyline_points(cells) if len(cells)>1 else cells
    return disc_from_points(pts, brush_pt/CELL/2)

def evaluate(T, D, S):
    covered = (T & S).sum()/max(1,T.sum())
    prec = (S & D).sum()/S.sum() if S.any() else 0.0
    return covered, prec

def stem_width(T):
    sk = skeletonize(T); 
    return T.sum()/max(1,sk.sum())*CELL     # approx stem thickness (pt)
