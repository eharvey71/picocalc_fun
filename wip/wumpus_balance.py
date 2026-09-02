"""
Balance harness for wip/wumpus.bas.

There is no MMBasic emulator here, so this is a line-for-line Python port of
the maze generator and warning logic in wumpus.bas.  It checks the properties
the game depends on:

  - tunnel links are symmetric (A --right--> B implies B --left--> A)
  - self-looping tunnels occur, as the TI manual's "SURPRISE!" case requires
  - nearly every cavern is reachable from the Wumpus
  - the Wumpus is uniquely deducible from the bloodspot pattern alone,
    i.e. the game is solvable by reasoning rather than guessing

Run: python3 wumpus_balance.py

This validates the ALGORITHM only.  It says nothing about whether the MMBasic
itself runs - that can only be checked on the PicoCalc.
"""

import random
from collections import deque
COLS,ROWS,NSLOT=8,6,48
DUP,DDN,DLF,DRT=0,1,2,3

def build(ncav):
    cav=[0]*NSLOT
    while sum(cav)<ncav:
        cav[random.randrange(NSLOT)]=1
    link=[[-1]*4 for _ in range(NSLOT)]
    tlen=[[0]*4 for _ in range(NSLOT)]
    for s in range(NSLOT):
        if not cav[s]: continue
        c,r=s%COLS,s//COLS
        for k in range(1,COLS+1):
            t=r*COLS+((c+k)%COLS)
            if cav[t]: link[s][DRT],tlen[s][DRT]=t,k; break
        for k in range(1,COLS+1):
            t=r*COLS+((c-k+2*COLS)%COLS)
            if cav[t]: link[s][DLF],tlen[s][DLF]=t,k; break
        for k in range(1,ROWS+1):
            t=((r+k)%ROWS)*COLS+c
            if cav[t]: link[s][DDN],tlen[s][DDN]=t,k; break
        for k in range(1,ROWS+1):
            t=((r-k+2*ROWS)%ROWS)*COLS+c
            if cav[t]: link[s][DUP],tlen[s][DUP]=t,k; break
    return cav,link,tlen

def bfs(link,start,maxd=None):
    dep={start:0}; q=deque([start])
    while q:
        s=q.popleft()
        if maxd is not None and dep[s]>=maxd: continue
        for d in range(4):
            n=link[s][d]
            if n>=0 and n not in dep:
                dep[n]=dep[s]+1; q.append(n)
    return dep

OPP={DUP:DDN,DDN:DUP,DLF:DRT,DRT:DLF}
stats={'sym':0,'loops':0,'reach':[],'blood':[],'clear':[],'solvable':0,'games':0,'nofit':0}
for trial in range(3000):
    ncav=random.choice([32,24,16])
    cav,link,tlen=build(ncav)
    # symmetry check: A --d--> B implies B --opp(d)--> A
    for s in range(NSLOT):
        if not cav[s]: continue
        for d in range(4):
            n=link[s][d]
            if n>=0 and link[n][OPP[d]]!=s: stats['sym']+=1
            if n==s: stats['loops']+=1
    wump=random.choice([i for i in range(NSLOT) if cav[i]])
    pits=random.sample([i for i in range(NSLOT) if cav[i]],2)
    blood=set(bfs(link,wump,2))
    slime=set()
    for p in pits:
        slime.add(p)
        for d in range(4):
            if link[p][d]>=0: slime.add(link[p][d])
    reach=bfs(link,wump)
    stats['reach'].append(len(reach)/ncav)
    stats['blood'].append(len(blood)/ncav)
    cands=[i for i in reach if i!=wump and i not in pits]
    if not cands: stats['nofit']+=1; continue
    stats['games']+=1
    # deduction check: is the wumpus uniquely identifiable from bloodspots alone?
    # a cavern w is consistent if the set of caverns within 2 of it == blood set
    consistent=[w for w in range(NSLOT) if cav[w] and set(bfs(link,w,2))==blood]
    if len(consistent)==1: stats['solvable']+=1
    # how many explored caverns carry no bloodspot (need some clear ones to triangulate)
    stats['clear'].append(sum(1 for i in range(NSLOT) if cav[i] and i not in blood)/ncav)

import statistics as st
print(f"trials with asymmetric links : {stats['sym']}  (must be 0)")
print(f"self-looping tunnels seen    : {stats['loops']}")
print(f"mazes with no valid start    : {stats['nofit']} / 3000")
print(f"caverns reachable from wumpus: {st.mean(stats['reach'])*100:.1f}% avg")
print(f"caverns with bloodspots      : {st.mean(stats['blood'])*100:.1f}% avg")
print(f"caverns with NO bloodspot    : {st.mean(stats['clear'])*100:.1f}% avg")
print(f"wumpus uniquely deducible    : {stats['solvable']/stats['games']*100:.1f}% of games")
