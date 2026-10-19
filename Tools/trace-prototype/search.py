import sys; import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import sim2
from sim2 import *
import numpy as np, itertools

# Realroq "tashlab ketilgan qism": kichik bo'laklar (r 2..5 katak), soni ~ drop ulushiga mos
def good_path2(t,amp,bias,drop):
    ys,xs=np.nonzero(SK[t]); pts=np.stack([xs,ys],1).astype(float)
    keep=np.ones(len(pts),bool); removed=0; tgt=drop*len(pts); tries=0
    while removed<tgt and tries<50:
        tries+=1; c=pts[rng.integers(len(pts))]; r=rng.uniform(2,5); m=(np.hypot(pts[:,0]-c[0],pts[:,1]-c[1])<r)&keep; removed+=m.sum(); keep&=~m
    pts=pts[keep]
    fx,fy=smooth_field(amp); xi=np.clip(pts[:,0].astype(int),0,GW-1); yi=np.clip(pts[:,1].astype(int),0,GH-1); b=rng.normal(0,bias/CELL,2)
    return np.stack([pts[:,0]+fx[yi,xi]+b[0],pts[:,1]+fy[yi,xi]+b[1]],1)
sim2.good_path=good_path2
import proto2
def run(TOL,RC):
    D={t:(ndi.distance_transform_edt(~T)<=TOL/CELL) for t,T in TARGETS.items()}; rc=RC/CELL; letters=list(TARGETS)
    good={n:np.array([proto2.evaluate2(TARGETS[t],D[t],SK[t],good_path2(t,a,b,d),rc) for t in letters for _ in range(8)]) for n,(a,b,d) in {"careful":(4,3,0.03),"typical":(9,6,0.08),"sloppy":(15,10,0.18)}.items()}
    bad={}
    def add(k,f,reps=4): bad[k]=np.array([proto2.evaluate2(TARGETS[t],D[t],SK[t],f(t),rc) for t in letters for _ in range(reps)])
    add("empty",lambda t:np.zeros((0,2)),1); add("dot",lambda t:sim2.path_from_strokes([[(W/2,H/2)]]),1)
    add("scribble",lambda t:sim2.path_from_strokes(sim2.scribble(4)),6); add("blob",lambda t:sim2.path_from_strokes(sim2.blob()),1)
    add("underline",lambda t:sim2.path_from_strokes([[(0.1*W,BASE),(0.9*W,BASE)]]),1)
    def shift(dx,dy):
        def f(t): ys,xs=np.nonzero(SK[t]); return np.stack([xs+dx/CELL,ys+dy/CELL],1).astype(float)
        return f
    add("shift30",shift(30,10),1); add("shift40",shift(40,0),1)
    def half(t):
        ys,xs=np.nonzero(SK[t]); m=xs<np.median(xs); return np.stack([xs[m],ys[m]],1).astype(float)
    add("half_trace",half,1)
    def third_missing(t):
        ys,xs=np.nonzero(SK[t]); m=xs<np.percentile(xs,68); return np.stack([xs[m],ys[m]],1).astype(float)
    add("70pct_trace",third_missing,1)
    return good,bad
def st(v,S):
    out=np.zeros(len(v),int)
    for i,(cc,pp,rr) in enumerate(S):
        out=np.where((v[:,0]>=cc)&(v[:,1]>=pp)&(v[:,2]>=rr),i+1,out)
    return out
best=[]
for TOL,RC in [(8,20),(10,22),(10,24),(12,24),(12,26)]:
    good,bad=run(TOL,RC)
    for c1,c2,c3 in itertools.product([0.55,0.6,0.65,0.7],[0.75,0.8],[0.88,0.92]):
        for p1,p2,p3 in [(0.6,0.7,0.8),(0.65,0.75,0.85),(0.7,0.8,0.9)]:
            for r3 in [0.0,0.3,0.5]:
                S=[(c1,p1,0.0),(c2,p2,0.0),(c3,p3,r3)]
                fp=max((st(v,S)>=1).mean() for k,v in bad.items() if k!="70pct_trace")
                car=st(good["careful"],S); typ=st(good["typical"],S); slo=st(good["sloppy"],S)
                score= (car>=2).mean()+ (car==3).mean()*0.5 + (typ>=1).mean() + (typ>=2).mean()*0.5 + (slo>=1).mean()*0.3 - 6*fp
                best.append((score,TOL,RC,S,fp,(car>=2).mean(),(car==3).mean(),(typ>=1).mean(),(typ>=2).mean(),(slo>=1).mean()))
best.sort(key=lambda x:-x[0])
print("TOP 8 sozlama  (score, tol, reach, [(cov,prec,reg)*3], eng_yomon_false_pass, careful>=2★, careful=3★, typical>=1★, typical>=2★, sloppy>=1★)")
for b in best[:6]:
    print(f" {b[0]:.2f} tol={b[1]} rc={b[2]} S={b[3]} FP={b[4]:.1%} car>=2:{b[5]:.0%} car3:{b[6]:.0%} typ>=1:{b[7]:.0%} typ>=2:{b[8]:.0%} slo>=1:{b[9]:.0%}")
