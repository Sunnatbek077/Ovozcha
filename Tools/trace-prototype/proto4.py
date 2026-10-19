import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    from proto3 import *
import proto2, sim2

def build_target(t):
    T=TARGETS[t]; K=zhang_suen(T)
    lab,n=ndi.label(T,structure=np.ones((3,3))); dist=chebyshev_inside(T)
    cells=K.copy(); groups=[]
    for c in range(1,n+1):
        comp=lab==c
        if (K&comp).sum()<MIN_SKEL:
            mx=dist[comp].max(); plateau=comp&(dist==mx)        # faqat eng markaziy katak(lar)
            cells|=plateau; groups.append(plateau)
    return cells,groups

def evaluate4(t,path,tol_pt,reach_pt,em=EM):
    T=TARGETS[t]; cells,groups=BUILT[t]
    if len(path)==0: return 0,0,0,False
    reach=max(18,0.0909*em) if reach_pt is None else reach_pt
    m=np.zeros((GH,GW),bool); xi=np.round(path[:,0]).astype(int); yi=np.round(path[:,1]).astype(int)
    ok=(xi>=0)&(xi<GW)&(yi>=0)&(yi<GH); m[yi[ok],xi[ok]]=True
    if not m.any(): return 0,0,0,False
    dt=ndi.distance_transform_edt(~m); cov_mask=dt<=reach/CELL
    cov=(cov_mask&cells).sum()/cells.sum()
    Dm=ndi.distance_transform_edt(~T)<=tol_pt/CELL
    inside=np.zeros(len(path),bool); inside[ok]=Dm[yi[ok],xi[ok]]; prec=inside.mean()
    missing=any(not (cov_mask&g).any() for g in groups)
    return cov,prec,0,missing
BUILT={t:build_target(t) for t in TARGETS}
def stars(cov,prec,missing,S=((0.70,0.60),(0.82,0.75),(0.92,0.85))):
    n=0
    for i,(c,p) in enumerate(S):
        if cov>=c and prec>=p: n=i+1
    if missing: n=min(n,2)
    return n
if __name__=="__main__":
    TOL,RC=8,20; letters=list(TARGETS)
    lv={"careful":(4,3,0.03),"typical":(9,6,0.08),"sloppy":(15,10,0.18)}
    print("--- yaxshi urinishlar (nuqta ham qo'yilgan)")
    for n,(a,b,d) in lv.items():
        s=np.array([stars(*[evaluate4(t,good_path2(t,a,b,d),TOL,RC)[i] for i in (0,1,3)]) for t in letters for _ in range(8)])
        print(f"  {n:8s} 0★{(s==0).mean():4.0%} 1★{(s==1).mean():4.0%} 2★{(s==2).mean():4.0%} 3★{(s==3).mean():4.0%}")
    print("--- nuqta qo'yilmagan (i,j uchun stem'ni chizib, nuqtani tashlab ketish)")
    for t in ["i","j"]:
        ys,xs=np.nonzero(SK[t]); pts=np.stack([xs,ys],1).astype(float); pts=pts[pts[:,1]>np.percentile(pts[:,1],25)]  # yuqori 25% ni (nuqta zonasi) tashla
        c,p,_,mis=evaluate4(t,pts,TOL,RC); print(f"  {t}: cov {c:.2f} prec {p:.2f} nuqta_yo'q={mis} -> {stars(c,p,mis)}★")
        c,p,_,mis=evaluate4(t,np.vstack([pts,[[GW*0.5,GH*0.5]]]),TOL,RC)
    print("--- yomon urinishlar")
    def rep(name,f,reps=4):
        s=[]; 
        for t in letters:
            for _ in range(reps):
                c,p,_,mis=evaluate4(t,f(t),TOL,RC); s.append(stars(c,p,mis))
        s=np.array(s); print(f"  {name:11s} o'tdi(>=1★) {(s>=1).mean():5.1%}")
    rep("empty",lambda t:np.zeros((0,2)),1); rep("dot",lambda t:sim2.path_from_strokes([[(W/2,H/2)]]),1)
    rep("scribble",lambda t:sim2.path_from_strokes(sim2.scribble(4)),6); rep("blob",lambda t:sim2.path_from_strokes(sim2.blob()),1)
    rep("underline",lambda t:sim2.path_from_strokes([[(0.1*W,BASE),(0.9*W,BASE)]]),1)
    def shift(t): ys,xs=np.nonzero(SK[t]); return np.stack([xs+30/CELL,ys+10/CELL],1).astype(float)
    rep("shift30",shift,1)
    def half(t): ys,xs=np.nonzero(SK[t]); m=xs<np.median(xs); return np.stack([xs[m],ys[m]],1).astype(float)
    rep("half_trace",half,1)
