pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
--bug defense
--by eduszesz
--game off game jam 2021


function _init()
	t=0
	b_fix=40
	no_funds=false
	enemies={}
	float={}
	pathx={}
	pathy={}
	towers={}
	bullets={}
	lasers={}
	explosions={}
	selected=false
	t_typ=0
	s_c=1--stage counter
	stagex={0,128,256,384,512,640,768,896,0,128,256,384,512,640,768,896}
	stagey={0,0,0,0,0,0,0,0,128,128,128,128,128,128,128,128}
	wave_t=0 --time between waves
	wave=0
	s_alert=false	
	c={
		x=stagex[s_c],
		y=stagey[s_c],
		sp=2}
			
	find_path()
	set_e=false	
	lose=false
	win=false
	reset_map()		
end

function _update()
	t+=1
	
	set_waves()
	set_enemies()
	
	if btnp(0) then c.x-=8 end
	if btnp(1) then c.x+=8	end
	if btnp(2) then c.y-=8	end
	if btnp(3) then c.y+=8	end
	
	if c.x<stagex[s_c] then
	 c.x=stagex[s_c]
 end
	if c.y<stagey[s_c] then
	 c.y=stagey[s_c]
	end
	if c.x>120+stagex[s_c] then
		c.x=120+stagex[s_c]
	end
	if c.y>120+stagey[s_c] then
		c.y=120+stagey[s_c]
	end
	
	if btnp(4) and selected then
		set_tower()
	end
	
	if btnp(4) and not selected then
		select_tower()
	end
	
	if btnp(5) then
		selected=false
	end
	
	fire_bullets()
	fire_laser()
	set_lasers()
	move_bullets()
	
	col_bullets()
	col_lasers()
	set_explosions()
	set_trap()
	set_hold_tower(16,27)
	slow_enemies()
	exit_enemies()
	for e in all(enemies) do
		immortal(e,45)
	end
	if t%150==0 then
		check_win()	
	end
	move_enemies()
	fix_bugs()
	dofloats()
	show_cost()
	destroy_towers()
end

function _draw()
	cls()
	pal(14,0)
	map()
	camera(stagex[s_c],stagey[s_c])	
	for e in all(enemies) do
		if t%16<8 then
			e.sp=42
			if e.imm then 
				e.sp=127
			end
		else
			e.sp=43
		end
		spr(e.sp,e.x,e.y)
		if e.imm then
			line(e.x,e.y,e.x+5,e.y,8)
			line(e.x,e.y,(e.x+e.h),e.y,11)
		end
	end
		
	if fget(mget(c.x/8,c.y/8),0) then
		c.sp=2
	else
		if selected then
			c.sp=3
		else	
			c.sp=1
		end	
	end
	
		
	spr(c.sp,c.x,c.y)
	
	for tw in all(towers) do
		
		if t%16==0 then
			tw.c+=1
		end
		
		if tw.c>4 then
			tw.c=1
		end
		
		if tw.isp==5 or tw.isp==7 
		 or tw.isp==14 or tw.isp==28 then
			if tw.c<3 then
				tw.sp=tw.isp
			else
				tw.sp=tw.isp+1	
			end 
			
			if tw.c%2==0 then
				flipx=true
			else
				flipx=false
			end
		end
		
		if tw.isp==10 then
			tw.sp=tw.c+9
			flipx=false
		end
		
	
		spr(tw.sp,tw.x,tw.y,1,1,flipx)
		line(tw.x,tw.y,tw.x+5,tw.y,8)
		line(tw.x,tw.y,(tw.x+tw.h),tw.y,11)
	end
	
	for b in all(bullets) do
		spr(b.sp,b.x,b.y)
	end
	
	for ex in all(explosions) do
  circ(ex.x,ex.y,ex.t/2,8+ex.t%3)
 end
 
 for l in all(lasers) do
  --rectfill(l.x,l.y,l.x+l.fx,l.y+l.fy,8+l.t%3)
  --rect(l.x+l.box.x1,l.y+l.box.y1,l.x+l.box.x2,l.y+l.box.y2,11)
  line(l.ix,l.iy,l.fx,l.fy,8+l.t%3)
 end
	if lose then
		--print("you lose",stagex[s_c]*4,stagex[s_c]*4,8)
		pal(1,8)
	end
	wave_alert()
	print(b_fix,stagex[s_c]+32,stagey[s_c],7)
	
	for f in all(float) do
		print(f.txt,f.x,f.y,f.c)
	end
	
end

function find_path()
	for x=0,128 do
		for y=0,16 do
			if mget(x,y)>21 and mget(x,y)<26 then
				add(pathx,x*8)
				add(pathy,y*8)
			end
		end
	end
	for x=0,128 do
		for y=16,32 do
			if mget(x,y)>21 and mget(x,y)<26 then
				add(pathx,x*8)
				add(pathy,y*8)
			end
		end
	end
end

function select_tower()
	local tile=mget(c.x/8,c.y/8)
	if fget(tile,7) then
		t_typ=tile
		selected=true
	end
end

function set_tower()
	local cost=set_cost(t_typ)
	if c.sp==3 and c.y>8 and 
		b_fix>=set_cost(t_typ) then
			local tw={
											x=c.x,
											y=c.y,
											sp=t_typ,
											isp=t_typ,
											flipx=false,
											c=1,
											t=0,
											h=5,
											b=cost,
											box={x1=0,y1=0,x2=7,y2=7}
											}
			add(towers,tw)
			mset(c.x/8,c.y/8,33)
			b_fix-=cost							
		else
			no_funds=true
		end
end


function fire_bullets()
	
	for tw in all(towers) do
		local drcx,drcy=1,1
		if t%8==0 and tw.isp==5 then
			if tw.c==1 then drcx,drcy=-1,-1 end			
			if tw.c==2 then drcx,drcy=1,-1 end			
			if tw.c==3 then drcx,drcy=1,1 end			
			if tw.c==4 then drcx,drcy=-1,1 end
			local b={
										sp=9,
										x=tw.x+3+drcx,		
										y=tw.y+3+drcy,
										px=tw.x+3+drcx,		
										py=tw.y+3+drcy,
										dx=drcx,
										dy=drcy,
										box = {x1=0,y1=0,x2=1,y2=1},
										}		
			add(bullets,b)
		end
		if t%16==0 and tw.isp==28 then
			for e in all(enemies) do
				local vx,vy=e.x-tw.x,e.y-tw.y
				local mod=sqrt(vx*vx+vy*vy)
				local b={
										sp=30,
										x=tw.x+4,		
										y=tw.y+4,
										px=tw.x+4,		
										py=tw.y+4,
										dx=vx/mod,
										dy=vy/mod,
										box = {x1=0,y1=0,x2=1,y2=1},
										}		
			add(bullets,b)
			end
		end
	end
end

function move_bullets()
	for b in all(bullets) do
		b.x+=b.dx
		b.y+=b.dy
		if distance(b.x,b.y,b.px,b.py)>32 then
			del(bullets,b)
		end	
	end
end

function col_bullets()
	for b in all(bullets) do
		for e in all(enemies) do
			if coll(e,b) 
			and not e.imm then
				e.imm=true
				e.h-=1
				del(bullets,b)
				sfx(0)
				b_fix+=1
			end
			if e.h<0 then
				del(enemies,e)
				explode(e.x+4,e.y+4)
			end
		end
	end
end

function col_lasers()
	for l in all(lasers) do
		for e in all(enemies) do
			if coll(e,l) 
			and not e.imm then
				e.imm=true
				e.h-=1
				sfx(0)
				b_fix+=1
			end
			if e.h<0 then
				del(enemies,e)
				explode(e.x+4,e.y+4)
			end
		end
	end
end

function set_enemies()
	
	local e={
								x=pathx[s_c],
								y=pathy[s_c],
								dx=0,
								dy=0,
								sp=3,
								h=5,
								t=0,
								s=30,
								imm=false,
								box={x1=0,y1=0,x2=7,y2=7},}
			
	if	set_e and t%60==0 then						
		add(enemies,e)							
	end		

	if #enemies==2+wave then set_e=false end
end

function move_enemies()
	for e in all(enemies) do
		local tile=mget(e.x/8,e.y/8)
		if fget(tile,1) then e.dx,e.dy=1,0 end
		if fget(tile,2) then e.dx,e.dy=0,-1 end
		if fget(tile,3) then e.dx,e.dy=0,1 end
		if fget(tile,4) then e.dx,e.dy=-1,0 end
		
		if t%e.s==0 then
			e.x+=e.dx*8
			e.y+=e.dy*8
		end	
	end
end

function addfloat(_txt,_x,_y,_c)
 add(float,{txt=_txt,x=_x,y=_y,c=_c,ty=_y-10,t=0})
end

function dofloats()
 for f in all(float) do
  f.y+=(f.ty-f.y)/10
  f.t+=1
  if f.t>70 then
   del(float,f)
  end
 end
end


function rectfill2(_x,_y,_w,_h,_c)
 --★
 rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end


function distance(x1,y1,x2,y2)
	local dx=(x2-x1)
	local dy=(y2-y1)
	if abs(dx)>160 then dx=160 end
	return sqrt(dx*dx+dy*dy)
end

function abs_box(s)
 local box = {}
 box.x1 = s.box.x1 + s.x
 box.y1 = s.box.y1 + s.y
 box.x2 = s.box.x2 + s.x
 box.y2 = s.box.y2 + s.y
 return box

end

function coll(a,b)
 
 local box_a = abs_box(a)
 local box_b = abs_box(b)
 
 if box_a.x1 > box_b.x2 or
    box_a.y1 > box_b.y2 or
    box_b.x1 > box_a.x2 or
    box_b.y1 > box_a.y2 then
    return false
 end
 
 return true 
  
end

function immortal(a,i)
	if a.imm then
  a.t += 1
  if a.t >i then
   a.imm,a.t=false,0
  end
 end
end

function explode(x,y)
 add(explosions,{x=x,y=y,t=0})
 sfx(0)
end

function set_explosions()
	for ex in all(explosions) do
  ex.t+=1
  if ex.t == 13 then
   del(explosions, ex)
  end
 end
end

function fire_laser()
 for tw in all(towers) do	
			if tw.isp==10 and t%60<4 then
	 		if #enemies>0 then	
					local vx,vy=enemies[1].x+4,enemies[1].y+4
					local l={
											x=vx,
											y=vy,
											ix=tw.x+4,		
											iy=tw.y+4,
											fx=vx,
											fy=vy,
											t=0,
											box = {x1=0,y1=0,x2=1,y2=1},
											}
																
		 		add(lasers,l)
	 	end
	 end
	end 
end

function set_lasers()
	for l in all(lasers) do
  l.t+=1
  if l.t == 13 then
   del(lasers,l)
  end
 end
end

function set_trap()
	for tw in all(towers) do
		if tw.isp==7 then
			for e in all(enemies) do
				if distance(tw.x,tw.y,e.x,e.y)<10 then
					explode(tw.x,tw.y)
					mset(tw.x/8,tw.y/8,48)
					del(towers,tw)
					del(enemies,e)
					b_fix+=5
					explode(e.x,e.y)
				end
			end
		end
	end
end

function set_hold_tower(_i,_f)
	local ini,fin=_i,_f
	local ax={1,-1,0,0,1,-1,-1,1}
	local ay={0,0,1,-1,1,-1,1,-1}
	for tw in all(towers) do
		if tw.isp==14 then
			local twx,twy=tw.x/8,tw.y/8
			for i=1,8 do
				if mget(twx+ax[i],twy+ay[i])==ini then
					mset(twx+ax[i],twy+ay[i],fin)
				end
			end
		end
	end
end

function slow_enemies()
	if #enemies>0 then	
		for e in all(enemies) do
			if mget(e.x/8,e.y/8)==27 then
				e.s=60
			else	
				e.s=30
			end
		end
	end	
end

function exit_enemies()
	for e in all(enemies) do
		if mget(e.x/8,e.y/8)==26 then
			lose=true
		end
	end
end

function check_win()
	local sc=s_c
	if not win and #enemies==0 
		and wave==3 then
		win=true
		_init()
		s_c=(1+sc)
		if s_c>16 then s_c=1 end
	end
end

function reset_map()
	b_fix=40
	for x=0,128 do
		for y=0,128 do
			if mget(x,y)==27 then
				mset(x,y,16)
			end
			if mget(x,y)==33 then
				mset(x,y,48)			end
		end
	end
	wave=0
end

function set_waves()
	if t%30==0 and (not set_e) 
		and #enemies==0 then
		wave_t+=1
	end
	
	if wave_t==40 then
		wave_t=0
		set_e=true
		wave+=1
	end
end

function wave_alert()
	local co=flr(rnd(15))
	print(wave_t,stagex[s_c]+16,stagey[s_c],7)
	if wave_t>30 and wave_t<40 then	
		rectfill2(stagex[s_c]+23,stagey[s_c]+60,82,10,6)
		rectfill2(stagex[s_c]+24,stagey[s_c]+61,80,8,0)
		print("the bugs are coming!",stagex[s_c]+25,stagey[s_c]+62,co)
	end
end

function fix_bugs()
	if t%90==0 then
		b_fix+=1
	end
end

function set_cost(_t_typ)
	local b_cost=10
	local typ=_t_typ
	if typ==7 then b_cost=20 end
	if typ==10 then b_cost=40 end
	if typ==14 then b_cost=25 end
	if typ==28 then b_cost=30 end	
	return b_cost
end

function show_cost()
	local tile=mget(c.x/8,c.y/8)
	local cost=set_cost(tile)
	if fget(tile,7) then
		addfloat(cost,c.x,c.y+10,7)
	end
	for f in all(float) do
	 if #float>1 then
	 	del(float,f)
	 end
	end
end

function destroy_towers()
	for tw in all(towers) do
		for e in all(enemies) do
			if t%e.s==0 and tw.isp!=14 and 
				distance(tw.x,tw.y,e.x,e.y)<9 then
				tw.h-=1
			end
		end
		if tw.h<1 then
			explode(tw.x+4,tw.y+4)
			mset(tw.x/8,tw.y/8,48)
			set_hold_tower(27,16)
			del(towers,tw)
		end
	end
end
__gfx__
000000007700007788000088bb0000bb000000008000000000000000000000000088880080000000000000000000000000000000000000000000000000000000
000000007000000780000008b000000bb000b0000800000000000000000000000800008000000000000570000005500000055000000550000500005000000000
007007000000000000000000000000000b355b00008222000022220000088000800000080000000000666600006666000066660000666600000dd000005dd500
0007700000000000000000000000000000bbb8400025420000254200008a680080066008000000000565865005685650056586500568565000d16d0000d16d00
0007700000000000000000000000000000bbb8400024520000245200008668008006a008000000000568565005658670056856500765865000d61d0000d61d00
007007000000000000000000000000000b535b00002222000022280000088000800000080000000000666600006666000066660000666600000dd000005dd500
000000007000000780000008b000000b00b000b00000000000000080000000000800008000000000000550000005500000057000000550000500005000000000
000000007700007788000088bb0000bb000000000000000000000008000000000088880000000000000000000000000000000000000000000000000000000000
eeeeeeee0666666000000000000e00000000000000000000beeeeeebbeeeeeebbeeeeeebbeeeeeeb8eeeeee8000000000000000000000000a000000006666660
eeeeeeee611111150a0000a00aeee0a00a0000a00ae000a0eee0eeeeeeee0eeeeee0eeeeee0eeeeeeeeeeeee0500005000000000060000600000000056cccc65
eeaaaaee61111115000e00000e0e0e00000e00000e000000eeee0eeeeee000eeeee0eeeee0eeeeeeeeeeeeee0005500000855000000550000000000056bccc65
eeaaaaee611111150000e000000e0000000e0000eeeeee00000000eeee0e0e0ee0e0e0ee000000eeeeeeeeee0056850000587500005775000000000056cccc65
eeaaaaee61111115eeeeee00000e0000000e00000e000000eeee0eeeeeee0eeeee000eeee0eeeeeeeeeeeeee0058650000577500005785000000000006666660
eeaaaaee611111150000e000000e00000e0e0e0000e00000eee0eeeeeeee0eeeeee0eeeeee0eeeeeeeeeeeee0005500000055000000558000000000065d5d5d6
eeeeeeee611111150a0e00a00a0000a00aeee0a00a0000a0eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee050000500000000006000060000000006d5d5d56
eeeeeeee055555500000000000000000000e000000000000beeeeeebbeeeeeebbeeeeeebbeeeeeeb8eeeeee80000000000000000000000000000000066666666
bb0000bb0eeeeee00000000000000000000000000000000000000000000000000000000044800000006660000000000000000000000000000000000000000000
b000000beeeeeeee00b000b0b000b000000440000000000000000000000000000448000040000000001163000066630000000000000000000000000000000000
00000000eeeeeeee0b535b400b355b00004b4b000000000002525252252525204000544540504000001bbb80001bbb8000000000000000000000000000000000
00000000eeeeeeee00bbb80000bbb840044b4b48000000000222b1b00222bb10041414104014144500bbbbb000bbbbb000000000000000000000000000000000
00000000eeeeeeee00bbb80000bbb8400b4111484b4b4b480222bb100222b1b0004444b0044444b0001b6b80001b6b8000000000000000000000000000000000
00000000eeeeeeee0b355b400b535b000b4111114b4b4b4825252520025252520041541000411445001163000066630000000000000000000000000000000000
b000000beeeeeeeeb000b00000b000b0000000000111111000000000000000000400044505040000006660000000000000000000000000000000000000000000
bb0000bb0eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
03000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeee00
__gff__
0000000000800080000080000000800001010305091103050911010180000080000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00000000000005070a0e1c000000000000000000000005070a0e00000000000000000000000005070a0e00000000000000000000000005070a0e00000000000000000000000005070a0e00000000000000000000000005070a0e00000000000000000000000005070a0e00000000000000000000000005070a0e000000000000
11111111111111111111111111111111111111111811111111111111111111111111181111111111111111111a1111111111111111111111111111181111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111118111111111111111111111111
113030303030303030303030303030111100000010000000000000000000001111001000000000000000000010000011110000000000000000000010000000111100000000000000000000000000001a160000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1130303030303030301210101430301111000000100000000000000000000011110010000000000000000000100000111100000000000000000000100000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1130301210101430301030301030301111000000100000000000111100000011110010000000111100000000100000111100000000141010101010150000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000001111000000000000000011
1130301030301030301030301030301111000000100000000000000011000011110010000000000011000000100000111100000000100000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000110000110000000000000011
1130301030301030301030141530301111000000100000000000000011000011110010000000000011000000100000111100000000100000000000000000001111000000001111110000000000000011110000000000000000000000000000111100000000000000000000000000001111000000110000110000000000000011
1130301030301030301030103030301111000000100000000000111100000011110010000000111100000000100000111100000000100000121010101010101a11000000001100000000000000000011110000000000001100000000000000111100000000000000000000000000001111000000001111000000000000000011
1612101330301030301030103030121a11000000100000000000111111110011110010000000000011000000100000111100000000100000131010101500001111000000001111110000000000000011110000000000110000000000000000111100000000001111110000000000001111000000110000110000000000000011
113030303030103030103010303010111a101010101010101500000000000011110010000000000011000000100000111100000000100000000000001000001111000000000000110000000000000011110000000011001100000000000000111100000000000000110000000000001111000000110000110000000000000011
1130303030301030301030121430101111000000100000001000000000000011110010000000111100000000100000111100000000100000000000121300001111000000001111110000000000000011110000000011000011000000000000111100000000000011000000000000001111000000001111000000000000000011
1130303030301030301030111030101111000000100000001000000000000011110010000000000000000000100000111100110011100000000000100000001111000000000000000000000000000011110000000000111100000000000000111100000000001100000000000000001111000000000000000000000000000011
1130303030301210101330111030101111000000100000001000000000000011110012101010101010101010130000111100111111121010101010130000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1130303030303030303030111030101111000000121010101300000000000011110000000000000000000000000000111100000011000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
11303030303030303030303012101311110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011160000000000000000000000000000111100000000000000000000000000001a1100000000000000000000000000001111000000000000000000000000000011
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117111111111111111a111111111111111111111111111111111a111111
00000000000005070a0e00000000000000000700000000000000000000000000000000070000000000000000000000000000070000000000000000000000000000000700000000000000000000000000000007000000000000000000000000000000070000000000000000000000000000000700000000000000000000000000
1111111111111111111111111111111111111111111111111111111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111118111111111111111111111111111111111a11111111111111111111111111111111111111111811111111111111111111111111111111111111
1100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100000000000000000011110000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100001210101400000011110000001111000000110011111100000000000011110000110011000000000000000000111100000011001111000000000000001111000011000011110000000000000011110000000000000000000000000000191100000000000000000000000000001111000000000000000000000000000011
1100001000001000000000110000001111000000110011001100000000000011110000110011000000000000000000111100000011000000110000000000001111000011000000001100000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100001000001000000000110000001111000000110011111100000000000011110000110011000000000000000000111100000011000000110000000000001111000011000000001100000000000011110000110011001100000000000000111100000011001111110000000000001111000011000000001100000000000011
110000100000100000000000000000111100000000000000000000000000001111000000000000000000000000000011110000001100111100000000000000111100001100001111000000000000001111000011001111110000000000000011110000001100110000000000000000111100001100000011000000000000001a
1610101300001214000000001210101a16000000000000000000000000000011111111111100000000000000000000111100000011001111110000000000001111000011000000001100000000000011110000110000001100000000000000111100000011001111110000000000001111000011000011001100000000000011
1100000000000010000000001000001111000000000000000000000000000011111111111600000000000000000000111100000000000000000000000000001111000011000000001100000000000011110000000000000000000000000000111100000011000000110000000000001111000011000011000011000000000011
1100000000000010000000001000001111000000000000000000000000000011111111111100000000000000000000111100000000000000000000000000001a11000011000011110000000000000011110000000000000000000000000000111100000011001111110000000000001111000011000000111100000000000011
1100000000000010000000001000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100000000000010000000001000001111000000000000000000000000000011110000000000000000000000000000111100000011171100000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100000000000012101010101300001111000000000000000000000000000011110000000000000000000000000000111100000011111100000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
1100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000011111100000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000000000000000001111000000000000000000000000000011
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a11111111111111111111111111111111111111111111111111111111111a1111111111111111111111111111111111111111111a1111111111111111111111111111111711111111111111111111111111
__sfx__
000300001b670186701767014670106700c6700a60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
