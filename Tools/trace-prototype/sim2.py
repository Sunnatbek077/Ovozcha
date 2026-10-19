import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from proto2 import *
import numpy as np, random
rng=np.random.default_rng(11); random.seed(11)
TARGETS={};SK={}
for u,l in LETTERS:
    for t in (u,l):
        T=render_target(t); TARGETS[t]=T; SK[t]=zhang_suen(T)
def smooth_field(amp_pt, sigma=14):
    fx=ndi.gaussian_filter(rng.standard_normal((GH,GW)),sigma); fy=ndi.gaussian_filter(rng.standard_normal((GH,GW)),sigma)
    return fx/max(fx.std(),1e-9)*amp_pt/CELL, fy/max(fy.std(),1e-9)*amp_pt/CELL
def good_path(t,amp,bias,drop):
    ys,xs=np.nonzero(SK[t]); pts=np.stack([xs,ys],1).astype(float)
    if drop>0:
        keep=np.ones(len(pts),bool); removed=0; tgt=drop*len(pts)
        while removed<tgt:
            c=pts[rng.integers(len(pts))]; r=rng.uniform(4,10); m=(np.hypot(pts[:,0]-c[0],pts[:,1]-c[1])<r)&keep; removed+=m.sum(); keep&=~m
        pts=pts[keep]
    fx,fy=smooth_field(amp); xi=np.clip(pts[:,0].astype(int),0,GW-1); yi=np.clip(pts[:,1].astype(int),0,GH-1)
    b=rng.normal(0,bias/CELL,2)
    return np.stack([pts[:,0]+fx[yi,xi]+b[0],pts[:,1]+fy[yi,xi]+b[1]],1)
def scribble(n):
    return [[(rng.uniform(0.1*W,0.9*W),rng.uniform(0.1*H,0.9*H)) for _ in range(rng.integers(2,5))] for _ in range(n)]
def blob():
    ys=np.linspace(0.12*H,0.9*H,14); s=[]
    for i,y in enumerate(ys):
        xs=(0.1*W,0.9*W) if i%2==0 else (0.9*W,0.1*W); s.append([(xs[0],y),(xs[1],y)])
    return s

def collect(TOL,RC):
    D={t:(ndi.distance_transform_edt(~T)<=TOL/CELL) for t,T in TARGETS.items()}
    rc=RC/CELL; letters=list(TARGETS); good={}; bad={}
    for name,(amp,bias,drop) in {"careful":(4,3,0.02),"typical":(9,6,0.07),"sloppy":(15,10,0.15)}.items():
        good[name]=np.array([evaluate2(TARGETS[t],D[t],SK[t],good_path(t,amp,bias,drop),rc) for t in letters for _ in range(6)])
    def add(k,f,reps=4): bad[k]=np.array([evaluate2(TARGETS[t],D[t],SK[t],f(t),rc) for t in letters for _ in range(reps)])
    add("empty",lambda t:np.zeros((0,2)),1)
    add("dot",lambda t:path_from_strokes([[(W/2,H/2)]]),1)
    add("scribble",lambda t:path_from_strokes(scribble(4)))
    add("blob",lambda t:path_from_strokes(blob()),1)
    add("underline",lambda t:path_from_strokes([[(0.1*W,BASE),(0.9*W,BASE)]]),1)
    def shift(t):
        ys,xs=np.nonzero(SK[t]); return np.stack([xs+30/CELL,ys+10/CELL],1).astype(float)
    add("shift30",shift,1)
    def half(t):
        ys,xs=np.nonzero(SK[t]); m=xs<np.median(xs); return np.stack([xs[m],ys[m]],1).astype(float)
    add("half_trace",half,1)
    def wrong(t):
        o=random.choice([k for k in letters if k!=t]); ys,xs=np.nonzero(SK[o]); return np.stack([xs,ys],1).astype(float)
    add("wrong_letter",wrong,6)
    return good,bad

def stars(c,p,r,S):
    n=0
    for i,(cc,pp,rr) in enumerate(S):
        if c>=cc and p>=pp and r>=rr: n=i+1
    return n
if __name__=="__main__":
    import itertools
    S=[(0.55,0.60,0.25),(0.75,0.72,0.45),(0.88,0.85,0.65)]
    for TOL,RC in [(8,18),(10,20),(10,24),(12,22)]:
        good,bad=collect(TOL,RC)
        print(f"\n=== tolerance {TOL}pt  reach {RC}pt  | yulduz chegaralari (cov,prec,region) {S}")
        for k,v in good.items():
            st=np.array([stars(*r,S) for r in v]); print(f"  GOOD {k:9s} cov {v[:,0].mean():.2f} prec {v[:,1].mean():.2f} reg {v[:,2].mean():.2f} | 0★:{(st==0).mean():.0%} 1★:{(st==1).mean():.0%} 2★:{(st==2).mean():.0%} 3★:{(st==3).mean():.0%}")
        for k,v in bad.items():
            st=np.array([stars(*r,S) for r in v]); print(f"  BAD  {k:12s} cov {v[:,0].mean():.2f} prec {v[:,1].mean():.2f} reg {v[:,2].mean():.2f} | noto'g'ri o'tish: {(st>=1).mean():.1%}")
