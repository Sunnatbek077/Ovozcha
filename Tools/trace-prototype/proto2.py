import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from proto import *
import numpy as np
from scipy import ndimage as ndi

def zhang_suen(img):
    """Zhang-Suen thinning (Swift bilan aynan bir xil algoritm)."""
    I=img.astype(np.uint8).copy(); h,w=I.shape
    P=np.pad(I,1)
    changed=True
    while changed:
        changed=False
        for step in (0,1):
            p2=P[:-2,1:-1];p3=P[:-2,2:];p4=P[1:-1,2:];p5=P[2:,2:];p6=P[2:,1:-1];p7=P[2:,:-2];p8=P[1:-1,:-2];p9=P[:-2,:-2];c=P[1:-1,1:-1]
            nb=p2+p3+p4+p5+p6+p7+p8+p9
            seq=[p2,p3,p4,p5,p6,p7,p8,p9,p2]
            A=sum(((seq[i]==0)&(seq[i+1]==1)).astype(np.uint8) for i in range(8))
            if step==0: c1=(p2*p4*p6==0); c2=(p4*p6*p8==0)
            else:       c1=(p2*p4*p8==0); c2=(p2*p6*p8==0)
            rm=(c==1)&(nb>=2)&(nb<=6)&(A==1)&c1&c2
            if rm.any(): P[1:-1,1:-1][rm]=0; changed=True
    return P[1:-1,1:-1].astype(bool)

def evaluate2(T,D,K,path_cells,rc_cells,blocks=None):
    """path_cells: Nx2 (x,y) katak koordinatalarida zich nuqtalar."""
    if len(path_cells)==0: return 0.0,0.0,0.0
    m=np.zeros((GH,GW),bool)
    xi=np.round(path_cells[:,0]).astype(int); yi=np.round(path_cells[:,1]).astype(int)
    ok=(xi>=0)&(xi<GW)&(yi>=0)&(yi<GH)
    m[yi[ok],xi[ok]]=True
    if not m.any(): return 0.0,0.0,0.0
    dt=ndi.distance_transform_edt(~m)
    kc=(dt<=rc_cells)&K
    cov=kc.sum()/max(1,K.sum())
    inside=np.zeros(len(path_cells),bool); inside[ok]=D[yi[ok],xi[ok]]
    prec=inside.mean()
    # hududlar bo'yicha minimal qoplash (glif chegara qutisi 3x3)
    ys,xs=np.nonzero(K); minreg=1.0
    if len(xs)>0:
        x0,x1,y0,y1=xs.min(),xs.max()+1,ys.min(),ys.max()+1
        bx=np.minimum(((xs-x0)*BLK/(x1-x0)).astype(int),BLK-1); by=np.minimum(((ys-y0)*BLK/(y1-y0)).astype(int),BLK-1)
        cov_cells=kc[ys,xs]; regs=[]
        for j in range(BLK):
            for i in range(BLK):
                sel=(bx==i)&(by==j); n=sel.sum()
                if n>=MINREG_FRAC*len(xs): regs.append(cov_cells[sel].mean())
        minreg=min(regs) if regs else 1.0
    return cov,prec,minreg
BLK=3; MINREG_FRAC=0.08
def path_from_strokes(strokes_pt):
    out=[]
    for s in strokes_pt:
        cells=[(x/CELL,y/CELL) for x,y in s]
        out+= polyline_points(cells) if len(cells)>1 else cells
    return np.array(out) if out else np.zeros((0,2))
