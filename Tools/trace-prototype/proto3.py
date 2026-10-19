import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    import search
from search import *
from scipy import ndimage as ndi

def chebyshev_inside(T):
    """Ikki o'tishli 8-qo'shni masofa (Swift'dagi bilan bir xil)."""
    h,w=T.shape; d=np.where(T,10**6,0).astype(np.int64)
    for y in range(h):
        for x in range(w):
            if d[y,x]:
                m=d[y,x]
                for dy,dx in ((-1,-1),(-1,0),(-1,1),(0,-1)):
                    yy,xx=y+dy,x+dx
                    v=d[yy,xx] if 0<=yy<h and 0<=xx<w else 0
                    m=min(m,v+1)
                d[y,x]=m
    for y in range(h-1,-1,-1):
        for x in range(w-1,-1,-1):
            if d[y,x]:
                m=d[y,x]
                for dy,dx in ((1,1),(1,0),(1,-1),(0,1)):
                    yy,xx=y+dy,x+dx
                    v=d[yy,xx] if 0<=yy<h and 0<=xx<w else 0
                    m=min(m,v+1)
                d[y,x]=m
    return d

MIN_SKEL=10
def scoring_cells(T):
    """Skelet + skeleti kichik komponentlar uchun 'yadro' piksellari."""
    K=zhang_suen(T)
    lab,n=ndi.label(T,structure=np.ones((3,3)))
    dist=chebyshev_inside(T)
    out=K.copy()
    for c in range(1,n+1):
        comp=lab==c
        if (K&comp).sum()<MIN_SKEL:
            mx=dist[comp].max(); core=comp&(dist>=int(np.ceil(0.5*mx))); out|=core
    return out
if __name__=="__main__":
    for t in ["i","j","I","O\u02BB","G\u02BB","l","B"]:
        T=TARGETS[t]; K0=SK[t]; K1=scoring_cells(T)
        lab,n=ndi.label(T,structure=np.ones((3,3)))
        print(f"{t!r:8s} komponentlar={n}  skelet={K0.sum():3d} -> ball beriladigan katak={K1.sum():3d}")
